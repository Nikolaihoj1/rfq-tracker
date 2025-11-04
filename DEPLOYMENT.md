# Local Service Deployment Guide - Linux Server

Complete guide for deploying the RFQ Tracker as a local-only service on a Linux server (no reverse proxy).

---

## Prerequisites

Fresh Ubuntu/Debian or RHEL/CentOS server with:
- Root or sudo access
- Internet connection
- Git installed (for cloning repository)

---

## Quick Install (Automated)

For the fastest setup, use the automated installation script:

```bash
# Step 1: Install git first
sudo apt install -y git  # Ubuntu/Debian
# OR
sudo yum install -y git  # CentOS/RHEL

# Step 2: Clone repository
cd ~
git clone https://github.com/Nikolaihoj1/rfq-tracker.git
cd rfq-tracker
git checkout main

# Step 3: Run automated installer
chmod +x install.sh
./install.sh
```

The script will handle all steps automatically. See [README.md](README.md) for details.

---

## Manual Installation (Step-by-Step)

### Step 1: Update System

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

---

### Step 2: Install Git (Required for Cloning)

**Ubuntu/Debian:**

```bash
sudo apt install -y git
```

**CentOS/RHEL:**

```bash
sudo yum install -y git
```

---

### Step 3: Clone the Repository

```bash
cd ~
git clone https://github.com/Nikolaihoj1/rfq-tracker.git
cd rfq-tracker
git checkout main
```

**Important:** Make sure you're on the `main` branch where all the files are located.

---

### Step 4: Install Required Packages

**Ubuntu/Debian:**

```bash
sudo apt install -y python3 python3-pip python3-venv sqlite3
```

**CentOS/RHEL:**

```bash
sudo yum install -y python3 python3-pip sqlite
```

**Note:** Nginx is not required since we're running local-only without reverse proxy.

---

### Step 5: Create Application User (Optional but Recommended)

```bash
sudo useradd -m -s /bin/bash rfqapp
sudo su - rfqapp
```

Or continue as your current user. If you created this user, repeat Steps 3-4 as this user.

---

### Step 6: Set Up Python Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

---

### Step 7: Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn
```

---

### Step 8: Initialize Database (First Run)

```bash
# Test run to create database
python app.py
# Press Ctrl+C after it starts successfully
```

This creates `rfq.db` with sample data.

---

### Step 9: Set Up Systemd Service

#### Create systemd service file

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
ExecStart=/home/YOUR_USERNAME/rfq-tracker/.venv/bin/gunicorn -w 4 -b 0.0.0.0:5000 'app:create_app()'
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

#### Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable rfq-tracker
sudo systemctl start rfq-tracker
sudo systemctl status rfq-tracker
```

---

### Step 10: Verify Deployment

#### Check service status

```bash
sudo systemctl status rfq-tracker
```

#### View application logs

```bash
sudo journalctl -u rfq-tracker -f
```

#### Test the application

Open your browser (on the server or from another device on the local network) and navigate to:
- `http://SERVER_IP:5000` (replace SERVER_IP with your server's IP address)
- `http://SERVER_IP:5000/admin` for the admin panel

**Note:** The application runs on `0.0.0.0:5000` which allows access from devices on your local network. Access it using the server's IP address from other devices.

---

## Using the Setup Script

Alternatively, you can use the `setup-service.sh` script if you've already installed the application manually:

```bash
cd ~/rfq-tracker
chmod +x setup-service.sh
sudo ./setup-service.sh
```

This script will:
- Create the systemd service file
- Set proper permissions
- Enable and start the service

---

## Updating the Application

To pull and deploy updates:

```bash
cd ~/rfq-tracker
git checkout main
git pull origin main
source .venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart rfq-tracker
```

See [UPDATE.md](UPDATE.md) for detailed update instructions.

---

## Troubleshooting

### Check if service is running

```bash
sudo systemctl status rfq-tracker
sudo journalctl -u rfq-tracker -n 50
```

### Check port usage

```bash
sudo netstat -tlnp | grep :5000  # Service should be listening on 0.0.0.0:5000 (all interfaces)
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

1. **Regular backups** of `rfq.db`:
   ```bash
   # Add to crontab
   0 2 * * * cp ~/rfq-tracker/rfq.db ~/backups/rfq-$(date +\%Y\%m\%d).db
   ```
2. **Keep system updated**:
   ```bash
   sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
   ```
3. **Monitor logs regularly**:
   ```bash
   sudo journalctl -u rfq-tracker -f
   ```
4. **Since it's local-only**, ensure SSH access is properly secured

---

## Performance Tuning

### Adjust Gunicorn workers

In `/etc/systemd/system/rfq-tracker.service`, modify:

```
ExecStart=...gunicorn -w 4 -b 127.0.0.1:5000 ...
```

Recommended workers: `(2 x CPU cores) + 1`

---

## Alternative: Using Flask Development Server

If you prefer to use Flask's built-in server instead of Gunicorn:

Update the service file `ExecStart` line:
```ini
ExecStart=/home/YOUR_USERNAME/rfq-tracker/.venv/bin/python app.py
```

**Note:** When using Flask's built-in server with `app.py`, it will listen on `0.0.0.0:5000` by default, making it accessible from your local network. Gunicorn is still recommended for better performance and stability.

---

## Support

For issues, check the logs:
```bash
sudo journalctl -u rfq-tracker -n 100
```

GitHub: https://github.com/Nikolaihoj1/rfq-tracker/issues
