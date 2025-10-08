# Machine Shop RFQ Tracker

Single Page Application to track RFQs with a Flask backend and SQLite database.

## Quickstart

1. Create a virtual environment (recommended)

```bash
python -m venv .venv
. .venv/Scripts/activate  # PowerShell: .venv\\Scripts\\Activate.ps1
```

2. Install dependencies

```bash
pip install -r requirements.txt
```

3. Run the app

```bash
python app.py
```

Open `http://localhost:5000` in your browser.

The database `rfq.db` will be created automatically with a few sample rows on first run.

## Features

- Tiled RFQ grid with responsive layout
- Sort by `rfq_date` (default), `client_name`, or `due_date`
- Color-coded status badges
  - Red: Created (and before Draft)
  - Yellow: Draft
  - Green: Send, Followed up, Received
- Inline status update per RFQ (PATCH request)
- `/admin` placeholder page for future maintenance

## API

- `GET /api/rfqs?sort_by=rfq_date|client_name|due_date&order=asc|desc`
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
