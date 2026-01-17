# Truth or Dare 🎲

A modern, feature-rich Truth or Dare party game built with **Flutter** (mobile app), **Go** (backend API), and **React** (admin panel). Perfect for parties, game nights, and social gatherings!

## 🏛️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│   Go Backend    │◀────│  React Admin    │
│   (Mobile)      │     │   (REST API)    │     │   (Dashboard)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                        ┌──────┴──────┐
                        │   SQLite    │
                        │  Database   │
                        └─────────────┘
```

## 📱 Features

### Mobile App (Flutter)
- **Multiple Game Modes**: Kids, Teens, Adults, and Mature (18+)
- **Spin the Bottle**: Classic bottle spinning with smooth animations
- **Turn Modes**: Sequential, Random, or Spin Bottle
- **Categories**: Multiple categories with consent flags for sensitive content
- **Multilingual Support**: English, Hindi, Gujarati, Spanish, French, German
- **Custom Tasks**: Add your own truths and dares
- **Scoring System**: Track points and crown the winner
- **Timer**: Configurable countdown timer for each task
- **Offline-First**: Works without internet using Hive local database
- **Clean Architecture**: Repository pattern with separation of concerns
- **State Management**: Riverpod for reactive, testable state
- **Beautiful UI**: Material 3 design with smooth animations
- **Sound & Haptics**: Immersive audio feedback and vibrations
- **Dark/Light Themes**: System-aware or manual theme selection

### Backend API (Go)
- **RESTful API**: Clean REST endpoints with Gin framework
- **Database**: SQLite for development, PostgreSQL for production
- **ORM**: GORM with migrations and seeding
- **AI Integration**: Groq API for content generation
- **Admin Auth**: OTP-based authentication for admin endpoints
- **Filtering & Sorting**: Comprehensive query parameters
- **Count Endpoints**: Efficient pagination support

### Admin Panel (React)
- **Dashboard**: Overview statistics and quick actions
- **Category Management**: Full CRUD with emoji picker
- **Task Management**: Create, edit, filter, bulk operations
- **AI Generation**: Generate category labels and tasks with AI
- **Multilingual Editor**: Edit content in multiple languages
- **Responsive Design**: Works on desktop and tablet

## 🏗️ Project Structure

```
tod/
├── flutter_app/              # Flutter Mobile App
│   ├── lib/
│   │   ├── core/             # Core utilities
│   │   │   ├── constants/    # Enums, constants
│   │   │   ├── di/           # Dependency injection
│   │   │   ├── haptics/      # Vibration service
│   │   │   ├── localization/ # i18n translations
│   │   │   ├── providers/    # Riverpod providers
│   │   │   ├── router/       # GoRouter navigation
│   │   │   ├── sound/        # Audio service
│   │   │   └── theme/        # Colors, typography, spacing
│   │   ├── data/
│   │   │   ├── local_db/     # Hive boxes
│   │   │   ├── models/       # Data models
│   │   │   ├── remote_api/   # API client
│   │   │   └── repositories/ # Data repositories
│   │   └── features/         # UI screens
│   │       ├── home/
│   │       ├── game_mode_select/
│   │       ├── player_setup/
│   │       ├── category_select/
│   │       ├── spin_bottle/
│   │       ├── question/
│   │       ├── scoreboard/
│   │       ├── results/
│   │       ├── settings/
│   │       ├── how_to_play/
│   │       └── add_truth_dare/
│   └── pubspec.yaml
│
├── backend/                  # Go REST API
│   ├── cmd/api/main.go       # Entry point
│   └── internal/
│       ├── ai/               # AI client utility
│       ├── config/           # Configuration
│       ├── database/         # DB connection & seeding
│       ├── handlers/         # HTTP handlers
│       ├── models/           # GORM models
│       ├── prompts/          # AI prompt templates
│       ├── repository/       # Data access layer
│       └── server/           # Gin server setup
│
├── admin/                    # React Admin Panel
│   ├── src/
│   │   ├── api/              # API client functions
│   │   ├── components/       # Reusable UI components
│   │   │   ├── EmojiPicker/  # Custom emoji picker
│   │   │   └── ...           # Other components
│   │   ├── pages/            # Page components
│   │   │   ├── DashboardPage.tsx
│   │   │   ├── CategoriesPage.tsx
│   │   │   ├── TasksPage.tsx
│   │   │   └── SettingsPage.tsx
│   │   └── types/            # TypeScript types
│   └── package.json
│
├── instructions.md           # Development instructions
├── run.sh                    # Development run script
└── README.md                 # This file
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.16+ and Dart 3.2+
- Go 1.21+
- Node.js 18+ (for admin panel)
- Android Studio / Xcode (for mobile builds)

### Quick Start (Using run.sh)

```bash
# Make script executable
chmod +x run.sh

# Run everything (backend + admin)
./run.sh

# Run backend only
./run.sh backend

# Run admin only
./run.sh admin
```

### Manual Setup

#### Backend Setup

```bash
cd backend

# Create environment file
cp .env.example .env

# Edit .env with your settings
# DB_TYPE=sqlite
# DB_PATH=./data/truthordare.db
# GROQ_API_KEY=your_groq_api_key
# ADMIN_OTP=your_admin_otp

# Run the server
go run cmd/api/main.go
```

The API will be available at `http://localhost:8080`

#### Admin Panel Setup

```bash
cd admin

# Install dependencies
npm install

# Start development server
npm run dev
```

The admin panel will be available at `http://localhost:5173`

#### Flutter App Setup

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run
```

## 📡 API Endpoints

### Categories

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/categories` | List all categories |
| `GET` | `/api/v1/categories?age=adults` | Filter by age group |
| `GET` | `/api/v1/categories/:id` | Get single category |
| `GET` | `/api/v1/categories/count` | Get category count |
| `POST` | `/api/v1/categories` | Create category (Admin) |
| `PUT` | `/api/v1/categories/:id` | Update category (Admin) |
| `DELETE` | `/api/v1/categories/:id` | Delete category (Admin) |

### Tasks

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/tasks` | List all tasks |
| `GET` | `/api/v1/tasks?category_id=xxx` | Filter by category |
| `GET` | `/api/v1/tasks?type=truth` | Filter by type |
| `GET` | `/api/v1/tasks?age=teens` | Filter by age |
| `GET` | `/api/v1/tasks?from_date=2024-01-01` | Filter by date |
| `GET` | `/api/v1/tasks?sort=created_at&sort_order=desc` | Sort results |
| `GET` | `/api/v1/tasks?limit=10&offset=0` | Pagination |
| `GET` | `/api/v1/tasks/count` | Get task count |
| `GET` | `/api/v1/tasks/random` | Get random task |
| `POST` | `/api/v1/tasks` | Create task (Admin) |
| `PUT` | `/api/v1/tasks/:id` | Update task (Admin) |
| `DELETE` | `/api/v1/tasks/:id` | Delete task (Admin) |

### AI Generation (Admin)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/generate` | Generate tasks with AI |
| `POST` | `/api/v1/generate/category-labels` | Generate category labels |

### Authentication

Admin endpoints require the `X-Admin-OTP` header:

```bash
curl -X POST http://localhost:8080/api/v1/categories \
  -H "X-Admin-OTP: your_otp_here" \
  -H "Content-Type: application/json" \
  -d '{"name": {...}, "emoji": "🎉"}'
```

### Health Check

```
GET /health
```

## 🎮 Game Flow

1. **Home** → Start a new game or continue existing
2. **Game Mode** → Select age-appropriate mode (Kids/Teens/Adults/Mature)
3. **Player Setup** → Add 2-16 players with custom avatars
4. **Categories** → Choose which categories to include
5. **Spin/Play** → Spin the bottle or pass-and-play
6. **Question** → Choose Truth or Dare
7. **Complete** → Finish task to earn points or forfeit
8. **Results** → View final scores and winner

## 🌐 Multilingual Support

The app supports multiple languages with the `MultilingualText` model:

```json
{
  "text": {
    "en": "What is your biggest fear?",
    "hi": "आपका सबसे बड़ा डर क्या है?",
    "es": "¿Cuál es tu mayor miedo?"
  }
}
```

Categories and tasks automatically display in the user's selected language.

## 🔒 Content Safety

- **Age-based filtering**: Categories and tasks are filtered by age group
- **Consent flags**: Sensitive categories require explicit consent
- **Custom consent messages**: Per-category warning messages

## 📦 Dependencies

### Flutter App
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `hive_flutter` - Local database
- `dio` - HTTP client
- `equatable` - Value equality
- `uuid` - Unique ID generation
- `google_fonts` - Typography
- `audioplayers` - Sound effects
- `vibration` - Haptic feedback

### Go Backend
- `gin` - Web framework
- `gorm` - ORM
- `zerolog` - Logging
- `godotenv` - Environment variables
- `uuid` - Unique ID generation
- `rate` - Rate limiting

### React Admin
- `react` 19 - UI framework
- `@tanstack/react-query` - Data fetching
- `@mui/material` - UI components
- `react-router-dom` - Routing
- `axios` - HTTP client
- `vite` - Build tool

## 🎨 Theming

The app uses Material 3 design with customizable themes:

```dart
// Primary colors
static const truthGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
static const dareGradient = [Color(0xFFEF4444), Color(0xFFF97316)];

// Semantic colors
static const success = Color(0xFF10B981);
static const error = Color(0xFFEF4444);
static const gold = Color(0xFFFFD700);
```

## 🔧 Configuration

### Backend Environment Variables

```env
# Server
PORT=8080
GIN_MODE=release

# Database
DB_TYPE=sqlite
DB_PATH=./data/truthordare.db

# For PostgreSQL:
# DB_TYPE=postgres
# DB_HOST=localhost
# DB_PORT=5432
# DB_USER=postgres
# DB_PASS=password
# DB_NAME=truthordare

# AI (for content generation)
GROQ_API_KEY=your_groq_api_key

# Admin Authentication
ADMIN_OTP=your_secure_otp
```

### Admin Environment Variables

```env
# API Base URL
VITE_API_URL=http://localhost:8080

# Admin OTP (for authentication)
VITE_ADMIN_OTP=your_secure_otp
```

### Flutter API Configuration

```dart
// lib/core/constants/app_constants.dart
static const String apiBaseUrl = 'http://localhost:8080/api/v1';
```

## 📚 Documentation

- [Backend README](./backend/README.md) - API documentation and setup
- [Admin README](./admin/README.md) - Admin panel features and setup
- [Instructions](./instructions.md) - Development instructions and API reference

## 📝 License

This project is for educational and personal use. Please ensure you have appropriate permissions before using any third-party assets.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📧 Support

For questions or issues, please open a GitHub issue.

---

Made with ❤️ using Flutter, Go, and React
# tod
