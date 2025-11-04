# RFQ Tracker - Future Features & Roadmap

This document outlines planned features and improvements for the RFQ Tracker application.

---

## 🎯 High Priority Features

### 1. Search & Filter Functionality
- **Description:** Add search bar to filter RFQs by client name, RFQ number, contact, or any field
- **Use Case:** Quickly find specific RFQs in large datasets
- **Implementation:**
  - Client-side filtering on loaded data
  - Backend search endpoint with SQL LIKE queries
  - Highlight matching terms in results

### 2. Export to CSV/Excel
- **Description:** Export RFQ list to CSV or Excel format
- **Use Case:** Share data with external parties, create reports
- **Implementation:**
  - Add export button to admin page
  - Generate CSV using Python's `csv` module
  - Optional: Excel export using `openpyxl` or `pandas`

### 3. Due Date Reminders & Alerts
- **Description:** Visual indicators and alerts for RFQs approaching or past due dates
- **Use Case:** Stay on top of deadlines
- **Implementation:**
  - Color-coded badges (red for overdue, yellow for due soon)
  - Alert banner for overdue items
  - Configurable reminder threshold (e.g., 3 days before due date)

### 4. Advanced Filtering
- **Description:** Multiple filter options (date range, status, client, contact)
- **Use Case:** Narrow down RFQs by specific criteria
- **Implementation:**
  - Filter panel with multiple dropdowns/date pickers
  - Combine filters (AND/OR logic)
  - Save filter presets

---

## 📊 Medium Priority Features

### 5. Bulk Operations
- **Description:** Select multiple RFQs and perform bulk actions
- **Use Case:** Update status of multiple RFQs at once, bulk delete
- **Implementation:**
  - Checkbox selection in admin table
  - Bulk status update dropdown
  - Bulk delete with confirmation

### 6. Notes/Comments System
- **Description:** Add notes or comments to individual RFQs
- **Use Case:** Track internal discussions, add reminders
- **Implementation:**
  - Add `notes` TEXT field to database
  - Textarea in admin form
  - Display notes in RFQ detail view
  - Optional: Timestamp comments, edit history

### 7. Dashboard & Analytics
- **Description:** Visual dashboard with charts and statistics
- **Use Case:** Track RFQ metrics, identify trends
- **Implementation:**
  - Status distribution chart (pie/bar chart)
  - RFQs by month/week timeline
  - Average response time
  - Success rate (Send/Followed up vs total)
  - Use Chart.js or similar lightweight library

### 8. Print-Friendly View
- **Description:** Optimized print layout for RFQ list
- **Use Case:** Print RFQ lists for meetings or records
- **Implementation:**
  - Print CSS stylesheet
  - Hide unnecessary UI elements
  - Table layout optimized for printing

### 9. Activity Log / Audit Trail
- **Description:** Track all changes made to RFQs (who, when, what changed)
- **Use Case:** Compliance, debugging, accountability
- **Implementation:**
  - New `activity_log` table
  - Log CREATE, UPDATE, DELETE operations
  - Display in admin panel or separate audit page

---

## 💡 Nice to Have Features

### 10. Email Integration
- **Description:** Send RFQ information via email directly from the app
- **Use Case:** Quick communication with clients
- **Implementation:**
  - SMTP configuration
  - Email templates
  - Send RFQ summary to client contact
  - Optional: Email notifications on status changes

### 11. File Attachments
- **Description:** Attach files (PDFs, documents) to RFQs
- **Use Case:** Store related documents with RFQs
- **Implementation:**
  - File upload functionality
  - Store files in `static/uploads/` directory
  - Display attachment links in RFQ view
  - Database table for file metadata

### 12. RFQ Templates
- **Description:** Create reusable templates for common RFQ types
- **Use Case:** Faster RFQ creation for recurring clients
- **Implementation:**
  - Template management page
  - Save templates with pre-filled fields
  - Apply template when creating new RFQ

### 13. User Authentication & Authorization
- **Description:** Multi-user support with login and role-based permissions
- **Use Case:** Team collaboration, access control
- **Implementation:**
  - User login system (Flask-Login or Flask-Security)
  - User roles (Admin, Viewer, Editor)
  - Session management
  - Optional: Password reset functionality

### 14. Mobile Responsive Improvements
- **Description:** Enhanced mobile experience
- **Use Case:** Access RFQ tracker on mobile devices
- **Implementation:**
  - Optimize tile layout for small screens
  - Mobile-friendly admin form
  - Touch-friendly buttons and interactions

### 15. Dark/Light Theme Toggle
- **Description:** Allow users to switch between dark and light themes
- **Use Case:** User preference, reduce eye strain
- **Implementation:**
  - Theme toggle button
  - CSS variables for easy theme switching
  - Save preference in localStorage

---

## 🔧 Technical Improvements

### Database Enhancements
- [ ] Add indexes on frequently queried fields (client_name, rfq_date, due_date, status)
- [ ] Database migration system for schema changes
- [ ] Backup/restore functionality

### Performance Optimizations
- [ ] Pagination for large RFQ lists (server-side)
- [ ] Lazy loading for tiles
- [ ] Caching of frequently accessed data

### Code Quality
- [ ] Add unit tests (pytest)
- [ ] Add integration tests for API endpoints
- [ ] Code documentation (docstrings)
- [ ] Type hints throughout codebase

### Security Enhancements
- [ ] Input validation and sanitization
- [ ] Rate limiting for API endpoints
- [ ] CSRF protection
- [ ] SQL injection prevention (already using parameterized queries, but review)

---

## 📝 Implementation Notes

### Priority Guidelines
- **High Priority:** Features that directly improve daily workflow efficiency
- **Medium Priority:** Features that add value but aren't critical
- **Nice to Have:** Features that would be nice but can wait

### When Adding Features
1. Update this document when starting work on a feature
2. Update `README.md` with new features
3. Follow existing code patterns and architecture
4. Test thoroughly before committing
5. Update API documentation if adding new endpoints

### Current Tech Stack
- **Backend:** Flask (Python)
- **Database:** SQLite
- **Frontend:** Vanilla JavaScript, HTML, CSS
- **Deployment:** Gunicorn + Nginx

---

## 🚀 Quick Wins (Easy to Implement)

These features could be implemented quickly:
1. ✅ Dark/Light theme toggle (CSS variables already in place)
2. ✅ Print-friendly view (CSS print media queries)
3. ✅ Client-side search/filter (no backend changes needed)
4. ✅ Export to CSV (Python built-in `csv` module)
5. ✅ Due date reminders (date comparison logic)

---

## 📅 Future Considerations

- Migration to PostgreSQL for better scalability
- REST API versioning
- Docker containerization
- CI/CD pipeline
- Automated testing in deployment

---

**Last Updated:** 2025-01-27

**Note:** This is a living document. Features will be added, removed, or reprioritized as the project evolves.

