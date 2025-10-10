#!/bin/bash

# RFQ Tracker - Automated Installation Script
# For fresh Ubuntu/Debian servers

set -e  # Exit on any error

echo "================================================"
echo "  RFQ Tracker - Production Installation"
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
echo "[1/10] Updating system packages..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt update && sudo apt upgrade -y
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum update -y
fi

# Step 2: Install dependencies
echo "[2/10] Installing required packages..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt install -y python3 python3-pip python3-venv git nginx sqlite3
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum install -y python3 python3-pip git nginx sqlite
fi

# Step 3: Clone repository
echo "[3/10] Cloning RFQ Tracker repository..."
cd ~
if [ -d "rfq-tracker" ]; then
    echo "Directory rfq-tracker already exists. Updating..."
    cd rfq-tracker
    git pull origin main
else
    git clone https://github.com/Nikolaihoj1/rfq-tracker.git
    cd rfq-tracker
fi

APP_DIR=$(pwd)
echo "Application directory: $APP_DIR"

# Step 4: Create virtual environment
echo "[4/10] Setting up Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# Step 5: Install Python dependencies
echo "[5/10] Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

# Step 6: Initialize database
echo "[6/10] Initializing database..."
timeout 5 python app.py || true
echo "Database initialized."

# Step 7: Create systemd service
echo "[7/10] Creating systemd service..."
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
ExecStart=$APP_DIR/.venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 'app:create_app()'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service created."

# Step 8: Enable and start service
echo "[8/10] Starting RFQ Tracker service..."
sudo systemctl daemon-reload
sudo systemctl enable rfq-tracker
sudo systemctl start rfq-tracker
sleep 2
sudo systemctl status rfq-tracker --no-pager

# Step 9: Configure Nginx
echo "[9/10] Configuring Nginx..."

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

NGINX_CONFIG="/etc/nginx/sites-available/rfq-tracker"

sudo tee $NGINX_CONFIG > /dev/null <<EOF
server {
    listen 80;
    server_name $SERVER_IP _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /static {
        alias $APP_DIR/static;
        expires 30d;
    }
}
EOF

# Enable site
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo cp $NGINX_CONFIG /etc/nginx/conf.d/rfq-tracker.conf
fi

sudo nginx -t
sudo systemctl restart nginx

# Step 10: Configure firewall
echo "[10/10] Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw --force enable
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    echo "UFW firewall configured."
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
    echo "Firewalld configured."
fi

echo ""
echo "================================================"
echo "  Installation Complete!"
echo "================================================"
echo ""
echo "RFQ Tracker is now running at:"
echo "  http://$SERVER_IP"
echo "  http://$SERVER_IP/admin (Admin panel)"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status rfq-tracker    # Check service status"
echo "  sudo systemctl restart rfq-tracker   # Restart service"
echo "  sudo journalctl -u rfq-tracker -f    # View logs"
echo ""
echo "To update the application:"
echo "  cd $APP_DIR"
echo "  git pull origin main"
echo "  source .venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  sudo systemctl restart rfq-tracker"
echo ""
echo "For HTTPS setup with Let's Encrypt:"
echo "  sudo apt install certbot python3-certbot-nginx"
echo "  sudo certbot --nginx -d your-domain.com"
echo ""
echo "================================================"

