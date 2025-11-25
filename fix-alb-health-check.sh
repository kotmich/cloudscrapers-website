#!/bin/bash
# ALB Health Check Fixer
# Diagnoses and helps fix ALB health check issues

set -e

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

print_header "ALB Health Check Diagnostics"

PRIVATE_IP=$(hostname -I | awk '{print $1}')
print_success "Instance Private IP: $PRIVATE_IP"

echo ""
print_header "Testing Health Check Endpoint Locally"

# Test with different methods that ALB might use
echo "1. Testing: curl http://localhost/health"
RESPONSE=$(curl -s -o /tmp/health_test.txt -w "%{http_code}" http://localhost/health 2>&1)
echo "   HTTP Status: $RESPONSE"
echo "   Response Body: $(cat /tmp/health_test.txt)"
if [ "$RESPONSE" = "200" ]; then
    print_success "localhost health check OK"
else
    print_error "localhost health check FAILED"
fi

echo ""
echo "2. Testing: curl http://$PRIVATE_IP/health"
RESPONSE=$(curl -s -o /tmp/health_test.txt -w "%{http_code}" http://$PRIVATE_IP/health 2>&1)
echo "   HTTP Status: $RESPONSE"
echo "   Response Body: $(cat /tmp/health_test.txt)"
if [ "$RESPONSE" = "200" ]; then
    print_success "Private IP health check OK"
else
    print_error "Private IP health check FAILED"
fi

echo ""
echo "3. Testing: curl -v http://$PRIVATE_IP/health (verbose)"
curl -v http://$PRIVATE_IP/health 2>&1 | grep -E "(< HTTP|< Server|< Content-Type|^healthy)"

echo ""
echo "4. Testing with HTTP/1.0 (some ALBs use this):"
printf "GET /health HTTP/1.0\r\nHost: $PRIVATE_IP\r\n\r\n" | nc -w 3 $PRIVATE_IP 80

print_header "Common ALB Health Check Issues"

echo "Based on your symptoms, here are the most likely issues:"
echo ""
echo "❌ ISSUE #1: Health check path is wrong in ALB Target Group"
echo "   Fix: Set health check path to: /health (with leading slash)"
echo ""
echo "❌ ISSUE #2: Health check is using HTTPS instead of HTTP"
echo "   Fix: Set health check protocol to: HTTP (not HTTPS)"
echo ""
echo "❌ ISSUE #3: Success codes don't include 200"
echo "   Fix: Set success codes to: 200"
echo ""
echo "❌ ISSUE #4: Health check timeout is too short"
echo "   Fix: Increase timeout to at least 5 seconds"
echo ""
echo "❌ ISSUE #5: Healthy threshold is too high"
echo "   Fix: Set healthy threshold to: 2 or 3"
echo ""

print_header "How to Fix in AWS Console"

echo "Step-by-step instructions:"
echo ""
echo "1. Go to AWS Console: EC2 > Target Groups"
echo ""
echo "2. Select your target group for CloudScrapers"
echo ""
echo "3. Click 'Health checks' tab"
echo ""
echo "4. Click 'Edit health check settings'"
echo ""
echo "5. Configure these EXACT settings:"
echo "   ┌─────────────────────────────────────┐"
echo "   │ Health check protocol: HTTP         │"
echo "   │ Health check path: /health          │"
echo "   │ Health check port: Traffic port     │"
echo "   │ Success codes: 200                  │"
echo "   │ Healthy threshold: 2                │"
echo "   │ Unhealthy threshold: 2              │"
echo "   │ Timeout: 5 seconds                  │"
echo "   │ Interval: 30 seconds                │"
echo "   └─────────────────────────────────────┘"
echo ""
echo "6. Click 'Save changes'"
echo ""
echo "7. Go to 'Targets' tab and wait 30-60 seconds"
echo ""
echo "8. Status should change from 'unhealthy' to 'healthy'"
echo ""

print_header "Using AWS CLI (Optional)"

echo "If you have AWS CLI configured, run these commands:"
echo ""
echo "# Get your target group ARN"
echo "aws elbv2 describe-target-groups --names cloudscrapers-tg --query 'TargetGroups[0].TargetGroupArn' --output text"
echo ""
echo "# Update health check settings"
echo "aws elbv2 modify-target-group \\"
echo "  --target-group-arn <YOUR_TG_ARN> \\"
echo "  --health-check-protocol HTTP \\"
echo "  --health-check-path /health \\"
echo "  --health-check-interval-seconds 30 \\"
echo "  --health-check-timeout-seconds 5 \\"
echo "  --healthy-threshold-count 2 \\"
echo "  --unhealthy-threshold-count 2 \\"
echo "  --matcher HttpCode=200"
echo ""
echo "# Check target health"
echo "aws elbv2 describe-target-health --target-group-arn <YOUR_TG_ARN>"
echo ""

print_header "Monitoring Health Check Status"

echo "Watch the health check in real-time:"
echo ""
echo "# On EC2, monitor access logs:"
echo "sudo tail -f /var/log/nginx/cloudscrapers-access.log | grep health"
echo ""
echo "# You should see requests from ALB IPs every 30 seconds"
echo "# Example: 10.0.x.x - - [date] \"GET /health HTTP/1.1\" 200"
echo ""

print_header "Common Mistakes to Avoid"

echo "✗ Don't use 'index.html' as health check path"
echo "✗ Don't use HTTPS protocol (unless you configured SSL on EC2)"
echo "✗ Don't forget the leading slash: /health (not 'health')"
echo "✗ Don't set success codes to '200-399' if your health endpoint returns 200"
echo "✗ Don't set timeout lower than 5 seconds"
echo ""

print_header "Quick Validation Checklist"

echo "Before making changes, verify on EC2:"
echo ""
echo "✓ Nginx is running:"
systemctl is-active nginx && print_success "Nginx is running" || print_error "Nginx is NOT running"
echo ""
echo "✓ Health endpoint returns 200:"
HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
if [ "$HEALTH_CODE" = "200" ]; then
    print_success "Health endpoint returns 200"
else
    print_error "Health endpoint returns $HEALTH_CODE (should be 200)"
fi
echo ""
echo "✓ Health endpoint returns 'healthy':"
HEALTH_BODY=$(curl -s http://localhost/health)
if [ "$HEALTH_BODY" = "healthy" ]; then
    print_success "Health endpoint body is correct"
else
    print_warning "Health endpoint body: '$HEALTH_BODY' (expected: 'healthy')"
fi
echo ""
echo "✓ Accessible from private IP:"
PRIVATE_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://$PRIVATE_IP/health)
if [ "$PRIVATE_HEALTH" = "200" ]; then
    print_success "Health check accessible from private IP"
else
    print_error "Health check NOT accessible from private IP"
fi

echo ""
print_header "Next Steps"
echo ""
echo "1. Fix ALB target group health check settings (see above)"
echo "2. Wait 60 seconds for health checks to update"
echo "3. Check target health in AWS Console (EC2 > Target Groups > Targets tab)"
echo "4. Once healthy, try accessing cloudscrapers.pl in browser"
echo ""

rm -f /tmp/health_test.txt
