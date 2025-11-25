#!/bin/bash
# Install Custom ALB Log Format for Nginx
# This script adds a custom log format to nginx.conf that captures ALB headers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

echo "========================================"
echo "Custom ALB Log Format Installer"
echo "========================================"
echo ""

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run with sudo privileges"
   echo "Usage: sudo ./install-custom-log-format.sh"
   exit 1
fi

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    print_error "Nginx is not installed. Please install Nginx first."
    exit 1
fi

NGINX_CONF="/etc/nginx/nginx.conf"

# Check if nginx.conf exists
if [ ! -f "$NGINX_CONF" ]; then
    print_error "Nginx configuration file not found at $NGINX_CONF"
    exit 1
fi

# Check if log format already exists
if grep -q "log_format alb_log" "$NGINX_CONF"; then
    print_info "Custom ALB log format already exists in $NGINX_CONF"
    echo "Nothing to do."
    exit 0
fi

print_info "Installing custom ALB log format..."

# Backup original config
BACKUP_FILE="${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$NGINX_CONF" "$BACKUP_FILE"
print_success "Backed up nginx.conf to $BACKUP_FILE"

# Create temporary file with the log format
TEMP_FILE=$(mktemp)

cat > "$TEMP_FILE" << 'EOF'
    # Custom ALB log format - captures AWS ALB headers
    log_format alb_log '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'forwarded_for="$http_x_forwarded_for" '
                       'forwarded_proto="$http_x_forwarded_proto" '
                       'alb_trace="$http_x_amzn_trace_id"';
EOF

# Find the line number of 'http {' and add the log format after it
LINE_NUM=$(grep -n "^http {" "$NGINX_CONF" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    print_error "Could not find 'http {' block in $NGINX_CONF"
    rm "$TEMP_FILE"
    exit 1
fi

# Insert the log format after the 'http {' line
sed -i "${LINE_NUM}r ${TEMP_FILE}" "$NGINX_CONF"
rm "$TEMP_FILE"

print_success "Added custom log format to $NGINX_CONF"

# Update cloudscrapers.conf to use the new log format (if it exists)
SITE_CONF="/etc/nginx/conf.d/cloudscrapers.conf"
if [ -f "$SITE_CONF" ]; then
    print_info "Updating cloudscrapers.conf to use custom log format..."

    # Backup site config
    SITE_BACKUP="${SITE_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$SITE_CONF" "$SITE_BACKUP"

    # Replace 'combined' with 'alb_log'
    sed -i 's/access_log \/var\/log\/nginx\/cloudscrapers-access.log combined;/access_log \/var\/log\/nginx\/cloudscrapers-access.log alb_log;/' "$SITE_CONF"

    print_success "Updated cloudscrapers.conf to use alb_log format"
fi

# Test nginx configuration
print_info "Testing Nginx configuration..."
if nginx -t; then
    print_success "Nginx configuration is valid"

    # Reload nginx
    print_info "Reloading Nginx..."
    nginx -s reload
    print_success "Nginx reloaded successfully"

    echo ""
    echo "========================================"
    print_success "Installation Complete!"
    echo "========================================"
    echo ""
    echo "Your Nginx logs will now include:"
    echo "  • Original client IP (from X-Forwarded-For)"
    echo "  • Protocol used (HTTP/HTTPS from X-Forwarded-Proto)"
    echo "  • AWS ALB trace ID (from X-Amzn-Trace-Id)"
    echo ""
    echo "View logs with:"
    echo "  sudo tail -f /var/log/nginx/cloudscrapers-access.log"
    echo ""
else
    print_error "Nginx configuration test failed"
    print_info "Restoring original configuration..."
    cp "$BACKUP_FILE" "$NGINX_CONF"
    [ -f "$SITE_BACKUP" ] && cp "$SITE_BACKUP" "$SITE_CONF"
    print_success "Original configuration restored"
    exit 1
fi
