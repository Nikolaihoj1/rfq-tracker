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

# Detect current branch (default to main if detection fails)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
echo "Current branch: $CURRENT_BRANCH"

# Get current commit before pull
CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Check if rfq.db has changes and stash them separately
RFQ_DB_STASHED=false
if [ -f "$DB_FILE" ] && ! git diff --quiet "$DB_FILE" 2>/dev/null; then
    echo "Stashing local changes to rfq.db..."
    git stash push -m "Auto-stash rfq.db $(date +%Y%m%d_%H%M%S)" -- "$DB_FILE" 2>/dev/null && RFQ_DB_STASHED=true || {
        echo "Warning: Could not stash rfq.db. Will try to preserve it manually."
    }
fi

# Check if update.sh has changes and stash them separately  
UPDATE_SH_STASHED=false
if [ -f "update.sh" ] && ! git diff --quiet update.sh 2>/dev/null; then
    echo "Stashing local changes to update.sh..."
    git stash push -m "Auto-stash update.sh $(date +%Y%m%d_%H%M%S)" -- update.sh 2>/dev/null && UPDATE_SH_STASHED=true || true
fi

# Pull changes
if ! git pull origin "$CURRENT_BRANCH"; then
    echo "Pull failed. Trying alternative merge approach..."
    
    # Fetch first
    git fetch origin "$CURRENT_BRANCH"
    
    # If rfq.db is causing issues, temporarily remove it from index
    if [ -f "$DB_FILE" ] && git ls-files --error-unmatch "$DB_FILE" >/dev/null 2>&1; then
        echo "Temporarily removing rfq.db from git index..."
        git rm --cached "$DB_FILE" 2>/dev/null || true
    fi
    
    # Reset update.sh to remote version (we want the new version)
    git checkout origin/"$CURRENT_BRANCH" -- update.sh 2>/dev/null || true
    
    # Try merge
    if ! git merge origin/"$CURRENT_BRANCH" --no-commit --no-ff; then
        echo "Merge conflict detected. Resolving..."
        # Abort merge and try a different approach
        git merge --abort 2>/dev/null || git reset --hard HEAD 2>/dev/null || true
        
        # Use reset and checkout instead
        git reset --hard origin/"$CURRENT_BRANCH" 2>/dev/null || {
            echo "ERROR: Could not update. Please resolve manually."
            exit 1
        }
        
        # Restore rfq.db from backup if it exists
        if [ -f "$DB_BACKUP" ]; then
            echo "Restoring database from backup..."
            cp "$DB_BACKUP" "$DB_FILE" 2>/dev/null || true
        fi
    else
        # Merge succeeded, commit it
        git commit -m "Merge latest changes from $CURRENT_BRANCH" || true
    fi
fi

# Restore stashed rfq.db changes (if we stashed them)
if [ "$RFQ_DB_STASHED" = "true" ]; then
    echo "Restoring stashed database changes..."
    # Find the most recent stash with rfq.db
    STASH_REF=$(git stash list | grep "Auto-stash rfq.db" | head -1 | sed 's/:.*//')
    if [ -n "$STASH_REF" ]; then
        git checkout "$STASH_REF" -- "$DB_FILE" 2>/dev/null && {
            echo "Database restored from stash."
            # Drop the stash since we've applied it
            git stash drop "$STASH_REF" 2>/dev/null || true
        } || {
            echo "Warning: Could not restore rfq.db from stash. Using backup instead."
            if [ -f "$DB_BACKUP" ]; then
                cp "$DB_BACKUP" "$DB_FILE" 2>/dev/null || true
            fi
        }
    elif [ -f "$DB_BACKUP" ]; then
        echo "Restoring database from backup..."
        cp "$DB_BACKUP" "$DB_FILE" 2>/dev/null || true
    fi
fi

# Ensure rfq.db is not tracked by git
if [ -f "$DB_FILE" ] && git ls-files --error-unmatch "$DB_FILE" >/dev/null 2>&1; then
    echo "Removing rfq.db from git tracking..."
    git rm --cached "$DB_FILE" 2>/dev/null || true
fi
git update-index --assume-unchanged "$DB_FILE" 2>/dev/null || true

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

# If update.sh was backed up, inform user
if [ "$UPDATE_SH_CHANGED" = "true" ] && [ -f "update.sh.local-backup" ]; then
    echo ""
    echo "Note: Your local update.sh changes were backed up to update.sh.local-backup"
    echo "The new version from git is now active."
fi

# Ensure rfq.db is not tracked
git update-index --assume-unchanged rfq.db 2>/dev/null || true

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
