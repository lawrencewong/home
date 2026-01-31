# Home

A personal home management application built with Ruby on Rails 8.1. Manage household tasks, appliances, reminders, wishlists, and documentation all in one place.

## Features

- **Tasks** - Create and track household tasks with status, due dates, and assignment
- **Appliances** - Inventory household appliances with warranty tracking and maintenance reminders
- **Reminders** - Set one-time or recurring reminders (daily, weekly, monthly, yearly)
- **Wishlist** - Track purchases and future projects with priority and pricing
- **Wiki** - Build a household knowledge base with markdown and internal linking
- **Dashboard** - View assigned tasks, overdue and upcoming reminders at a glance
- **Search** - Find tasks, appliances, and wishlist items across the application
- **AI Assistant** - Ask questions about your home with Claude AI integration

## Tech Stack

- Ruby 3.3.7
- Rails 8.1
- SQLite3
- Tailwind CSS
- Solid Queue (background jobs)
- Solid Cache (caching)

## Requirements

- Ruby 3.3.7
- Bundler
- SQLite3

## Setup

```bash
# Clone the repository
git clone <repository-url>
cd home

# Run the setup script
bin/setup

# Start the development server
bin/dev
```

The application will be available at `http://localhost:3000`.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Web server port | `3000` |
| `RAILS_MAX_THREADS` | Thread pool size | `5` |
| `RAILS_LOG_LEVEL` | Production log level | `info` |
| `JOB_CONCURRENCY` | Background job workers | `1` |

### Credentials

Rails credentials are stored encrypted in `config/credentials.yml.enc`. Edit with:

```bash
bin/rails credentials:edit
```

#### AI Assistant Configuration

To enable the AI Assistant feature, add your Anthropic API key to credentials:

```yaml
anthropic:
  api_key: your-api-key-here
```

### Database

Development and test databases are SQLite files stored in `storage/`:

- `storage/development.sqlite3`
- `storage/test.sqlite3`

Production uses separate databases for cache and queue.

## Development

### Running the Server

```bash
# Start web server and CSS watcher together
bin/dev

# Or run individually
bin/rails server              # Rails on port 3000
bin/rails tailwindcss:watch   # Tailwind CSS compiler
```

### Running Tests

```bash
bin/rails test
```

### Code Style

```bash
# Check style
bin/rubocop

# Auto-fix issues
bin/rubocop -a
```

### Security Scan

```bash
bin/brakeman
```

## Deployment

The application includes Docker and Kamal configuration for production deployment.

### Docker Build

```bash
docker build -t home .
```

### Kamal Deploy

Configure `config/deploy.yml` with your server details, then:

```bash
kamal setup   # First-time setup
kamal deploy  # Deploy updates
```

## License

This project is private.
