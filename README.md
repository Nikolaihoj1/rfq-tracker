# Machine Shop RFQ Tracker

Single Page Application to track RFQs with a Flask backend and SQLite database.

**GitHub Repository:** [https://github.com/nikolaihoj1/rfq-tracker](https://github.com/nikolaihoj1/rfq-tracker)

---

## Table of Contents

- [Installation](#installation)
- [Updating from Git](#updating-from-git)
- [Quickstart (Development)](#quickstart-development)
- [Running as a Service](#running-as-a-service)
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
git checkout main
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

### Automated Update (Recommended)

Use the update script to safely update without touching your database:

```bash
cd /path/to/rfq-tracker
chmod +x update.sh  # First time only
./update.sh
```

The script will backup your database, pull changes, update dependencies, and restart the service.

### Manual Update

To pull the latest changes manually:

```bash
cd /path/to/rfq-tracker
git checkout main
git pull origin main
```

After pulling updates, restart the application:

```bash
# Stop the running app (Ctrl+C if running in foreground)
python app.py
```

If new dependencies were added, update them:

```bash
source .venv/bin/activate  # If using virtual environment
pip install -r requirements.txt
```

**Note:** Your database (`rfq.db`) is protected by `.gitignore` and will never be overwritten during updates.

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
- **Full CRUD operations:** Add, edit, and delete RFQ entries
- **Refresh button:** Manually refresh the RFQ list at any time
- **Limit selector:** Choose how many RFQs to display (10, 20, 50, 100, or All)
- **Default sort:** RFQs sorted by RFQ ID (descending, newest first)
- Fields:
  - Client name
  - RFQ date
  - Due date
  - Client contact
  - Client email
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
- 🔧 Admin panel for full CRUD operations (Create, Read, Update, Delete)
- 🔄 Auto-refresh every 2 minutes (homepage)
- 📊 Limit selector in admin page (10, 20, 50, 100, All)
- 🔃 Manual refresh button in admin page

---

## API Documentation

### Get all RFQs

```http
GET /api/rfqs?sort_by=rfq_id|rfq_date|client_name|due_date&order=asc|desc&limit=10|20|50|100|all
```

**Query Parameters:**
- `sort_by` (optional): Field to sort by (default: `due_date` for homepage, `rfq_id` for admin)
- `order` (optional): Sort order `asc` or `desc` (default: `desc` for homepage, `desc` for admin)
- `limit` (optional): Number of results to return. Use `all` for no limit (default: `all`)

### Create new RFQ

```http
POST /api/rfqs
Content-Type: application/json

{
  "client_name": "ACME Corp",
  "rfq_date": "2025-10-10",
  "due_date": "2025-10-20",
  "client_contact": "John Doe",
  "client_email": "john@acme.com",
  "our_contact": "Jane Smith",
  "network_folder_link": "\\\\server\\rfqs\\acme-001",
  "status": "Created",
  "rfq_number": "RFQ-001"
}
```

### Update RFQ (full update)

```http
PUT /api/rfqs/<rfq_id>
Content-Type: application/json

{
  "client_name": "ACME Corp",
  "rfq_date": "2025-10-10",
  "due_date": "2025-10-20",
  "client_contact": "John Doe",
  "client_email": "john@acme.com",
  "our_contact": "Jane Smith",
  "network_folder_link": "\\\\server\\rfqs\\acme-001",
  "status": "Draft",
  "rfq_number": "RFQ-001"
}
```

### Update RFQ status only

```http
PATCH /api/rfqs/<rfq_id>/status
Content-Type: application/json

{
  "status": "Draft"
}
```

### Delete RFQ

```http
DELETE /api/rfqs/<rfq_id>
```

### Available Statuses

- Received
- Created
- Draft
- Send
- Followed up

---

## Running as a Service

The application can be run as a system service for automatic startup and background operation.

### Windows Service

**Option 1: Using NSSM (Non-Sucking Service Manager)**

1. Download NSSM from https://nssm.cc/download
2. Extract and run `nssm install RFQTracker` from an Administrator command prompt
3. Configure the service:
   - **Path:** `C:\Python\python.exe` (or path to your Python executable)
   - **Startup directory:** `C:\path\to\rfq-tracker`
   - **Arguments:** `app.py`
   - **Service name:** `RFQTracker`
4. Start the service:
   ```powershell
   nssm start RFQTracker
   ```

**Option 2: Using Task Scheduler**

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger: "When the computer starts"
4. Set action: "Start a program"
   - Program: `python`
   - Arguments: `app.py`
   - Start in: `C:\path\to\rfq-tracker`
5. Check "Run whether user is logged on or not"

### Linux Service (systemd)

**Option 1: Using the automated setup script**

1. Make the script executable:
   ```bash
   chmod +x setup-service.sh
   ```

2. Run the setup script (requires sudo):
   ```bash
   sudo ./setup-service.sh
   ```

The script will:
- Create the systemd service file
- Set proper permissions
- Enable and start the service

**Option 2: Manual setup**

1. Create a systemd service file `/etc/systemd/system/rfq-tracker.service`:

```ini
[Unit]
Description=RFQ Tracker
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/rfq-tracker
Environment="PATH=/path/to/rfq-tracker/.venv/bin"
ExecStart=/path/to/rfq-tracker/.venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

2. Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rfq-tracker
sudo systemctl start rfq-tracker
```

3. Check service status:

```bash
sudo systemctl status rfq-tracker
```

**Note:** The setup script uses Gunicorn for better performance. For manual setup with Gunicorn:

```bash
pip install gunicorn
```

Then update the `ExecStart` line in the service file:

```ini
ExecStart=/path/to/rfq-tracker/.venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 'app:create_app()'
```

---

## Configuration

### Start on a different port

```bash
python -c "import app; app.create_app().run(host='0.0.0.0', port=5050, debug=True)"
```

**Note:** The application runs on `0.0.0.0` by default which allows access from other devices on your local network. Access it using the server's IP address (e.g., `http://192.168.1.100:5000`) from other devices on the same network. For localhost-only access, change `host='0.0.0.0'` to `host='127.0.0.1'` in `app.py`.

### Autostart (Windows) - Simple Method

For quick autostart without a full service:
- Create a shortcut to `python app.py`
- Place it in `shell:startup` folder
- Or use Task Scheduler to run at logon

**Note:** For proper service operation, use the [Running as a Service](#running-as-a-service) section above.

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
