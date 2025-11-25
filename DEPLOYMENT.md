# CloudScrapers Deployment Guide

Complete guide for deploying the CloudScrapers website to AWS EC2 with ALB.

## Architecture Overview

```
Internet
   ↓
Route 53 (DNS)
   ↓
Application Load Balancer (ALB)
   ↓ (Port 443 → 80)
EC2 Instances (Nginx)
   ↓
RDS PostgreSQL (for future backend)
```

## Prerequisites

- AWS Account with appropriate permissions
- Domain name (cloudscrapers.pl)
- SSH key pair for EC2 access
- Basic knowledge of AWS services

---

## Part 1: AWS Infrastructure Setup

### 1. VPC Configuration

```bash
# Create VPC
VPC CIDR: 10.0.0.0/16

# Create Subnets
Public Subnet 1: 10.0.1.0/24 (us-east-1a)
Public Subnet 2: 10.0.2.0/24 (us-east-1b)
Private Subnet 1: 10.0.10.0/24 (us-east-1a)
Private Subnet 2: 10.0.11.0/24 (us-east-1b)

# Internet Gateway
- Attach to VPC

# Route Tables
Public RT: 0.0.0.0/0 → Internet Gateway
Private RT: 0.0.0.0/0 → NAT Gateway
```

### 2. Security Groups

**ALB Security Group:**
```yaml
Name: cloudscrapers-alb-sg
Inbound:
  - Type: HTTP, Port: 80, Source: 0.0.0.0/0
  - Type: HTTPS, Port: 443, Source: 0.0.0.0/0
Outbound:
  - All traffic
```

**EC2 Security Group:**
```yaml
Name: cloudscrapers-ec2-sg
Inbound:
  - Type: HTTP, Port: 80, Source: ALB Security Group
  - Type: SSH, Port: 22, Source: Your IP (for initial setup only)
Outbound:
  - All traffic
```

### 3. Launch EC2 Instances

```bash
# Instance Configuration
AMI: Amazon Linux 2023 (or Ubuntu 22.04 LTS)
Instance Type: t3.small (minimum for production)
Number of Instances: 2 (for high availability)
Subnet: Private Subnet 1 & 2
Security Group: cloudscrapers-ec2-sg
IAM Role: Create role with:
  - CloudWatchAgentServerPolicy
  - AmazonSSMManagedInstanceCore (for Systems Manager)
  - SecretsManagerReadWrite (for future backend)

# Storage
Root Volume: 20 GB gp3
Encrypted: Yes

# User Data (for automated setup)
#!/bin/bash
yum update -y
yum install -y git nginx

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
```

### 4. Application Load Balancer Setup

```bash
# Create Target Group
Name: cloudscrapers-tg
Target Type: Instance
Protocol: HTTP
Port: 80
Health Check Path: /health
Health Check Interval: 30s
Healthy Threshold: 2
Unhealthy Threshold: 3

# Create ALB
Name: cloudscrapers-alb
Scheme: Internet-facing
IP address type: IPv4
Subnets: Select both public subnets
Security Group: cloudscrapers-alb-sg

# Listener Configuration
Listener 1:
  - Port: 80
  - Protocol: HTTP
  - Action: Redirect to HTTPS

Listener 2:
  - Port: 443
  - Protocol: HTTPS
  - SSL Certificate: (from ACM)
  - Action: Forward to cloudscrapers-tg
```

### 5. SSL Certificate (AWS Certificate Manager)

```bash
# Request Certificate
Domain: cloudscrapers.pl
Additional names: www.cloudscrapers.pl
Validation: DNS validation

# Add CNAME records to Route 53
(ACM will provide the CNAME records)

# Wait for validation (usually 5-30 minutes)
```

### 6. Route 53 DNS Configuration

```bash
# Create A Record
Record name: cloudscrapers.pl
Record type: A - Alias
Route traffic to: Alias to Application Load Balancer
Region: us-east-1
Load Balancer: cloudscrapers-alb

# Create CNAME for www
Record name: www.cloudscrapers.pl
Record type: A - Alias
Route traffic to: Alias to Application Load Balancer
```

---

## Part 2: EC2 Instance Setup

### Method 1: Automated Deployment (Recommended)

```bash
# 1. SSH into EC2 instance
ssh -i your-key.pem ec2-user@<instance-ip>

# 2. Clone repository
cd /home/ec2-user
git clone https://github.com/yourusername/cloudscrapers-website.git
cd cloudscrapers-website

# 3. Make deployment script executable
chmod +x deploy-to-ec2.sh

# 4. Run deployment script
./deploy-to-ec2.sh

# 5. Verify deployment
curl http://localhost/health
```

### Method 2: Manual Deployment

```bash
# 1. Install Nginx
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y

# 2. Create web directory
sudo mkdir -p /var/www/cloudscrapers

# 3. Upload website files
# Using SCP from your local machine:
scp -i your-key.pem -r * ec2-user@<instance-ip>:/tmp/website/

# Then on EC2:
sudo cp -r /tmp/website/* /var/www/cloudscrapers/
sudo chown -R ec2-user:nginx /var/www/cloudscrapers
sudo chmod -R 755 /var/www/cloudscrapers

# 4. Configure Nginx
sudo cp nginx-alb.conf /etc/nginx/conf.d/cloudscrapers.conf

# 5. Test and restart Nginx
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# 6. Verify
curl http://localhost/health
```

---

## Part 3: Security Hardening

### 1. Disable SSH Password Authentication

```bash
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 2. Install and Configure fail2ban

```bash
sudo yum install fail2ban -y

# Configure fail2ban for nginx
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true

[nginx-noscript]
enabled = true

[nginx-badbots]
enabled = true

[nginx-noproxy]
enabled = true
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 3. Setup Automatic Security Updates

```bash
# Amazon Linux
sudo yum install yum-cron -y
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Ubuntu
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 4. Configure CloudWatch Monitoring

```bash
# Create CloudWatch config
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json << 'EOF'
{
  "metrics": {
    "namespace": "CloudScrapers/EC2",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"},
          {"name": "cpu_usage_iowait", "rename": "CPU_IOWAIT", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/cloudscrapers-access.log",
            "log_group_name": "/cloudscrapers/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/cloudscrapers-error.log",
            "log_group_name": "/cloudscrapers/nginx/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json
```

---

## Part 4: WAF Setup (Optional but Recommended)

### Create WAF Web ACL

```bash
# In AWS Console, go to WAF & Shield
# Create Web ACL with:

1. Core rule set (AWS Managed - AWSManagedRulesCommonRuleSet)
2. Known bad inputs (AWS Managed - AWSManagedRulesKnownBadInputsRuleSet)
3. SQL database (AWS Managed - AWSManagedRulesSQLiRuleSet)
4. Rate limiting rule:
   - Name: RateLimitRule
   - Rate limit: 2000 requests per 5 minutes
   - Action: Block

# Associate with ALB
```

---

## Part 5: Backup Strategy

### 1. AMI Snapshots

```bash
# Create lifecycle policy in DLM (Data Lifecycle Manager)
Target: Instance (tag: Name=cloudscrapers-web)
Schedule: Daily at 03:00 UTC
Retention: 7 days
```

### 2. File Backups to S3

```bash
# Create S3 bucket
aws s3 mb s3://cloudscrapers-backups --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket cloudscrapers-backups \
  --versioning-configuration Status=Enabled

# Create backup script
sudo tee /usr/local/bin/backup-website.sh << 'EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar -czf /tmp/website-backup-$TIMESTAMP.tar.gz -C /var/www/cloudscrapers .
aws s3 cp /tmp/website-backup-$TIMESTAMP.tar.gz s3://cloudscrapers-backups/
rm /tmp/website-backup-$TIMESTAMP.tar.gz
EOF

sudo chmod +x /usr/local/bin/backup-website.sh

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-website.sh") | crontab -
```

---

## Part 6: Monitoring and Alerts

### CloudWatch Alarms

```bash
# High CPU Usage
Metric: CPUUtilization
Threshold: > 80% for 5 minutes
Action: SNS notification

# Unhealthy Target
Metric: UnHealthyHostCount
Threshold: >= 1 for 2 minutes
Action: SNS notification

# 5xx Errors
Metric: HTTPCode_Target_5XX_Count
Threshold: > 10 in 5 minutes
Action: SNS notification
```

---

## Part 7: Testing

### Load Testing

```bash
# Install Apache Bench
sudo yum install httpd-tools -y

# Run load test
ab -n 1000 -c 10 https://cloudscrapers.pl/

# Monitor during test
watch -n 1 'curl -s http://localhost/health/detailed'
```

### Security Testing

```bash
# SSL Labs Test
Visit: https://www.ssllabs.com/ssltest/analyze.html?d=cloudscrapers.pl

# Security Headers
Visit: https://securityheaders.com/?q=https://cloudscrapers.pl

# OWASP ZAP Scan (from local machine)
docker run -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-stable \
  zap-baseline.py -t https://cloudscrapers.pl
```

---

## Troubleshooting

### Issue: 502 Bad Gateway

```bash
# Check Nginx status
sudo systemctl status nginx

# Check Nginx logs
sudo tail -f /var/log/nginx/cloudscrapers-error.log

# Check if Nginx is listening
sudo netstat -tlnp | grep nginx
```

### Issue: Health Check Failing

```bash
# Test health check locally
curl -v http://localhost/health

# Check ALB target group health
aws elbv2 describe-target-health \
  --target-group-arn <your-target-group-arn>
```

### Issue: High Memory Usage

```bash
# Check memory usage
free -h

# Check top processes
top -o %MEM

# Optimize Nginx worker processes
# Edit /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;
```

---

## Maintenance

### Regular Tasks

- **Daily**: Review CloudWatch logs for errors
- **Weekly**: Review security group rules
- **Monthly**: Update system packages
- **Quarterly**: Review and rotate SSL certificates (auto-renewed by ACM)

### Updating the Website

```bash
# 1. Backup current version
sudo tar -czf /var/backups/cloudscrapers/backup-$(date +%Y%m%d).tar.gz \
  -C /var/www/cloudscrapers .

# 2. Pull latest changes
cd ~/cloudscrapers-website
git pull origin main

# 3. Copy to web root
sudo cp -r * /var/www/cloudscrapers/

# 4. Test Nginx config
sudo nginx -t

# 5. Reload Nginx (zero-downtime)
sudo nginx -s reload
```

---

## Cost Optimization

- Use Reserved Instances for long-term savings (up to 72% off)
- Enable ALB access logs only when needed
- Use CloudWatch Logs retention policies (7-30 days)
- Consider Aurora Serverless for future database needs
- Use S3 Intelligent-Tiering for backups

---

## Support

For issues or questions:
- Email: biuro@cloudscrapers.pl
- Documentation: This file
- AWS Support: (if subscribed to support plan)
