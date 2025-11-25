#!/bin/bash
# 502 Bad Gateway Troubleshooting Script
# Run this on your EC2 instance to diagnose ALB connection issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Script header
echo "================================================"
echo "502 Bad Gateway Troubleshooting Script"
echo "CloudScrapers EC2 Instance Diagnostics"
echo "================================================"
echo ""

# Check 1: Nginx Status
print_header "1. Nginx Service Status"
if systemctl is-active --quiet nginx; then
    print_success "Nginx is running"
    systemctl status nginx --no-pager -l | grep -E "(Active|Main PID|Memory|CPU)"
else
    print_error "Nginx is NOT running!"
    echo "Start Nginx with: sudo systemctl start nginx"
    exit 1
fi

# Check 2: Nginx listening ports
print_header "2. Nginx Listening Ports"
echo "Checking if Nginx is listening on port 80..."
if sudo netstat -tlnp | grep -q ":80.*nginx"; then
    LISTEN_ADDRESS=$(sudo netstat -tlnp | grep ":80.*nginx" | awk '{print $4}')
    if echo "$LISTEN_ADDRESS" | grep -q "0.0.0.0:80"; then
        print_success "Nginx is listening on 0.0.0.0:80 (all interfaces) ✓"
    elif echo "$LISTEN_ADDRESS" | grep -q "127.0.0.1:80"; then
        print_error "Nginx is listening on 127.0.0.1:80 (localhost only)"
        print_warning "This is the problem! ALB can't reach nginx on localhost."
        echo ""
        echo "Fix: Edit /etc/nginx/conf.d/cloudscrapers.conf"
        echo "Change: listen 127.0.0.1:80;"
        echo "To:     listen 80;"
        echo ""
        echo "Then: sudo nginx -t && sudo systemctl reload nginx"
    else
        print_warning "Nginx listening on: $LISTEN_ADDRESS"
    fi
    echo ""
    sudo netstat -tlnp | grep ":80"
else
    print_error "Nginx is NOT listening on port 80!"
    echo "Check your nginx configuration"
fi

# Check 3: Test local connectivity
print_header "3. Local Web Server Test"
echo "Testing HTTP response from localhost..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "200"; then
    print_success "Local HTTP request successful (200 OK)"
else
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
    print_error "Local HTTP request failed (HTTP $HTTP_CODE)"
fi

echo ""
echo "Testing health check endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost/health)
if [ "$HEALTH_RESPONSE" = "healthy" ]; then
    print_success "Health check endpoint working: $HEALTH_RESPONSE"
else
    print_error "Health check endpoint failed: $HEALTH_RESPONSE"
fi

# Check 4: Security Group (requires AWS CLI)
print_header "4. Security Group Check"
INSTANCE_ID=$(ec2-metadata --instance-id 2>/dev/null | cut -d " " -f 2)
if [ -n "$INSTANCE_ID" ]; then
    print_info "Instance ID: $INSTANCE_ID"

    echo ""
    echo "Security groups attached to this instance:"
    if command -v aws &> /dev/null; then
        REGION=$(ec2-metadata --availability-zone 2>/dev/null | cut -d " " -f 2 | sed 's/[a-z]$//')
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION \
            --query 'Reservations[0].Instances[0].SecurityGroups[*].[GroupId,GroupName]' \
            --output table 2>/dev/null || print_warning "AWS CLI not configured or no permissions"
    else
        print_warning "AWS CLI not installed. Install with: sudo yum install aws-cli -y"
    fi
else
    print_warning "Could not determine instance ID. Not running on EC2?"
fi

# Check 5: Private IP address
print_header "5. Network Interface Information"
PRIVATE_IP=$(hostname -I | awk '{print $1}')
print_info "Private IP: $PRIVATE_IP"

echo ""
echo "Testing if port 80 is accessible from private IP..."
if curl -s -o /dev/null -w "%{http_code}" http://$PRIVATE_IP/ | grep -q "200"; then
    print_success "Port 80 accessible from private IP ($PRIVATE_IP)"
else
    print_error "Port 80 NOT accessible from private IP ($PRIVATE_IP)"
    print_warning "This will prevent ALB from reaching this instance"
fi

# Check 6: Firewall rules
print_header "6. Firewall Configuration"
if command -v firewall-cmd &> /dev/null; then
    if systemctl is-active --quiet firewalld; then
        print_warning "firewalld is running"
        echo ""
        echo "HTTP service allowed:"
        firewall-cmd --list-services | grep -q http && print_success "HTTP is allowed" || print_error "HTTP is NOT allowed"
        echo ""
        echo "To allow HTTP: sudo firewall-cmd --permanent --add-service=http && sudo firewall-cmd --reload"
    else
        print_info "firewalld is not active"
    fi
elif command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1)
    print_info "UFW Status: $UFW_STATUS"
else
    print_info "No firewall detected (firewalld/ufw)"
fi

# Check 7: Nginx error logs
print_header "7. Recent Nginx Error Logs"
if [ -f /var/log/nginx/cloudscrapers-error.log ]; then
    ERRORS=$(sudo tail -20 /var/log/nginx/cloudscrapers-error.log 2>/dev/null)
    if [ -z "$ERRORS" ]; then
        print_success "No recent errors in nginx error log"
    else
        print_warning "Recent errors found:"
        echo "$ERRORS"
    fi
else
    print_warning "Error log not found at /var/log/nginx/cloudscrapers-error.log"
fi

# Check 8: SELinux (if applicable)
print_header "8. SELinux Status"
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce 2>/dev/null)
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        print_warning "SELinux is in Enforcing mode"
        echo ""
        echo "This might block nginx. To allow nginx to bind to ports:"
        echo "sudo setsebool -P httpd_can_network_connect 1"
        echo ""
        echo "Or temporarily disable for testing:"
        echo "sudo setenforce 0"
    elif [ "$SELINUX_STATUS" = "Permissive" ]; then
        print_info "SELinux is in Permissive mode (logging but not blocking)"
    else
        print_success "SELinux is disabled"
    fi
else
    print_info "SELinux not detected (likely Ubuntu/Debian)"
fi

# Summary and Recommendations
print_header "Summary & Next Steps"

echo "Common causes of 502 Bad Gateway:"
echo ""
echo "1. ⚠️  MOST COMMON: Security Group blocking ALB → EC2 traffic"
echo "   Fix: Add inbound rule to EC2 security group:"
echo "   Type: HTTP, Port: 80, Source: <ALB Security Group ID>"
echo ""
echo "2. ⚠️  Nginx listening on 127.0.0.1 instead of 0.0.0.0"
echo "   Check above for listening address"
echo "   Fix: Ensure nginx config has 'listen 80;' not 'listen 127.0.0.1:80;'"
echo ""
echo "3. ⚠️  Instance health check failing in ALB"
echo "   Go to: AWS Console > EC2 > Target Groups > Your TG > Health status tab"
echo "   Ensure health check path is '/health' and instances are healthy"
echo ""
echo "4. ⚠️  Wrong target group or not registered with ALB"
echo "   Verify this instance is registered in the correct target group"
echo ""

print_header "Quick Fix Commands"
echo "# If nginx listening on wrong interface:"
echo "sudo nano /etc/nginx/conf.d/cloudscrapers.conf"
echo "# Change 'listen 127.0.0.1:80;' to 'listen 80;'"
echo "sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "# Check ALB target health (requires AWS CLI):"
echo "aws elbv2 describe-target-health --target-group-arn <YOUR_TG_ARN>"
echo ""
echo "# View live access logs:"
echo "sudo tail -f /var/log/nginx/cloudscrapers-access.log"
echo ""

echo "================================================"
echo "Troubleshooting Complete!"
echo "================================================"
