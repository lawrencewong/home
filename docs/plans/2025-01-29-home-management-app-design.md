# Home Management App Design

A simple web app for tracking house projects, maintenance, and information for a two-person household.

## Overview

- **Framework**: Rails 8 with classic server-rendered views
- **Database**: SQLite (simple, easy backups)
- **Hosting**: Local network only
- **Users**: Two accounts (you and your wife), full access for both
- **Styling**: Minimal CSS framework (Pico CSS or similar), mobile-friendly

## Data Models

### User
- email, password_digest, name
- Rails 8 built-in authentication

### Task
- title (string, required)
- status (enum: todo, in_progress, done)
- assigned_to (references user, optional)
- created_by (references user)
- notes (text, optional)
- due_date (date, optional)
- archived_at (datetime, optional)

### WishlistItem
- title (string, required)
- item_type (enum: purchase, future_project)
- price (decimal, optional)
- priority (enum: low, medium, high)
- notes (text, optional)
- link (string, optional)
- created_by (references user)

### Reminder
- title (string, required)
- due_date (date, required)
- recurrence_rule (string, optional - e.g., "daily", "weekly", "monthly", "every_n_days:90")
- remindable (polymorphic, optional - links to appliance, task, etc.)
- completed_at (datetime, optional)
- created_by (references user)

### Appliance
- name (string, required)
- location (string, optional - e.g., "Basement", "Kitchen")
- brand (string, optional)
- model_number (string, optional)
- serial_number (string, optional)
- purchase_date (date, optional)
- warranty_expires (date, optional)
- manual_url (string, optional)
- notes (text, optional)

### WikiPage
- title (string, required)
- body (text, markdown)
- created_by (references user)
- updated_by (references user)

## Pages & Navigation

### Navigation Bar
- Links: Dashboard, Tasks, Wishlist, Reminders, Wiki, Appliances
- Search bar (searches across all content)
- User name + logout link

### Dashboard (Home)
- Tasks assigned to current user (in progress or overdue)
- Upcoming reminders (next 7 days) and overdue items
- Quick-add buttons for task, reminder, wishlist item

### Tasks
- List view grouped by status: Todo → In Progress → Done
- Filter by assignee (Me / Partner / All)
- Click to view/edit details
- Inline status toggle
- Done tasks auto-archive after 30 days

### Wishlist
- Two tabs: "Shopping List" and "Future Projects"
- Sort by priority or date added
- Shopping list shows running total of prices

### Reminders
- List sorted by due date
- Overdue items highlighted at top
- Mark complete button
- For recurring: completing creates next occurrence automatically

### Wiki
- List of all pages
- Click to view (rendered markdown)
- Edit button for editing
- Support `[[Page Title]]` syntax for linking between pages

### Appliances
- Card grid layout
- Shows: name, location, warranty status indicator
- Warranty status: green (>6 months), yellow (< 6 months), red (expired)
- Click for full details and linked reminders

## Key Behaviors

### Task Workflow
- New tasks default to "Todo" and unassigned
- Either user can assign/reassign tasks
- Status changes logged with timestamp

### Recurring Reminders
- Recurrence rules: daily, weekly, monthly, every_n_days:N
- On completion: mark current done, create next occurrence
- Linked to appliances when relevant (e.g., "Service HVAC" linked to HVAC appliance)

### Search
- Single search bar searches: tasks, wiki pages, appliances, wishlist items
- Simple SQL LIKE query (sufficient for household scale)

## AI Assistant

### Interface
- "Ask" button in navigation
- Opens modal with text input
- Shows response with markdown formatting
- "Thinking..." indicator while waiting

### Implementation
1. User submits question
2. System searches wiki, appliances, reminders for relevant context (keyword-based)
3. Sends to Claude API with system prompt and context
4. Displays formatted response

### Technical Details
- Provider: Anthropic API (Claude claude-sonnet-4-20250514)
- API key stored in Rails credentials
- Context: all appliances + top 10 relevant wiki pages/items
- No vector database (keyword search sufficient at this scale)

### Scope Limits
- No conversation history (each question standalone)
- No streaming (wait for complete response)
- No embeddings/vector search

## Deployment

### Running
- `bin/rails server -b 0.0.0.0` on local machine
- Access via `http://<machine-ip>:3000`
- Can run on always-on machine, Raspberry Pi, or old laptop

### Database & Backups
- SQLite file at `db/production.sqlite3`
- Backup by copying the file
- Optional: script to copy to cloud storage daily

### Initial Setup
- Seed file creates two user accounts
- Environment variable for household name (displayed in header)

## Explicitly Out of Scope

- File uploads/attachments (use links to Google Drive, etc.)
- Comments on tasks
- Complex permissions (both users have full access)
- Revision history on wiki pages
- Email notifications
- Calendar view
- Conversation memory in AI assistant
