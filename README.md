# Machine Shop RFQ Tracker

Single Page Application to track RFQs with a Flask backend and SQLite database.

**GitHub Repository:** [https://github.com/nikolaihoj1/rfq-tracker](https://github.com/nikolaihoj1/rfq-tracker)

---

## Table of Contents

- [Installation](#installation)
- [Updating from Git](#updating-from-git)
- [Production Deployment](#production-deployment)
- [Quickstart (Development)](#quickstart-development)
- [Admin Usage](#admin-usage)
- [Homepage Usage](#homepage-usage)
- [Features](#features)
- [API Documentation](#api-documentation)
- [Configuration](#configuration)

---

## Installation

### First-time setup

Clone the repository:

```bash
git clone https://github.com/nikolaihoj1/rfq-tracker.git
cd rfq-tracker
```

Create a virtual environment:

**Linux/Mac:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

**Windows (PowerShell):**
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the application:

```bash
python app.py
```

Open `http://127.0.0.1:5000` in your browser.

The database `rfq.db` will be created automatically with sample data on first run.

---

## Updating from Git

To pull the latest changes from the repository:

```bash
cd /path/to/rfq-tracker
git pull origin main
```

After pulling updates, restart the application:

```bash
# Stop the running app (Ctrl+C if running in foreground)
python app.py
```

If new dependencies were added, update them:

```bash
pip install -r requirements.txt
```

---

## Production Deployment

### Quick Install (Automated - Fresh Server)

For a fresh Ubuntu/Debian server, use the automated installation script:

**Step 1: Install git first**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y git

# CentOS/RHEL
sudo yum install -y git
```

**Step 2: Run the automated installer**
```bash
git clone https://github.com/Nikolaihoj1/rfq-tracker.git
cd rfq-tracker
chmod +x install.sh
./install.sh
```

This script will:
- ✅ Update system packages
- ✅ Install Python, pip, git, nginx, sqlite
- ✅ Set up virtual environment
- ✅ Install dependencies
- ✅ Configure systemd service
- ✅ Configure nginx reverse proxy
- ✅ Configure firewall
- ✅ Start the application

📖 **For detailed step-by-step instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)**

### Option 1: Using Gunicorn (Manual Setup)

Install Gunicorn:

```bash
pip install gunicorn
```

Run the application:

```bash
gunicorn -w 4 -b 0.0.0.0:5000 'app:create_app()'
```

### Option 2: Nginx + Gunicorn

1. Create a systemd service file `/etc/systemd/system/rfq-tracker.service`:

```ini
[Unit]
Description=RFQ Tracker
After=network.target

[Service]
User=your-username
WorkingDirectory=/path/to/rfq-tracker
Environment="PATH=/path/to/rfq-tracker/.venv/bin"
ExecStart=/path/to/rfq-tracker/.venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 'app:create_app()'
Restart=always

[Install]
WantedBy=multi-user.target
```

2. Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rfq-tracker
sudo systemctl start rfq-tracker
```

3. Configure Nginx as reverse proxy (`/etc/nginx/sites-available/rfq-tracker`):

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/rfq-tracker /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Option 3: Docker (Coming Soon)

Docker support will be added in a future update.

---

## Quickstart (Development)

### Windows

1. **Create a virtual environment**

```powershell
cd C:\Users\<you>\kode\rfq-tracker
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. **Install dependencies**

```powershell
pip install -r requirements.txt
```

3. **Run the app**

```powershell
python app.py
```

Open `http://127.0.0.1:5000` in your browser.

### Common PowerShell tips

- PowerShell does not support `&&` like Bash. Run commands on separate lines or use `;`: `cmd1; cmd2`.
- If `Activate.ps1` is blocked, run as Administrator: 
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

---

## Admin Usage

- Navigate to `/admin` to manage RFQs
- Add, edit, and delete RFQ entries
- Fields:
  - Client name
  - RFQ date
  - Due date
  - Client contact
  - Our contact
  - Network folder link
  - Status
  - RFQ number

---

## Homepage Usage

- **Default sort:** Due date (descending)
- **Auto-refresh:** Every 2 minutes
- **"Show follow-up (Send)" checkbox:**
  - Off (default): hides "Send" and "Followed up" statuses
  - On: shows only "Send" status

---

## Features

- ✨ Responsive tiled RFQ grid layout
- 🔄 Sort by `rfq_date`, `client_name`, or `due_date`
- 🎨 Color-coded status badges
  - 🔴 Red: Created (and earlier statuses)
  - 🟡 Yellow: Draft
  - 🟢 Green: Send, Followed up, Received
- ⚡ Inline status updates (PATCH request)
- 🔧 Admin panel for full CRUD operations
- 🔄 Auto-refresh every 2 minutes

---

## API Documentation

### Get all RFQs

```http
GET /api/rfqs?sort_by=rfq_date|client_name|due_date&order=asc|desc
```

**Query Parameters:**
- `sort_by` (optional): Field to sort by (default: `due_date`)
- `order` (optional): Sort order `asc` or `desc` (default: `desc`)

### Create new RFQ

```http
POST /api/rfqs
Content-Type: application/json

{
  "client_name": "ACME Corp",
  "rfq_date": "2025-10-10",
  "due_date": "2025-10-20",
  "client_contact": "John Doe",
  "our_contact": "Jane Smith",
  "network_folder_link": "\\\\server\\rfqs\\acme-001",
  "status": "Created"
}
```

### Update RFQ status

```http
PATCH /api/rfqs/<rfq_id>/status
Content-Type: application/json

{
  "status": "Draft"
}
```

### Available Statuses

- Created
- Draft
- Send
- Followed up
- Received

---

## Configuration

### Start on a different port

```bash
python -c "import app; app.create_app().run(host='0.0.0.0', port=5050, debug=True)"
```

### Running behind a reverse proxy

- Keep SPA and API on the same origin if possible
- If your proxy blocks PUT/DELETE/PATCH, use POST-only endpoints or allow those methods
- For different origins, enable CORS (see below)

### Enable CORS (if needed)

```bash
pip install Flask-Cors
```

Add to `app.py`:

```python
from flask_cors import CORS
app = create_app()
CORS(app, resources={r"/api/*": {"origins": "*"}})  # or restrict to your domain
```

### Autostart (Windows)

- Create a shortcut to `python app.py`
- Place it in `shell:startup` folder
- Or use Task Scheduler to run at logon

---

## Database Management

Data is stored in SQLite (`rfq.db`). To inspect the database:

```bash
python -c "import sqlite3; import json; conn=sqlite3.connect('rfq.db'); conn.row_factory=sqlite3.Row; print(json.dumps([dict(r) for r in conn.execute('select * from rfq').fetchall()], indent=2))"
```

### Example SQL Query

```sql
SELECT rfq_id, client_name, rfq_date, due_date, client_contact, 
       our_contact, network_folder_link, status
FROM rfq
ORDER BY due_date DESC;
```

The application whitelists sort fields to prevent SQL injection.

---

## Project Structure

```
rfq-tracker/
├── app.py                  # Flask application and SQLite helpers
├── requirements.txt        # Python dependencies
├── rfq.db                 # SQLite database (auto-created)
├── templates/
│   ├── index.html         # Main RFQ viewer page
│   └── admin.html         # Admin management page
└── static/
    ├── styles.css         # Application styles
    ├── app.js            # Main page JavaScript
    └── admin.js          # Admin page JavaScript
```

---

## Support

For issues or feature requests, please visit the [GitHub repository](https://github.com/nikolaihoj1/rfq-tracker/issues).

---

## License

This project is provided as-is for internal use.
