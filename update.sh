#!/bin/bash

# RFQ Tracker - Safe Update Script
# Updates the application code without touching the existing database
#
# Usage: ./update.sh

# Don't exit on error - we handle errors manually
set +e

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

# Remove rfq.db from git tracking if it was accidentally tracked
if git ls-files --error-unmatch rfq.db >/dev/null 2>&1; then
    echo "Removing rfq.db from git tracking (it should be ignored)..."
    git rm --cached rfq.db 2>/dev/null || true
fi

# Backup update.sh if it has local changes
if git diff --quiet update.sh 2>/dev/null; then
    UPDATE_SH_CHANGED=false
else
    echo "Backing up local update.sh changes..."
    cp update.sh update.sh.local-backup 2>/dev/null || true
    UPDATE_SH_CHANGED=true
fi

# Temporarily ignore local changes to rfq.db and update.sh to allow pull
if [ -f "$DB_FILE" ]; then
    echo "Temporarily ignoring local database changes for git operations..."
    git update-index --assume-unchanged rfq.db 2>/dev/null || true
fi

if [ -f "update.sh" ]; then
    echo "Temporarily ignoring local update.sh changes for git operations..."
    git update-index --assume-unchanged update.sh 2>/dev/null || true
fi

# Detect current branch (default to main if detection fails)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
echo "Current branch: $CURRENT_BRANCH"

# Get current commit before pull
CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Pull changes with error handling
if ! git pull origin "$CURRENT_BRANCH"; then
    echo "Pull failed. Resolving conflicts..."
    # Restore tracking first
    git update-index --no-assume-unchanged rfq.db 2>/dev/null || true
    git update-index --no-assume-unchanged update.sh 2>/dev/null || true
    
    # Discard local changes to update.sh (we'll use the new version)
    git checkout -- update.sh 2>/dev/null || true
    
    # Keep rfq.db local changes
    git checkout -- rfq.db 2>/dev/null || true
    
    # Re-ignore for retry
    git update-index --assume-unchanged rfq.db 2>/dev/null || true
    
    # Try pull again
    if ! git pull origin "$CURRENT_BRANCH"; then
        echo "ERROR: Git pull failed. Please check the error messages above."
        exit 1
    fi
fi

# Get new commit after pull
NEW_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Show what changed
if [ "$CURRENT_COMMIT" != "$NEW_COMMIT" ]; then
    echo ""
    echo "Updated from commit $CURRENT_COMMIT to $NEW_COMMIT"
    echo "Files changed:"
    git diff --name-only "$CURRENT_COMMIT" "$NEW_COMMIT" | head -20
else
    echo ""
    echo "Already up to date (no new commits)"
fi

# Restore tracking (if we set it)
if [ -f "$DB_FILE" ]; then
    git update-index --no-assume-unchanged rfq.db 2>/dev/null || true
fi
if [ -f "update.sh" ]; then
    git update-index --no-assume-unchanged update.sh 2>/dev/null || true
fi

# If update.sh was backed up, inform user
if [ "$UPDATE_SH_CHANGED" = "true" ] && [ -f "update.sh.local-backup" ]; then
    echo ""
    echo "Note: Your local update.sh changes were backed up to update.sh.local-backup"
    echo "The new version from git is now active."
fi

# If update.sh was backed up, inform user
if [ "$UPDATE_SH_CHANGED" = "true" ] && [ -f "update.sh.local-backup" ]; then
    echo ""
    echo "Note: Your local update.sh changes were backed up to update.sh.local-backup"
    echo "The new version from git is now active."
fi

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
    DB_MODIFIED=$(git diff --name-only HEAD HEAD~1 2>/dev/null | grep -q "$DB_FILE" && echo "yes" || echo "no")
    
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
    sleep 3
    if systemctl is-active --quiet rfq-tracker; then
        echo "✓ Service restarted successfully."
        echo ""
        echo "Service status:"
        sudo systemctl status rfq-tracker --no-pager -l | head -10
    else
        echo "✗ WARNING: Service failed to start!"
        echo "Check logs with: sudo journalctl -u rfq-tracker -n 50"
        exit 1
    fi
elif [ -f "app.py" ]; then
    echo "Service not running as systemd. If running manually, restart it with:"
    echo "  source .venv/bin/activate"
    echo "  python app.py"
    echo ""
    echo "⚠ WARNING: You need to manually restart the application for changes to take effect!"
else
    echo "Service check skipped."
fi

echo ""
echo "================================================"
echo "  Update Complete!"
echo "================================================"
echo ""
if [ "$CURRENT_COMMIT" != "$NEW_COMMIT" ]; then
    echo "✓ Changes pulled from git successfully."
    echo ""
    echo "⚠ IMPORTANT: Clear your browser cache or do a hard refresh (Ctrl+F5)"
    echo "   to see the updated styles and templates."
else
    echo "ℹ No new changes to pull (already up to date)."
fi
echo ""
if [ -f "$DB_BACKUP" ]; then
    echo "Database backup saved as: $DB_BACKUP"
    echo "You can remove old backups if everything works correctly."
fi
echo ""
echo "Your existing database has been preserved."
echo ""
echo "To verify the update worked, check:"
echo "  - Admin page should show new form sections with icons"
echo "  - RFQ number should copy link instead of opening it"
echo "  - Comments should appear on front page (max 1 line)"
echo ""
echo "================================================"
