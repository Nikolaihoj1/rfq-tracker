#!/bin/bash

# RFQ Tracker - Safe Update Script
# Updates the application code without touching the existing database
#
# Usage: ./update.sh

set -e  # Exit on any error

echo "================================================"
echo "  RFQ Tracker - Safe Update"
echo "================================================"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if database exists
DB_FILE="rfq.db"
DB_BACKUP="rfq.db.backup.$(date +%Y%m%d_%H%M%S)"

if [ -f "$DB_FILE" ]; then
    echo "[1/6] Backing up existing database..."
    cp "$DB_FILE" "$DB_BACKUP"
    echo "Database backed up to: $DB_BACKUP"
else
    echo "[1/6] No existing database found (will be created on first run)"
fi

# Step 2: Pull latest changes from git
echo ""
echo "[2/6] Pulling latest changes from git..."
git checkout main
git pull origin main

# Step 3: Activate virtual environment if it exists
echo ""
echo "[3/6] Checking virtual environment..."
if [ -d ".venv" ]; then
    echo "Activating virtual environment..."
    source .venv/bin/activate
else
    echo "Virtual environment not found. Creating one..."
    python3 -m venv .venv
    source .venv/bin/activate
fi

# Step 4: Update Python dependencies
echo ""
echo "[4/6] Updating Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Step 5: Restore database if it was accidentally overwritten
echo ""
echo "[5/6] Verifying database..."
if [ -f "$DB_BACKUP" ] && [ -f "$DB_FILE" ]; then
    # Check if database was modified during git pull (shouldn't happen, but safety check)
    DB_MODIFIED=$(git diff --name-only HEAD HEAD~1 | grep -q "$DB_FILE" && echo "yes" || echo "no")
    
    if [ "$DB_MODIFIED" = "yes" ]; then
        echo "WARNING: Database file was modified in git. Restoring from backup..."
        mv "$DB_FILE" "$DB_FILE.git-modified"
        cp "$DB_BACKUP" "$DB_FILE"
        echo "Database restored from backup."
    else
        echo "Database is safe (not modified by git)."
    fi
fi

# Step 6: Restart service if running as systemd service
echo ""
echo "[6/6] Checking service status..."
if systemctl is-active --quiet rfq-tracker 2>/dev/null; then
    echo "Restarting rfq-tracker service..."
    sudo systemctl restart rfq-tracker
    sleep 2
    if systemctl is-active --quiet rfq-tracker; then
        echo "Service restarted successfully."
    else
        echo "WARNING: Service failed to start. Check logs with: sudo journalctl -u rfq-tracker -n 50"
    fi
elif [ -f "app.py" ]; then
    echo "Service not running as systemd. If running manually, restart it with:"
    echo "  source .venv/bin/activate"
    echo "  python app.py"
else
    echo "Service check skipped."
fi

echo ""
echo "================================================"
echo "  Update Complete!"
echo "================================================"
echo ""
echo "Changes pulled from git successfully."
if [ -f "$DB_BACKUP" ]; then
    echo "Database backup saved as: $DB_BACKUP"
    echo "You can remove old backups if everything works correctly."
fi
echo ""
echo "The application should now be running with the latest code."
echo "Your existing database has been preserved."
echo ""
echo "================================================"
