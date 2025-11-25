# Deployment Troubleshooting Guide

This guide helps you resolve common issues when deploying the CloudScrapers website.

## Quick Fixes

### Permission Denied Errors

**Problem:**
```
cp: cannot create regular file '/var/www/cloudscrapers/index.html': Permission denied
```

**Solution:**
The fixed deployment script now uses `sudo cp` for all copy operations. If you still encounter this:

1. **Verify you're running from the repository directory:**
   ```bash
   pwd  # Should show: /home/ec2-user/cloudscrapers-website (or similar)
   ls -la index.html  # Should exist
   ```

2. **Ensure sudo privileges:**
   ```bash
   sudo -l  # Should show you have sudo access
   ```

3. **Manual deployment if script fails:**
   ```bash
   # Create directory
   sudo mkdir -p /var/www/cloudscrapers

   # Copy files
   sudo cp -r index.html styles.css script.js translations.js /var/www/cloudscrapers/
   sudo cp -r img platform /var/www/cloudscrapers/

   # Set permissions
   NGINX_GROUP=$(getent group nginx >/dev/null && echo "nginx" || echo "www-data")
   sudo chown -R $USER:$NGINX_GROUP /var/www/cloudscrapers
   sudo chmod -R 755 /var/www/cloudscrapers
   sudo find /var/www/cloudscrapers -type f -exec chmod 644 {} \;
   ```

---

## Common Issues

### Issue 1: Nginx Won't Start

**Error:**
```
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
```

**Solution:**
```bash
# Check what's using port 80
sudo netstat -tlnp | grep :80

# If it's Apache, stop it
sudo systemctl stop httpd
sudo systemctl disable httpd

# Start Nginx
sudo systemctl start nginx
```

---

### Issue 2: 403 Forbidden Error

**Error:** Browser shows "403 Forbidden"

**Solution:**
```bash
# Check file permissions
ls -la /var/www/cloudscrapers/index.html

# Should show: -rw-r--r-- 1 ec2-user nginx

# Fix permissions
sudo chown -R ec2-user:nginx /var/www/cloudscrapers
sudo chmod -R 755 /var/www/cloudscrapers
sudo find /var/www/cloudscrapers -type f -exec chmod 644 {} \;
sudo find /var/www/cloudscrapers -type d -exec chmod 755 {} \;

# Check SELinux (if on RHEL/CentOS/Amazon Linux)
sudo getenforce
# If "Enforcing", set proper context:
sudo chcon -R -t httpd_sys_content_t /var/www/cloudscrapers/
# Or disable SELinux temporarily:
sudo setenforce 0
```

---

### Issue 3: Nginx Configuration Test Fails

**Error:**
```
nginx: configuration file /etc/nginx/nginx.conf test failed
```

**Common Error: log_format directive not allowed**
```
nginx: [emerg] "log_format" directive is not allowed here in /etc/nginx/conf.d/cloudscrapers.conf:64
```

**Solution:**
This error occurs because `log_format` can only be defined in the `http` context (main nginx.conf), not in server blocks or conf.d includes.

**Quick Fix - Use default log format:**
The latest nginx-alb.conf uses the default 'combined' format. Pull the latest changes:
```bash
cd ~/cloudscrapers-website
git pull
sudo cp nginx-alb.conf /etc/nginx/conf.d/cloudscrapers.conf
sudo nginx -t
sudo systemctl reload nginx
```

**Optional - Install custom ALB log format:**
If you want enhanced logging with ALB headers (X-Forwarded-For, X-Amzn-Trace-Id, etc.):
```bash
cd ~/cloudscrapers-website
sudo ./install-custom-log-format.sh
```

**Other Configuration Issues:**
```bash
# Check detailed error
sudo nginx -t

# Common fixes:
# 1. Check for typos in config
sudo nano /etc/nginx/conf.d/cloudscrapers.conf

# 2. Verify file exists
ls -la /var/www/cloudscrapers/index.html

# 3. Test with minimal config
sudo mv /etc/nginx/conf.d/cloudscrapers.conf /tmp/
sudo nginx -t  # Should pass now
sudo mv /tmp/cloudscrapers.conf /etc/nginx/conf.d/
```

---

### Issue 4: Health Check Failing on ALB

**Problem:** ALB shows instances as "unhealthy"

**Solution:**
```bash
# Test health check locally
curl -v http://localhost/health

# Should return: HTTP/1.1 200 OK with "healthy"

# If fails, check:
# 1. Nginx is running
sudo systemctl status nginx

# 2. Check Nginx access logs
sudo tail -f /var/log/nginx/cloudscrapers-access.log

# 3. Verify security group allows ALB to reach EC2
# In AWS Console: EC2 > Security Groups > Inbound Rules
# Should have: HTTP (80) from ALB Security Group
```

---

### Issue 5: SSL/TLS Errors

**Problem:** Browser shows "Your connection is not private"

**For ALB Setup (Recommended):**
```bash
# ALB should handle SSL, EC2 only needs HTTP
# Verify ALB listener:
# - Port 443 → Forward to target group
# - SSL certificate from ACM attached

# In your EC2 nginx config, should only listen on port 80
grep "listen" /etc/nginx/conf.d/cloudscrapers.conf
# Should show: listen 80;
```

**For Direct SSL on EC2:**
```bash
# Generate self-signed certificate (for testing only)
sudo mkdir -p /etc/ssl/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/cloudscrapers.key \
  -out /etc/ssl/certs/cloudscrapers.crt

# For production, use Let's Encrypt:
sudo yum install certbot python3-certbot-nginx -y
sudo certbot --nginx -d cloudscrapers.pl -d www.cloudscrapers.pl
```

---

### Issue 6: Static Files Not Loading

**Problem:** HTML loads but CSS/JS don't

**Solution:**
```bash
# Check browser console for 404 errors
# Verify files exist:
ls -la /var/www/cloudscrapers/styles.css
ls -la /var/www/cloudscrapers/script.js
ls -la /var/www/cloudscrapers/platform/

# Check Nginx access logs
sudo tail -f /var/log/nginx/cloudscrapers-access.log

# Verify MIME types
curl -I http://localhost/styles.css
# Should show: Content-Type: text/css

# If not, check Nginx config
grep "types_hash_max_size" /etc/nginx/nginx.conf
```

---

### Issue 7: Rate Limiting Too Aggressive

**Problem:** Users getting 503 errors

**Solution:**
```bash
# Edit nginx config
sudo nano /etc/nginx/conf.d/cloudscrapers.conf

# Increase rate limits at the top:
# Change from:
# limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
# To:
# limit_req_zone $binary_remote_addr zone=general:10m rate=50r/s;

# And increase burst:
# Change from:
# limit_req zone=general burst=20 nodelay;
# To:
# limit_req zone=general burst=100 nodelay;

# Test and reload
sudo nginx -t
sudo nginx -s reload
```

---

## Verification Checklist

After deployment, verify everything works:

```bash
# 1. Nginx is running
sudo systemctl status nginx

# 2. Website loads locally
curl -I http://localhost/
# Should return: HTTP/1.1 200 OK

# 3. Health check works
curl http://localhost/health
# Should return: healthy

# 4. Static files work
curl -I http://localhost/styles.css
# Should return: HTTP/1.1 200 OK

# 5. Platform loads
curl -I http://localhost/platform/
# Should return: HTTP/1.1 200 OK

# 6. Check error logs
sudo tail -20 /var/log/nginx/cloudscrapers-error.log
# Should be empty or minimal

# 7. Verify file permissions
ls -la /var/www/cloudscrapers/
# Files should be: -rw-r--r-- 1 ec2-user nginx
# Dirs should be: drwxr-xr-x 1 ec2-user nginx
```

---

## Performance Testing

```bash
# Install Apache Bench
sudo yum install httpd-tools -y  # Amazon Linux
sudo apt install apache2-utils -y  # Ubuntu

# Test website performance
ab -n 1000 -c 10 http://localhost/

# Expected results:
# - Requests per second: > 500
# - Failed requests: 0
# - 50% served within: < 100ms
# - 99% served within: < 500ms
```

---

## Logs and Debugging

**View Nginx error log:**
```bash
sudo tail -f /var/log/nginx/cloudscrapers-error.log
```

**View Nginx access log:**
```bash
sudo tail -f /var/log/nginx/cloudscrapers-access.log
```

**View Nginx status:**
```bash
sudo systemctl status nginx -l
```

**Test Nginx config:**
```bash
sudo nginx -t
```

**Reload Nginx (zero-downtime):**
```bash
sudo nginx -s reload
```

**Restart Nginx (with brief downtime):**
```bash
sudo systemctl restart nginx
```

---

## Getting Help

If issues persist:

1. **Check logs:**
   ```bash
   sudo journalctl -u nginx -n 50 --no-pager
   ```

2. **Verify AWS resources:**
   - Security groups allow traffic
   - Target group health checks configured correctly
   - ALB listeners properly configured

3. **Contact support:**
   - Email: biuro@cloudscrapers.pl
   - Include: error logs, nginx -t output, systemctl status output

---

## Quick Recovery

If everything breaks, start fresh:

```bash
# Stop Nginx
sudo systemctl stop nginx

# Backup current config
sudo cp -r /etc/nginx /etc/nginx.backup.$(date +%Y%m%d)

# Remove all configs
sudo rm -f /etc/nginx/conf.d/cloudscrapers.conf

# Re-run deployment script
cd ~/cloudscrapers-website
./deploy-to-ec2.sh
```
