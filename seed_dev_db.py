#!/usr/bin/env python3
"""
Opret en placeholder-database til lokal udvikling med eksempeldata.
Kør: python seed_dev_db.py

Eksisterende rfq.db bliver backet op først.
Kræver ikke Flask – bruger kun standardbiblioteket sqlite3.
"""

from __future__ import annotations

import os
import shutil
import sqlite3
from datetime import datetime, timedelta

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(SCRIPT_DIR, "rfq.db")
BACKUP_PATH = os.path.join(SCRIPT_DIR, f"rfq.db.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}")


def main() -> None:
    if os.path.exists(DB_PATH):
        print(f"Backer up eksisterende database til {BACKUP_PATH}")
        shutil.copy2(DB_PATH, BACKUP_PATH)
        os.remove(DB_PATH)
        print("Eksisterende rfq.db fjernet.")
    else:
        print("Ingen eksisterende rfq.db fundet.")

    today = datetime.today().date()
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        conn.execute(
            """
            CREATE TABLE rfq (
                rfq_id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_name TEXT NOT NULL,
                rfq_date TEXT NOT NULL,
                due_date TEXT NOT NULL,
                client_contact TEXT NOT NULL,
                our_contact TEXT NOT NULL,
                network_folder_link TEXT NOT NULL,
                status TEXT NOT NULL CHECK (status IN ('Received','Created','Draft','Send','Followed up')),
                rfq_number TEXT,
                client_email TEXT,
                completed_date TEXT,
                comments TEXT
            )
            """
        )
        conn.commit()

        sample_rows = [
            (
                "Acme Industries",
                (today - timedelta(days=3)).isoformat(),
                (today + timedelta(days=7)).isoformat(),
                "Jane Doe",
                "Alex Turner",
                "https://example.com/acme-rfq-1001",
                "Created",
                "Tilbud 26.001",
                "jane.doe@acme.com",
                "Venter på tilbud fra underleverandør.",
            ),
            (
                "Beta Manufacturing",
                (today - timedelta(days=1)).isoformat(),
                (today + timedelta(days=10)).isoformat(),
                "",
                "Morgan Yu",
                "https://example.com/beta-rfq-1002",
                "Draft",
                "Tilbud 26.002",
                "",
                "",
            ),
            (
                "Cobalt Works",
                today.isoformat(),
                (today + timedelta(days=14)).isoformat(),
                "Rita Hansen",
                "Jordan Blake",
                "https://example.com/cobalt-rfq-1003",
                "Send",
                "Tilbud 26.003",
                "rita@cobalt-works.io",
                "Sendt tilbud – opfølgning om 1 uge.",
            ),
            (
                "Delta Precision",
                (today - timedelta(days=10)).isoformat(),
                (today + timedelta(days=3)).isoformat(),
                "Ole Jensen",
                "Harper Quinn",
                "https://example.com/delta-rfq-1004",
                "Followed up",
                "Tilbud 26.004",
                "ops@delta-precision.net",
                "",
            ),
            (
                "Epsilon Metal",
                (today - timedelta(days=5)).isoformat(),
                (today + timedelta(days=5)).isoformat(),
                "Sofie Larsen",
                "Alex Turner",
                "file:///network/rfqs/epsilon-1005",
                "Draft",
                "Tilbud 26.005",
                "sofie@epsilon.dk",
                "Prioritet: høj. Kunden har hastende behov.",
            ),
        ]

        for row in sample_rows:
            conn.execute(
                """
                INSERT INTO rfq (
                    client_name, rfq_date, due_date, client_contact, our_contact,
                    network_folder_link, status, rfq_number, client_email, comments
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                row,
            )
        conn.commit()
        print(f"Indsat {len(sample_rows)} eksempel-RFQ'er.")
    finally:
        conn.close()

    print("")
    print("Placeholder-database oprettet: rfq.db")
    print("Start appen med: python app.py")
    print("Åbn http://127.0.0.1:5000 og http://127.0.0.1:5000/admin")
    print("")


if __name__ == "__main__":
    main()
