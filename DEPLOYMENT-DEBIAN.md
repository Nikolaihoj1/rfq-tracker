# Debian Server Deployment Guide

This branch (`debian-deployment`) contains a complete deployment package including the SQLite database file (`rfq.db`) for easy setup on a Debian server.

## Quick Start

1. **Clone or download this branch:**
   ```bash
   git clone -b debian-deployment https://github.com/Nikolaihoj1/rfq-tracker.git
   cd rfq-tracker
   ```

2. **Install Python and dependencies:**
   ```bash
   sudo apt update
   sudo apt install python3 python3-venv python3-pip
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Run the application:**
   ```bash
   python app.py
   ```

   The application will be available at `http://localhost:5000`

## Database

The `rfq.db` file is included in this branch and contains the current database state. On first run, the application will use this existing database.

**Note:** Make sure to set proper file permissions:
```bash
chmod 644 rfq.db
```

## Production Deployment

For production, consider:

1. **Using Gunicorn:**
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 'app:create_app()'
   ```

2. **Setting up as a systemd service** (see `setup-service.sh`)

3. **Using a reverse proxy** (nginx/apache) in front of the application

## Files Included

- All application code
- Database file (`rfq.db`)
- Requirements file (`requirements.txt`)
- Deployment scripts (`setup-service.sh`, `install.sh`)

## Important Notes

- This branch includes the database file which is normally excluded in `.gitignore`
- The database contains your current RFQ data
- Make sure to backup the database before deploying
- For security, ensure proper file permissions are set on the server
