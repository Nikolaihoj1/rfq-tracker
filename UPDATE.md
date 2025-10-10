# Quick Update Guide - Existing Server

If you already have RFQ Tracker running on a server, use this guide to pull the latest changes.

---

## Simple Update (For Running Servers)

```bash
# Navigate to your RFQ tracker directory
cd ~/rfq-tracker  # or wherever you installed it

# Make sure you're on main branch
git checkout main

# Pull latest changes
git pull origin main

# Activate virtual environment (if using one)
source .venv/bin/activate

# Update dependencies (if requirements.txt changed)
pip install -r requirements.txt

# Restart the application
sudo systemctl restart rfq-tracker
```

That's it! Your server is now updated.

---

## Step-by-Step Update

### 1. SSH into your server
```bash
ssh user@your-server-ip
```

### 2. Navigate to the application directory
```bash
cd ~/rfq-tracker
# or: cd /path/to/your/rfq-tracker
```

### 3. Check current status
```bash
git status
git branch
```

### 4. Ensure you're on the main branch
```bash
git checkout main
```

### 5. Pull the latest changes
```bash
git pull origin main
```

### 6. If you're using a virtual environment
```bash
source .venv/bin/activate
pip install --upgrade -r requirements.txt
```

### 7. Restart the service

**If running with systemd:**
```bash
sudo systemctl restart rfq-tracker
sudo systemctl status rfq-tracker
```

**If running manually with Python:**
```bash
# Stop the current process (Ctrl+C in the terminal where it's running)
# Then start it again:
python app.py
```

**If running with Gunicorn manually:**
```bash
# Find and kill the process
pkill gunicorn
# Start it again
gunicorn -w 4 -b 0.0.0.0:5000 'app:create_app()'
```

---

## Verify the Update

1. Check service status:
```bash
sudo systemctl status rfq-tracker
```

2. Check application logs:
```bash
sudo journalctl -u rfq-tracker -n 50 -f
```

3. Visit your application in browser:
```
http://your-server-ip
http://your-server-ip/admin
```

---

## Troubleshooting

### If git pull fails with local changes:

```bash
# See what changed
git status

# Option 1: Stash your changes
git stash
git pull origin main
git stash pop

# Option 2: Discard local changes (careful!)
git reset --hard origin/main
```

### If the service won't restart:

```bash
# Check logs
sudo journalctl -u rfq-tracker -n 100

# Check if port is in use
sudo netstat -tlnp | grep 5000

# Kill any hanging process
sudo pkill -f gunicorn
sudo systemctl restart rfq-tracker
```

### If you need to reinstall dependencies:

```bash
cd ~/rfq-tracker
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt --force-reinstall
sudo systemctl restart rfq-tracker
```

---

## What Gets Updated?

When you run `git pull`, these files will be updated:
- ✅ `app.py` - Backend logic
- ✅ `templates/` - HTML templates
- ✅ `static/` - CSS and JavaScript files
- ✅ `requirements.txt` - Python dependencies

**What stays the same:**
- ❌ `rfq.db` - Your database (preserved)
- ❌ `.venv/` - Virtual environment (unless you reinstall)
- ❌ Systemd service configuration

---

## Rollback (If Update Breaks Something)

```bash
# View recent commits
git log --oneline -5

# Rollback to previous commit
git checkout <previous-commit-hash>

# Or go back one commit
git reset --hard HEAD~1

# Restart service
sudo systemctl restart rfq-tracker
```

To return to latest:
```bash
git checkout main
git pull origin main
sudo systemctl restart rfq-tracker
```

