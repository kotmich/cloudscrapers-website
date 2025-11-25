#!/bin/bash
# CloudScrapers EC2 Deployment Script
# This script automates the deployment of the website to an EC2 instance

set -e  # Exit on error

echo "================================================"
echo "CloudScrapers EC2 Deployment Script"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_USER="ec2-user"  # Change if using Ubuntu: "ubuntu"
WEB_ROOT="/var/www/cloudscrapers"
NGINX_CONF="/etc/nginx/conf.d/cloudscrapers.conf"
BACKUP_DIR="/var/backups/cloudscrapers"

# Detect Nginx group (nginx on Amazon Linux, www-data on Ubuntu)
if getent group nginx > /dev/null 2>&1; then
    NGINX_GROUP="nginx"
elif getent group www-data > /dev/null 2>&1; then
    NGINX_GROUP="www-data"
else
    NGINX_GROUP="nginx"  # Default fallback
fi

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Run as $DEPLOY_USER with sudo privileges."
   exit 1
fi

print_info "Starting deployment process..."
print_info "Deployment user: $DEPLOY_USER"
print_info "Nginx group: $NGINX_GROUP"
print_info "Web root: $WEB_ROOT"
echo ""

# Step 1: Update system packages
print_info "Updating system packages..."
sudo yum update -y || sudo apt-get update -y
print_success "System packages updated"

# Step 2: Install Nginx
print_info "Installing Nginx..."
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS / RHEL
    sudo amazon-linux-extras install nginx1 -y 2>/dev/null || sudo yum install nginx -y
elif command -v apt-get &> /dev/null; then
    # Ubuntu / Debian
    sudo apt-get install nginx -y
fi
print_success "Nginx installed"

# Step 3: Install fail2ban for security
print_info "Installing fail2ban..."
if command -v yum &> /dev/null; then
    sudo yum install fail2ban -y
elif command -v apt-get &> /dev/null; then
    sudo apt-get install fail2ban -y
fi
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
print_success "fail2ban installed and started"

# Step 4: Create web root directory
print_info "Creating web root directory..."
sudo mkdir -p $WEB_ROOT
sudo chown -R $DEPLOY_USER:$DEPLOY_USER $WEB_ROOT
print_success "Web root created at $WEB_ROOT"

# Step 5: Create backup directory
print_info "Creating backup directory..."
sudo mkdir -p $BACKUP_DIR
sudo chown -R $DEPLOY_USER:$DEPLOY_USER $BACKUP_DIR
print_success "Backup directory created"

# Step 6: Backup existing site (if exists)
if [ -f "$WEB_ROOT/index.html" ]; then
    print_info "Backing up existing site..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    sudo tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" -C $WEB_ROOT .
    print_success "Backup created at $BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
fi

# Step 7: Copy website files
print_info "Copying website files..."
# Assuming the script is run from the repository directory
# First, ensure we have the files to copy
if [ ! -f "index.html" ]; then
    print_error "index.html not found. Please run this script from the repository root directory."
    exit 1
fi

# Copy files using sudo to avoid permission issues
sudo cp -r index.html styles.css script.js translations.js $WEB_ROOT/
sudo cp -r img platform $WEB_ROOT/ 2>/dev/null || true

# Set proper ownership and permissions
sudo chown -R $DEPLOY_USER:$NGINX_GROUP $WEB_ROOT
sudo chmod -R 755 $WEB_ROOT
sudo find $WEB_ROOT -type f -exec chmod 644 {} \;
sudo find $WEB_ROOT -type d -exec chmod 755 {} \;

print_success "Website files copied"

# Step 8: Configure Nginx
print_info "Configuring Nginx..."
sudo cp nginx-alb.conf $NGINX_CONF

# Test Nginx configuration
if sudo nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration test failed"
    exit 1
fi

# Step 9: Create custom error pages
print_info "Creating custom error pages..."

# Create temporary error pages first
TEMP_404="/tmp/404.html"
TEMP_50X="/tmp/50x.html"

# 404 Error Page
cat > $TEMP_404 << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found | CloudScrapers</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .error-container {
            text-align: center;
            padding: 2rem;
        }
        .error-code {
            font-size: 8rem;
            font-weight: 700;
            margin-bottom: 1rem;
            text-shadow: 0 0 20px rgba(0,0,0,0.3);
        }
        h1 { font-size: 2rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; margin-bottom: 2rem; opacity: 0.9; }
        .btn {
            display: inline-block;
            padding: 12px 30px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 25px;
            font-weight: 600;
            transition: transform 0.3s;
        }
        .btn:hover { transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-code">404</div>
        <h1>Page Not Found</h1>
        <p>The page you're looking for doesn't exist or has been moved.</p>
        <a href="/" class="btn">Return Home</a>
    </div>
</body>
</html>
EOF

# 50x Error Page
cat > $TEMP_50X << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Error | CloudScrapers</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .error-container {
            text-align: center;
            padding: 2rem;
        }
        .error-code {
            font-size: 8rem;
            font-weight: 700;
            margin-bottom: 1rem;
            text-shadow: 0 0 20px rgba(0,0,0,0.3);
        }
        h1 { font-size: 2rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; margin-bottom: 2rem; opacity: 0.9; }
        .btn {
            display: inline-block;
            padding: 12px 30px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 25px;
            font-weight: 600;
            transition: transform 0.3s;
        }
        .btn:hover { transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-code">500</div>
        <h1>Server Error</h1>
        <p>Something went wrong on our end. We're working to fix it!</p>
        <a href="/" class="btn">Return Home</a>
    </div>
</body>
</html>
EOF

# Copy error pages to web root with sudo
sudo cp $TEMP_404 $WEB_ROOT/404.html
sudo cp $TEMP_50X $WEB_ROOT/50x.html
sudo chown $DEPLOY_USER:$NGINX_GROUP $WEB_ROOT/404.html $WEB_ROOT/50x.html
sudo chmod 644 $WEB_ROOT/404.html $WEB_ROOT/50x.html

# Clean up temporary files
rm -f $TEMP_404 $TEMP_50X

print_success "Custom error pages created"

# Step 10: Enable and start Nginx
print_info "Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx
print_success "Nginx started"

# Step 11: Configure firewall (if firewalld is installed)
if command -v firewall-cmd &> /dev/null; then
    print_info "Configuring firewall..."
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
    print_success "Firewall configured"
fi

# Step 12: Install CloudWatch Agent (optional)
read -p "Do you want to install AWS CloudWatch Agent? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing CloudWatch Agent..."
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    sudo rpm -U ./amazon-cloudwatch-agent.rpm
    rm amazon-cloudwatch-agent.rpm
    print_success "CloudWatch Agent installed (configuration needed separately)"
fi

# Step 13: Setup log rotation
print_info "Setting up log rotation..."
sudo tee /etc/logrotate.d/nginx-cloudscrapers > /dev/null << EOF
/var/log/nginx/cloudscrapers-*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 $NGINX_GROUP adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
    endscript
}
EOF
print_success "Log rotation configured"

# Step 14: Security hardening
print_info "Applying security hardening..."

# Disable directory listing (should already be disabled in Nginx)
# Set proper file permissions
sudo find $WEB_ROOT -type f -exec chmod 644 {} \;
sudo find $WEB_ROOT -type d -exec chmod 755 {} \;

print_success "Security hardening applied"

# Final status check
echo ""
echo "================================================"
print_success "Deployment completed successfully!"
echo "================================================"
echo ""
print_info "Website URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
print_info "Web root: $WEB_ROOT"
print_info "Nginx config: $NGINX_CONF"
print_info "Backup directory: $BACKUP_DIR"
echo ""
print_info "Next steps:"
echo "  1. Configure your domain DNS to point to this server"
echo "  2. Setup SSL certificate (if not using ALB)"
echo "  3. Configure CloudWatch monitoring"
echo "  4. Test the website thoroughly"
echo ""
print_info "Nginx status:"
sudo systemctl status nginx --no-pager -l
