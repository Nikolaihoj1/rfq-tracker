# Production Deployment Guide - Fresh Server

Complete guide for deploying the RFQ Tracker on a fresh Linux server.

---

## Prerequisites

Fresh Ubuntu/Debian or RHEL/CentOS server with:
- Root or sudo access
- Internet connection
- Domain name (optional, for Nginx setup)

---

## Step 1: Update System

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

---

## Step 2: Install Required Packages

### Ubuntu/Debian

```bash
sudo apt install -y python3 python3-pip python3-venv git nginx sqlite3
```

### CentOS/RHEL

```bash
sudo yum install -y python3 python3-pip git nginx sqlite
```

---

## Step 3: Create Application User (Optional but Recommended)

```bash
sudo useradd -m -s /bin/bash rfqapp
sudo su - rfqapp
```

Or continue as your current user.

---

## Step 4: Clone the Repository

```bash
cd ~
git clone https://github.com/Nikolaihoj1/rfq-tracker.git
cd rfq-tracker
```

---

## Step 5: Set Up Python Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

---

## Step 6: Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn
```

---

## Step 7: Initialize Database (First Run)

```bash
# Test run to create database
python app.py
# Press Ctrl+C after it starts successfully
```

This creates `rfq.db` with sample data.

---

## Step 8: Set Up Gunicorn Service

### Create systemd service file

```bash
sudo nano /etc/systemd/system/rfq-tracker.service
```

**For regular user deployment:**

```ini
[Unit]
Description=RFQ Tracker Application
After=network.target

[Service]
User=YOUR_USERNAME
Group=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/rfq-tracker
Environment="PATH=/home/YOUR_USERNAME/rfq-tracker/.venv/bin"
ExecStart=/home/YOUR_USERNAME/rfq-tracker/.venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 'app:create_app()'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Replace `YOUR_USERNAME` with your actual username!**

If using `rfqapp` user, replace with:
```ini
User=rfqapp
Group=rfqapp
WorkingDirectory=/home/rfqapp/rfq-tracker
Environment="PATH=/home/rfqapp/rfq-tracker/.venv/bin"
ExecStart=/home/rfqapp/rfq-tracker/.venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 'app:create_app()'
```

### Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable rfq-tracker
sudo systemctl start rfq-tracker
sudo systemctl status rfq-tracker
```

---

## Step 9: Configure Firewall

### Ubuntu (UFW)

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS (if using SSL)
sudo ufw enable
```

### CentOS/RHEL (Firewalld)

```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

---

## Step 10: Configure Nginx Reverse Proxy

### Create Nginx configuration

```bash
sudo nano /etc/nginx/sites-available/rfq-tracker
```

**Basic configuration (HTTP only):**

```nginx
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain or server IP

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (if needed in future)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Serve static files directly (optional optimization)
    location /static {
        alias /home/YOUR_USERNAME/rfq-tracker/static;
        expires 30d;
    }
}
```

### Enable the site

**Ubuntu/Debian:**

```bash
sudo ln -s /etc/nginx/sites-available/rfq-tracker /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**CentOS/RHEL:**

```bash
# Edit main nginx.conf to include the config
sudo cp /etc/nginx/sites-available/rfq-tracker /etc/nginx/conf.d/rfq-tracker.conf
sudo nginx -t
sudo systemctl restart nginx
```

---

## Step 11: Enable HTTPS with Let's Encrypt (Optional but Recommended)

### Install Certbot

**Ubuntu/Debian:**

```bash
sudo apt install -y certbot python3-certbot-nginx
```

**CentOS/RHEL:**

```bash
sudo yum install -y certbot python3-certbot-nginx
```

### Get SSL certificate

```bash
sudo certbot --nginx -d your-domain.com
```

Follow the prompts. Certbot will automatically configure Nginx for HTTPS.

---

## Step 12: Verify Deployment

### Check service status

```bash
sudo systemctl status rfq-tracker
```

### Check Nginx status

```bash
sudo systemctl status nginx
```

### View application logs

```bash
sudo journalctl -u rfq-tracker -f
```

### Test the application

Open your browser and navigate to:
- `http://your-domain.com` (or `http://your-server-ip`)
- `http://your-domain.com/admin` for the admin panel

---

## Updating the Application

To pull and deploy updates:

```bash
cd ~/rfq-tracker
source .venv/bin/activate
git pull origin main
pip install -r requirements.txt
sudo systemctl restart rfq-tracker
```

---

## Troubleshooting

### Check if Gunicorn is running

```bash
sudo systemctl status rfq-tracker
sudo journalctl -u rfq-tracker -n 50
```

### Check if Nginx is running

```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
```

### Check port usage

```bash
sudo netstat -tlnp | grep :5000  # Gunicorn
sudo netstat -tlnp | grep :80    # Nginx
```

### Permission issues

```bash
# Make sure the user has access to the directory
ls -la ~/rfq-tracker
sudo chown -R YOUR_USERNAME:YOUR_USERNAME ~/rfq-tracker
```

### Database file permissions

```bash
chmod 644 ~/rfq-tracker/rfq.db
```

---

## Security Recommendations

1. **Change default admin credentials** (if you add authentication in the future)
2. **Regular backups** of `rfq.db`:
   ```bash
   # Add to crontab
   0 2 * * * cp ~/rfq-tracker/rfq.db ~/backups/rfq-$(date +\%Y\%m\%d).db
   ```
3. **Keep system updated**:
   ```bash
   sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
   ```
4. **Monitor logs regularly**:
   ```bash
   sudo journalctl -u rfq-tracker -f
   ```
5. **Set up fail2ban** to prevent brute force attacks (optional)

---

## Performance Tuning

### Adjust Gunicorn workers

In `/etc/systemd/system/rfq-tracker.service`, modify:

```
ExecStart=...gunicorn -w 4 -b 127.0.0.1:5000 ...
```

Recommended workers: `(2 x CPU cores) + 1`

### Enable Nginx gzip compression

Add to Nginx config:

```nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
```

---

## Quick Install Script

For convenience, here's a one-liner that you can adapt:

```bash
curl -o- https://raw.githubusercontent.com/Nikolaihoj1/rfq-tracker/main/install.sh | bash
```

*(Note: Create `install.sh` script if needed)*

---

## Support

For issues, check the logs:
```bash
sudo journalctl -u rfq-tracker -n 100
```

GitHub: https://github.com/Nikolaihoj1/rfq-tracker/issues

