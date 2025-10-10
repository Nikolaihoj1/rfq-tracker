from __future__ import annotations

import os
import sqlite3
from datetime import datetime
from typing import Any, Dict, List, Tuple

from flask import Flask, jsonify, render_template, request


# -----------------------------------------------------------------------------
# Application factory and configuration
# -----------------------------------------------------------------------------

DATABASE_FILENAME = "rfq.db"
ALLOWED_SORT_FIELDS = {"client_name", "rfq_date", "due_date"}
ALLOWED_ORDER = {"asc", "desc"}
ALLOWED_STATUS = ["Received", "Created", "Draft", "Send", "Followed up"]


def create_app() -> Flask:
    app = Flask(__name__)
    app.config["DATABASE_PATH"] = os.path.join(os.path.dirname(__file__), DATABASE_FILENAME)

    ensure_database(app.config["DATABASE_PATH"]) 

    @app.route("/")
    def index() -> str:
        return render_template("index.html")

    @app.route("/admin")
    def admin() -> str:
        return render_template("admin.html")

    @app.get("/api/rfqs")
    def api_list_rfqs():
        sort_by = request.args.get("sort_by", "rfq_date")
        order = request.args.get("order", "asc")

        # Validate and normalize
        sort_by = sort_by if sort_by in ALLOWED_SORT_FIELDS else "rfq_date"
        order = order if order in ALLOWED_ORDER else "asc"

        try:
            rfqs = fetch_rfqs(app.config["DATABASE_PATH"], sort_by=sort_by, order=order)
            return jsonify({"items": rfqs})
        except Exception as exc:  # Basic error boundary for visibility during local dev
            return jsonify({"error": str(exc)}), 500

    @app.post("/api/rfqs")
    def api_create_rfq():
        try:
            payload = request.get_json(silent=True) or {}
            rfq_id = insert_rfq(app.config["DATABASE_PATH"], payload)
            return jsonify({"rfq_id": rfq_id}), 201
        except Exception as exc:
            return jsonify({"error": str(exc)}), 500

    @app.patch("/api/rfqs/<int:rfq_id>/status")
    def api_update_status(rfq_id: int):
        try:
            payload = request.get_json(silent=True) or {}
            new_status = payload.get("status")
            if new_status not in ALLOWED_STATUS:
                return (
                    jsonify({
                        "error": "Invalid status",
                        "allowed": ALLOWED_STATUS,
                    }),
                    400,
                )
            update_status(app.config["DATABASE_PATH"], rfq_id, new_status)
            return jsonify({"ok": True})
        except Exception as exc:
            return jsonify({"error": str(exc)}), 500

    return app


# -----------------------------------------------------------------------------
# Database helpers
# -----------------------------------------------------------------------------


def get_connection(db_path: str) -> sqlite3.Connection:
    connection = sqlite3.connect(db_path)
    connection.row_factory = sqlite3.Row
    return connection


def ensure_database(db_path: str) -> None:
    # Create tables if they do not exist; seed with sample data on first run
    with get_connection(db_path) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS rfq (
                rfq_id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_name TEXT NOT NULL,
                rfq_date TEXT NOT NULL,       -- YYYY-MM-DD
                due_date TEXT NOT NULL,       -- YYYY-MM-DD
                client_contact TEXT NOT NULL,
                our_contact TEXT NOT NULL,
                network_folder_link TEXT NOT NULL,
                status TEXT NOT NULL CHECK (status IN ('Received','Created','Draft','Send','Followed up')),
                rfq_number TEXT,
                client_email TEXT,
                completed_date TEXT           -- ISO timestamp when status changed to Send/Followed up
            )
            """
        )

        # Best-effort migration for existing DBs missing columns
        try:
            conn.execute("ALTER TABLE rfq ADD COLUMN rfq_number TEXT")
        except Exception:
            pass
        try:
            conn.execute("ALTER TABLE rfq ADD COLUMN client_email TEXT")
        except Exception:
            pass
        try:
            conn.execute("ALTER TABLE rfq ADD COLUMN completed_date TEXT")
        except Exception:
            pass

        # Seed if empty
        cur = conn.execute("SELECT COUNT(*) AS c FROM rfq")
        count = int(cur.fetchone()["c"])
        if count == 0:
            seed_rows = _sample_rows()
            conn.executemany(
                """
                INSERT INTO rfq (
                    client_name, rfq_date, due_date, client_contact, our_contact, network_folder_link, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                seed_rows,
            )


def fetch_rfqs(db_path: str, *, sort_by: str, order: str) -> List[Dict[str, Any]]:
    # Guard inputs: only allow whitelisted columns and order
    if sort_by not in ALLOWED_SORT_FIELDS:
        sort_by = "rfq_date"
    if order not in ALLOWED_ORDER:
        order = "asc"

    query = f"""
        SELECT rfq_id, client_name, rfq_date, due_date, client_contact, our_contact, network_folder_link, status, rfq_number, client_email, completed_date
        FROM rfq
        ORDER BY {sort_by} {order.upper()}
    """

    with get_connection(db_path) as conn:
        rows = conn.execute(query).fetchall()
        return [dict(row) for row in rows]


def update_status(db_path: str, rfq_id: int, new_status: str) -> None:
    from datetime import datetime
    with get_connection(db_path) as conn:
        # If status is Send or Followed up, set completed_date to now
        if new_status in ('Send', 'Followed up'):
            completed_date = datetime.utcnow().isoformat()
            cur = conn.execute(
                "UPDATE rfq SET status = ?, completed_date = ? WHERE rfq_id = ?",
                (new_status, completed_date, rfq_id)
            )
        else:
            # Clear completed_date if status is changed to something else
            cur = conn.execute(
                "UPDATE rfq SET status = ?, completed_date = NULL WHERE rfq_id = ?",
                (new_status, rfq_id)
            )
        if cur.rowcount == 0:
            raise ValueError(f"RFQ {rfq_id} not found")


def insert_rfq(db_path: str, payload: Dict[str, Any]) -> int:
    with get_connection(db_path) as conn:
        cur = conn.execute(
            """
            INSERT INTO rfq (
                client_name, rfq_date, due_date, client_contact, our_contact, network_folder_link, status, rfq_number, client_email
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                payload["client_name"],
                payload["rfq_date"],
                payload["due_date"],
                payload["client_contact"],
                payload["our_contact"],
                payload["network_folder_link"],
                payload["status"],
                payload.get("rfq_number", ""),
                payload.get("client_email", ""),
            ),
        )
        return cur.lastrowid


def _sample_rows() -> List[Tuple[str, str, str, str, str, str, str]]:
    today = datetime.today().date()
    sample: List[Tuple[str, str, str, str, str, str, str]] = [
        (
            "Acme Industries",
            today.replace(day=max(1, today.day - 3)).isoformat(),
            today.replace(day=min(28, today.day + 7)).isoformat(),
            "jane.doe@acme.com",
            "Alex Turner",
            "https://example.com/acme-rfq-1001",
            "Created",
        ),
        (
            "Beta Manufacturing",
            today.replace(day=max(1, today.day - 1)).isoformat(),
            today.replace(day=min(28, today.day + 10)).isoformat(),
            "sam.lee@beta.com",
            "Morgan Yu",
            "https://example.com/beta-rfq-1002",
            "Draft",
        ),
        (
            "Cobalt Works",
            today.isoformat(),
            today.replace(day=min(28, today.day + 14)).isoformat(),
            "rita@cobalt-works.io",
            "Jordan Blake",
            "https://example.com/cobalt-rfq-1003",
            "Send",
        ),
        (
            "Delta Precision",
            today.replace(day=max(1, today.day - 10)).isoformat(),
            today.replace(day=min(28, today.day + 3)).isoformat(),
            "ops@delta-precision.net",
            "Harper Quinn",
            "https://example.com/delta-rfq-1004",
            "Followed up",
        ),
    ]
    return sample


if __name__ == "__main__":
    flask_app = create_app()
    # For local dev use only; host=0.0.0.0 allows access from LAN if desired
    flask_app.run(host="0.0.0.0", port=5000, debug=True)


