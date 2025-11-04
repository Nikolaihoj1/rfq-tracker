#!/bin/bash

# RFQ Tracker - Automated Installation Script
# For fresh Ubuntu/Debian/CentOS/RHEL servers
# Installs RFQ Tracker as a local-only service (no reverse proxy)
#
# Prerequisites: git must be installed to clone this repository
# Install git first:
#   Ubuntu/Debian: sudo apt install -y git
#   CentOS/RHEL:   sudo yum install -y git

set -e  # Exit on any error

echo "================================================"
echo "  RFQ Tracker - Local Installation"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run as root. Run as a regular user with sudo privileges."
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Please install manually."
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Step 1: Update system
echo "[1/8] Updating system packages..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt update && sudo apt upgrade -y
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum update -y
fi

# Step 2: Install dependencies
echo "[2/8] Installing required packages..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt install -y python3 python3-pip python3-venv git sqlite3
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum install -y python3 python3-pip git sqlite
fi

# Step 3: Clone repository
echo "[3/8] Cloning RFQ Tracker repository..."
cd ~
if [ -d "rfq-tracker" ]; then
    echo "Directory rfq-tracker already exists. Updating..."
    cd rfq-tracker
    git checkout main
    git pull origin main
else
    git clone https://github.com/Nikolaihoj1/rfq-tracker.git
    cd rfq-tracker
    git checkout main
fi

APP_DIR=$(pwd)
echo "Application directory: $APP_DIR"

# Step 4: Create virtual environment
echo "[4/8] Setting up Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# Step 5: Install Python dependencies
echo "[5/8] Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

# Step 6: Initialize database
echo "[6/8] Initializing database..."
timeout 5 python app.py || true
echo "Database initialized."

# Step 7: Create systemd service
echo "[7/8] Creating systemd service..."
SERVICE_FILE="/etc/systemd/system/rfq-tracker.service"

sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=RFQ Tracker Application
After=network.target

[Service]
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/.venv/bin"
ExecStart=$APP_DIR/.venv/bin/gunicorn -w 4 -b 0.0.0.0:5000 'app:create_app()'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service created."

# Step 8: Enable and start service
echo "[8/8] Starting RFQ Tracker service..."
sudo systemctl daemon-reload
sudo systemctl enable rfq-tracker
sudo systemctl start rfq-tracker
sleep 2
sudo systemctl status rfq-tracker --no-pager


echo ""
echo "================================================"
echo "  Installation Complete!"
echo "================================================"
echo ""
echo "RFQ Tracker is now running as a service at:"
echo "  http://$(hostname -I | awk '{print $1}'):5000"
echo "  http://$(hostname -I | awk '{print $1}'):5000/admin (Admin panel)"
echo ""
echo "Note: The application runs on 0.0.0.0:5000 (accessible from local network)"
echo "Access it from any device on your local network using the server's IP address"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status rfq-tracker    # Check service status"
echo "  sudo systemctl restart rfq-tracker   # Restart service"
echo "  sudo systemctl stop rfq-tracker      # Stop service"
echo "  sudo journalctl -u rfq-tracker -f    # View logs"
echo ""
echo "To update the application:"
echo "  cd $APP_DIR"
echo "  git pull origin main"
echo "  source .venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  sudo systemctl restart rfq-tracker"
echo ""
echo "================================================"

