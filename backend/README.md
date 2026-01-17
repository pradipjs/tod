# Truth or Dare - Backend API

A high-performance Go backend for the Truth or Dare game, providing APIs for categories and tasks with multilingual support and AI-powered content generation.

## Features

- 🚀 High-performance Gin web framework
- 📦 SQLite database with GORM ORM
- 🌍 Multilingual support (10 languages)
- 🔍 Flexible filtering, sorting, and pagination
- 🎲 Random task selection with exclusion
- 📝 Full CRUD operations
- 🤖 AI-powered content generation (Groq)
- 🔐 OTP-based authentication for admin routes
- 📊 Statistics and count endpoints
- 🏥 Health check endpoint

## Quick Start

### Prerequisites

- Go 1.21 or higher
- SQLite3

### Installation

```bash
# Navigate to backend
cd backend

# Copy environment file
cp .env.example .env

# Edit .env with your settings
# - Set ADMIN_OTP_KEY for admin authentication
# - Set GROQ_API_KEY for AI generation

# Download dependencies
go mod download

# Run the server
go run cmd/api/main.go
```

The server will start at `http://localhost:8080`

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| APP_ENV | Environment (development/production) | development |
| PORT | Server port | 8080 |
| DB_PATH | SQLite database path | ./truthordare.db |
| ADMIN_OTP_KEY | OTP key for admin authentication | (required) |
| GROQ_API_KEY | Groq API key for AI generation | (optional) |
| GROQ_API_URL | Groq API URL | https://api.groq.com/openai/v1/chat/completions |
| GROQ_MODEL | AI model to use | llama-3.3-70b-versatile |

## API Endpoints

### Public Endpoints (No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Health check |
| GET | /api/v1/languages | List supported languages |
| GET | /api/v1/age-groups | List age groups |
| GET | /api/v1/categories | List categories (with filters) |
| GET | /api/v1/tasks | List tasks (with filters, sort, pagination) |
| GET | /api/v1/tasks/availability | Check task availability |

### Restricted Endpoints (Requires X-Admin-OTP header)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/auth/verify | Verify OTP |
| GET | /api/v1/categories/count | Get category count |
| GET | /api/v1/categories/:id | Get category by ID |
| POST | /api/v1/categories | Create category |
| PUT | /api/v1/categories/:id | Update category |
| DELETE | /api/v1/categories/:id | Delete category |
| GET | /api/v1/tasks/count | Get task count |
| GET | /api/v1/tasks/:id | Get task by ID |
| POST | /api/v1/tasks | Create task |
| POST | /api/v1/tasks/batch | Create multiple tasks |
| PUT | /api/v1/tasks/:id | Update task |
| DELETE | /api/v1/tasks/:id | Delete task |
| GET | /api/v1/tasks/stats | Get task statistics |
| GET | /api/v1/tasks/random | Get random task |
| POST | /api/v1/generate | AI-generate tasks |
| POST | /api/v1/generate/category-labels | AI-generate category labels |

### Query Parameters

**Tasks List:**
```
GET /api/v1/tasks?category_ids=uuid1,uuid2&age_groups=kids,teen&types=truth,dare&languages=en,hi&active=true&sort_by=created_at&sort_order=desc&from_date=2024-01-01T00:00:00Z&to_date=2024-12-31T23:59:59Z&limit=20&offset=0
```

| Parameter | Type | Description |
|-----------|------|-------------|
| category_id | string | Single category ID |
| category_ids | string | Multiple category IDs (comma-separated) |
| type | string | Single task type (truth, dare) |
| types | string | Multiple task types |
| age_group | string | Single age group |
| age_groups | string | Multiple age groups |
| languages | string | Language codes |
| intensity | int | Max intensity (1-3) |
| active | bool | Filter by active status |
| from_date | string | Created after (RFC3339) |
| to_date | string | Created before (RFC3339) |
| sort_by | string | Sort field |
| sort_order | string | asc or desc |
| limit | int | Limit results |
| offset | int | Pagination offset |
| random | bool | Randomize results |

## Project Structure

```
backend/
├── cmd/
│   └── api/
│       └── main.go           # Application entry point
├── internal/
│   ├── ai/
│   │   └── client.go         # AI client for Groq API
│   ├── config/
│   │   └── config.go         # Configuration management
│   ├── database/
│   │   ├── database.go       # Database connection
│   │   └── seed.go           # Database seeding
│   ├── handlers/
│   │   ├── category_handler.go
│   │   ├── task_handler.go
│   │   ├── generate_handler.go
│   │   └── generate_category_labels_handler.go
│   ├── middleware/
│   │   └── auth.go           # OTP authentication
│   ├── models/
│   │   └── models.go         # Data models
│   ├── prompts/
│   │   ├── loader.go         # Prompt template loader
│   │   ├── category_labels.txt
│   │   └── generate_tasks.txt
│   ├── repository/
│   │   ├── category_repository.go
│   │   └── task_repository.go
│   ├── server/
│   │   └── server.go         # HTTP server setup
│   └── services/
│       └── ai_service.go     # Legacy AI service
├── .env.example
├── go.mod
├── go.sum
└── README.md
```

## AI Integration

The backend integrates with Groq AI for:
1. **Task Generation**: Generate truth/dare questions in any supported language
2. **Category Label Translation**: Auto-translate category names to all languages

### Prompt Templates

Prompts are stored in `internal/prompts/` as `.txt` files with placeholders:
- `{{PLACEHOLDER}}` format for variable substitution
- Embedded via Go's embed package for deployment

## Development

```bash
# Run with hot reload (requires air)
air

# Build
go build -o bin/api cmd/api/main.go

# Run tests
go test ./...

# Format code
go fmt ./...
```

## License

MIT
