#!/bin/bash

# RFQ Tracker - Systemd Service Setup Script
# Run this script on your server to set up the systemd service

set -e

echo "================================================"
echo "  RFQ Tracker - Service Setup"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root: sudo ./setup-service.sh"
    exit 1
fi

# Get the current directory
APP_DIR=$(pwd)
echo "Application directory: $APP_DIR"

# Detect the non-root user running the app
if [ -n "$SUDO_USER" ]; then
    APP_USER=$SUDO_USER
else
    # If running directly as root, ask for username
    read -p "Enter the username to run the service (e.g., rfq): " APP_USER
fi

echo "Service will run as user: $APP_USER"
echo ""

# Verify the user exists
if ! id "$APP_USER" &>/dev/null; then
    echo "User $APP_USER does not exist!"
    read -p "Do you want to create this user? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        useradd -m -s /bin/bash $APP_USER
        echo "User $APP_USER created."
    else
        echo "Exiting. Please create the user first."
        exit 1
    fi
fi

# Verify virtual environment exists
if [ ! -d "$APP_DIR/.venv" ]; then
    echo "Virtual environment not found at $APP_DIR/.venv"
    echo "Please run the following first:"
    echo "  python3 -m venv .venv"
    echo "  source .venv/bin/activate"
    echo "  pip install -r requirements.txt"
    echo "  pip install gunicorn"
    exit 1
fi

# Verify gunicorn is installed
if [ ! -f "$APP_DIR/.venv/bin/gunicorn" ]; then
    echo "Gunicorn not found. Installing..."
    $APP_DIR/.venv/bin/pip install gunicorn
fi

# Create systemd service file
echo "Creating systemd service file..."
cat > /etc/systemd/system/rfq-tracker.service <<EOF
[Unit]
Description=RFQ Tracker Application
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/.venv/bin"
ExecStart=$APP_DIR/.venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 'app:create_app()'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Service file created at: /etc/systemd/system/rfq-tracker.service"

# Set proper ownership
echo "Setting proper ownership..."
chown -R $APP_USER:$APP_USER $APP_DIR

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload

# Enable service
echo "Enabling service..."
systemctl enable rfq-tracker

# Start service
echo "Starting service..."
systemctl start rfq-tracker

# Wait a moment
sleep 2

# Check status
echo ""
echo "================================================"
echo "Service Status:"
echo "================================================"
systemctl status rfq-tracker --no-pager

echo ""
echo "================================================"
echo "  Setup Complete!"
echo "================================================"
echo ""
echo "Useful commands:"
echo "  systemctl status rfq-tracker    # Check status"
echo "  systemctl restart rfq-tracker   # Restart service"
echo "  systemctl stop rfq-tracker      # Stop service"
echo "  journalctl -u rfq-tracker -f    # View logs"
echo ""

