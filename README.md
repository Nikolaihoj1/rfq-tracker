# Machine Shop RFQ Tracker

Single Page Application to track RFQs with a Flask backend and SQLite database.

## Quickstart (Windows)

1. Create a virtual environment (recommended)

Open Windows PowerShell and run:

```powershell
cd C:\Users\<you>\kode\rfq
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Install dependencies

```powershell
pip install -r requirements.txt
```

3. Run the app

```powershell
python app.py
```

Open `http://127.0.0.1:5000` in your browser.

The database `rfq.db` will be created automatically with a few sample rows on first run.

### Common PowerShell tips

- PowerShell does not support `&&` like Bash. Run commands on separate lines or use `;` if you prefer: `cmd1; cmd2`.
- If `Activate.ps1` is blocked, run as Administrator: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` (then re-run activation).

### Running behind a domain / reverse proxy

- Keep SPA and API on the same origin and scheme if possible (e.g., both https).
- If your proxy blocks PUT/DELETE/PATCH, you can use the provided POST-only endpoints (optional) or allow those methods in the proxy.
- If serving from a different origin, enable CORS in Flask (see below) or configure the proxy to route `/api/*` to the Flask app.

### Optional: Enable CORS

```powershell
pip install Flask-Cors
```

```python
from flask_cors import CORS
app = create_app()
CORS(app, resources={r"/api/*": {"origins": "*"}})  # or restrict to your domain
```

### Start on a different port

```powershell
python -c "import app; app.create_app().run(host='0.0.0.0', port=5050, debug=True)"
```

### Autostart (optional)

- Create a shortcut to `python app.py` and place it in `shell:startup` or use Task Scheduler to run at logon.

## Admin usage

- Go to `/admin` to add, edit, and delete RFQs.
- Fields: Client, RFQ date, Due date, Client contact, Our contact, Network folder link, Status, RFQ #.
- The table lists all RFQs; use Edit/Delete buttons to modify.

## Homepage usage

- Default sort: Due date (descending). Auto-refresh every 2 minutes.
- “Show follow-up (Send)” checkbox:
  - Off (default): hides Send and Followed up.
  - On: shows only Send.

## Features

- Tiled RFQ grid with responsive layout
- Sort by `rfq_date`, `client_name`, or `due_date` (default view uses due date desc)
- Color-coded status badges
  - Red: Created (and before Draft)
  - Yellow: Draft
  - Green: Send, Followed up, Received
- Inline status update per RFQ (PATCH request)
- `/admin` management page to create, update, and delete RFQs

## API

- `GET /api/rfqs?sort_by=rfq_date|client_name|due_date&order=asc|desc`
- `POST /api/rfqs` with JSON body including required fields
- `PATCH /api/rfqs/<rfq_id>/status` with JSON body `{ "status": "Draft" }`

## Example SQL

Below is an example SQL query used to fetch RFQs with sorting. The application whitelists sort fields to prevent SQL injection.

```sql
SELECT rfq_id, client_name, rfq_date, due_date, client_contact, our_contact, network_folder_link, status
FROM rfq
ORDER BY rfq_date ASC;
```

To sort by a different field or order, the app substitutes the allowed column and order.

## Notes

- This app is intended to run locally without authentication.
- Data is stored in SQLite (`rfq.db`). To inspect:

```bash
python -c "import sqlite3; import json; conn=sqlite3.connect('rfq.db'); conn.row_factory=sqlite3.Row; print(json.dumps([dict(r) for r in conn.execute('select * from rfq').fetchall()], indent=2))"
```

## Project Structure

- `app.py` — Flask app and SQLite helpers
- `templates/` — HTML templates (`index.html`, `admin.html`)
- `static/` — `styles.css`, `app.js`
- `requirements.txt` — dependencies
