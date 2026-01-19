# Truth or Dare — Flutter Game  
## Master Instructions for GitHub Copilot

---

## 1. Product Vision

Build a premium-quality, offline-first Truth or Dare party game using Flutter that works flawlessly on:
- Android phones
- Android tablets
- iPhones
- iPads

The app must feel:
- Fun
- Fast
- Polished
- Modern
- Highly interactive

Code quality is as important as gameplay.

---

## 2. Core Principles

All development must follow:

- Clean Architecture
- SOLID principles
- Separation of concerns
- Modular design
- Reusable components
- Testable logic
- Performance-first mindset
- Accessibility-ready UI
- Multilingual support from day one

---

## 3. Business Entities

### Age Groups (3 levels only)
- **kids** - Ages 0-12
- **teen** - Ages 13-17
- **adults** - Ages 18+ (requires consent popup)

### Supported Languages (10 languages)
| Code | Language |
|------|----------|
| en | English |
| zh | Chinese |
| es | Spanish |
| hi | Hindi |
| ar | Arabic |
| fr | French |
| pt | Portuguese |
| bn | Bengali |
| ru | Russian |
| ur | Urdu |

### Category Entity
```json
{
  "id": "uuid",
  "emoji": "🎉",
  "age_group": "teen",
  "name": {
    "en": "Party",
    "es": "Fiesta",
    "hi": "पार्टी",
    "ur": "پارٹی"
  },
  "description": {
    "en": "Fun party questions",
    ...
  }
}
```

### Task (Question) Entity
```json
{
  "id": "uuid",
  "type": "truth|dare",
  "age_group": "adults",
  "category_id": "uuid",
  "intensity": 1-3,
  "content": {
    "en": "What's your secret?",
    "hi": "आपका राज़ क्या है?",
    ...
  },
  "repeat_count": 0  // Frontend only - tracks usage
}
```

---

## 4. Game Rules

### Turn Modes
- Sequential
- Random
- Spin the Bottle (physics-based, not random selection)

### Player Rules
- Min players: 2  
- Max players: 16  

### Age Group Selection
- Kids (0-12 years)
- Teen (13-17 years)
- Adults (18+ years, requires consent popup)

### Question Rules
- Player chooses:
  - Truth
  - Dare
  - Random
- Questions fetched based on:
  - Age Group
  - Category
  - Language
- A question must not repeat until all in its pool are exhausted.
- `repeat_count` tracked locally for frontend rotation algorithm.

### Timer Rules
- Default: 60 seconds
- Tap to pause/resume
- Time out = auto forfeit
- Done = +1 point
- Forfeit = 0 point

---

## 5. API Documentation

### Authentication
The admin API uses OTP-based authentication. The OTP key is configured in the `.env` file.

```
# Request Header for authenticated endpoints
X-Admin-OTP: your-admin-otp-key
```

### Public Endpoints (No Auth Required)

```
GET /api/v1/health                     - Health check
GET /api/v1/languages                  - List all supported languages
GET /api/v1/age-groups                 - List all age groups with min/max ages
GET /api/v1/categories                 - List categories (with filters)
GET /api/v1/tasks                      - List tasks (with filters, sort, pagination)
GET /api/v1/tasks/availability         - Check task availability for game
```

### Restricted Endpoints (Auth Required)

```
GET    /api/v1/auth/verify                    - Verify OTP is valid
GET    /api/v1/categories/count               - Get category count with filters
GET    /api/v1/categories/:id                 - Get category by ID
POST   /api/v1/categories                     - Create category
PUT    /api/v1/categories/:id                 - Update category
DELETE /api/v1/categories/:id                 - Delete category
GET    /api/v1/tasks/count                    - Get task count with filters
GET    /api/v1/tasks/:id                      - Get task by ID
POST   /api/v1/tasks                          - Create task
POST   /api/v1/tasks/batch                    - Create multiple tasks
PUT    /api/v1/tasks/:id                      - Update task
DELETE /api/v1/tasks/:id                      - Delete task
GET    /api/v1/tasks/stats                    - Get task statistics
GET    /api/v1/tasks/random                   - Get random task
POST   /api/v1/generate                       - AI-generate tasks
POST   /api/v1/generate/category-labels       - AI-generate category labels
```

### Query Parameters

**Categories:**
```
GET /api/v1/categories?age_groups=kids,teen&active=true
GET /api/v1/categories/count?age_groups=kids,teen&active=true
```

**Tasks:**
```
GET /api/v1/tasks?age_groups=kids,teen&languages=en,hi,ar&category_ids=uuid1,uuid2&types=truth,dare&active=true&limit=20&offset=0&sort_by=created_at&sort_order=desc&from_date=2024-01-01T00:00:00Z&to_date=2024-12-31T23:59:59Z
GET /api/v1/tasks/availability?age_groups=adults&languages=en&category_ids=uuid1
GET /api/v1/tasks/count?category_id=uuid&type=truth&active=true
```

**Task Query Parameter Reference:**
| Parameter | Type | Description |
|-----------|------|-------------|
| category_id | string | Single category ID filter |
| category_ids | string | Multiple category IDs (comma-separated) |
| type | string | Single task type (truth, dare) |
| types | string | Multiple task types (comma-separated) |
| age_group | string | Single age group (kids, teen, adults) |
| age_groups | string | Multiple age groups (comma-separated) |
| languages | string | Language codes (comma-separated) |
| intensity | int | Maximum intensity level (1-3) |
| requires_consent | bool | Filter by consent requirement |
| active | bool | Filter by active status |
| exclude | string | Task IDs to exclude (comma-separated) |
| from_date | string | Filter tasks created after (RFC3339) |
| to_date | string | Filter tasks created before (RFC3339) |
| sort_by | string | Sort field (created_at, updated_at, intensity, min_age, type) |
| sort_order | string | Sort order (asc, desc) |
| limit | int | Limit results |
| offset | int | Offset for pagination |
| random | bool | Randomize results |

### Generate Tasks Endpoint
```json
POST /api/v1/generate
{
  "category_id": "uuid",
  "category_name": "Party",
  "age_group": "adults",
  "language": "en",
  "count": 10,
  "explicit_mode": false
}
```
Response includes created task counts and saves tasks synchronously.

### Generate Category Labels Endpoint
```json
POST /api/v1/generate/category-labels
{
  "category_name": "Party",
  "languages": ["en", "es", "hi", "ar"]  // optional, defaults to all
}
```
Response:
```json
{
  "success": true,
  "labels": {
    "en": "Party",
    "es": "Fiesta",
    "hi": "पार्टी",
    "ar": "حفلة"
  }
}
```

---

## 6. Play Button Logic
When user clicks Play at the final game setup stage:
1. Check local task availability for selected presets (age group, categories, language)
2. If not enough truths OR dares available locally:
   - Fetch data from backend
   - Store in app database (Hive)
   - Continue game once synced
3. Show loading indicator during sync
4. If sync fails and local cache insufficient, show error
---

## 7. Feature Set

### Gameplay
- Category selection (preselected defaults)
- If user selects none → auto select ALL
- Intensity slider:
  - Chill (level 1)
  - Normal (level 2)
  - Wild (level 3)

### Engagement
- Streaks
- Session summary
- MVP player highlight

### Personalization
- Theme changer
- Bottle skin changer
- Player avatars

### Home Screen Controls
- Language selector
- Sound toggle
- Haptics toggle
- Settings
- Share
- How to Play

---

## 8. Architecture

### Tech Stack
- **Frontend**: Flutter (latest stable)
- **State Management**: Riverpod
- **Local DB**: Hive with type adapters
- **HTTP Client**: Dio
- **Routing**: go_router
- **Backend**: Go with Gin framework
- **Backend DB**: SQLite with GORM

### Layers
- Presentation (UI)
- Application (state, controllers)
- Domain (business logic)
- Data (DB, API)

---

## 9. Folder Structure

### Flutter App
```
flutter_app/
├─ lib/
│  ├─ core/
│  │  ├─ theme/
│  │  ├─ localization/
│  │  ├─ sound/
│  │  ├─ haptics/
│  │  ├─ utils/
│  │  ├─ constants/
│  │  ├─ providers/
│  │  └─ di/
│  ├─ data/
│  │  ├─ models/
│  │  ├─ repositories/
│  │  ├─ local_db/
│  │  ├─ remote_api/
│  │  └─ services/
│  ├─ presentation/
│  │  ├─ screens/
│  │  ├─ widgets/
│  │  └─ router/
│  └─ main.dart
```

### Backend
```
backend/
├─ cmd/server/
├─ internal/
│  ├─ config/
│  ├─ handlers/
│  ├─ middleware/
│  ├─ models/
│  ├─ repository/
│  └─ server/
├─ migrations/
└─ seeds/
```

---

## 10. Database Schema

### Category (Backend)
- id (UUID, primary key)
- emoji (string, default: 📝)
- age_group (string: kids/teen/adults)
- label (JSON - multilingual)
- requires_consent (bool, default: false)
- is_active (bool, default: true)
- sort_order (int, default: 0)
- created_at (timestamp)
- updated_at (timestamp)
- deleted_at (timestamp, soft delete)

### Task (Backend)
- id (UUID, primary key)
- type (truth/dare)
- category_id (UUID, FK to categories)
- text (JSON - multilingual)
- min_age (int, default: 0)
- intensity (1-3, default: 2)
- requires_consent (bool, default: false)
- is_active (bool, default: true)
- created_at (timestamp)
- updated_at (timestamp)
- deleted_at (timestamp, soft delete)

### SQLite Indexes
- idx_task_category (category_id)
- idx_task_type (type)
- idx_task_min_age (min_age)
- idx_task_intensity (intensity)
- idx_task_active (is_active)
- idx_categories_age_group (age_group)

---

## 11. Question Rotation Algorithm

1. Load all eligible questions from local cache
2. Filter by:
   - age_group
   - category_ids
   - language (content must exist in that language)
3. Track `usedTaskIds` in GameSession
4. If all used:
   - Reset usedTaskIds to empty
5. Pick random unused question
6. Increment local `repeat_count` for analytics

---

## 12. Spin the Bottle System

- Render circular wheel with player names
- Bottle sprite at center
- On swipe:
  - Calculate angular velocity
  - Apply friction-based deceleration
  - Stop naturally
- Determine final angle → selected player
- Allow bottle skin changer

---

## 13. Sound & Haptics

### Sounds
- Button tap
- Spin start
- Spin stop
- Timer tick
- Success
- Forfeit

### Haptics
- Light tap
- Heavy impact on spin stop

Allow user to toggle both from Home Screen.

---

## 14. Localization

- Use Flutter localization system
- All strings via centralized AppLocalizations class
- Support all 10 languages from day one
- Architecture must support adding more languages easily
- Task content stored as JSON map with language codes as keys

---

## 15. UI/UX Guidelines

- Responsive for phones & tablets
- Large touch targets
- Smooth animations
- Material 3 design
- Dark mode support
- High contrast accessibility
- Themed components

---

## 16. Performance Rules

- No heavy logic in UI thread
- Use isolates if needed
- Lazy load assets
- Cache questions locally (offline-first)
- Keep animations at 60fps
- Avoid unnecessary rebuilds
- Background sync with 24-hour threshold

---

## 17. Coding Standards

- Feature-first structure
- One responsibility per class
- Clear naming
- No magic numbers
- Full documentation comments
- No tight coupling
- Dependency injection everywhere
- Testable business logic
- Modular and reusable code

---

## 18. GitHub Copilot Instructions

Copilot must act as:
- A senior Flutter engineer
- Always prefer:
  - Clean architecture
  - Modular code
  - Reusability
  - Documentation
- Never write:
  - Hard-coded logic
  - Monolithic widgets
  - God classes

---

## 19. Scope Boundaries

### Included
- Offline single-device multiplayer
- Server sync for questions
- Multi-language content support
- Age-appropriate content filtering

### Not included (v1)
- Online multiplayer
- Accounts
- Cloud saves
- User-generated content moderation

---

## 20. Success Criteria

The app is successful if:
- Gameplay feels smooth
- UI feels premium
- Codebase is scalable
- Adding new features is easy
- Copilot can generate consistent, clean code
- Offline-first works reliably
- Sync is seamless and non-blocking

---

## 21. Admin Panel

### Technology Stack
- **Framework**: React with TypeScript
- **UI Library**: Material UI (MUI)
- **State Management**: TanStack React Query
- **HTTP Client**: Axios
- **Routing**: React Router DOM

### Features
1. **Authentication**: OTP-based login via X-Admin-OTP header
2. **Dashboard**: Overview stats for categories and tasks
3. **Categories Management**: CRUD operations with multilingual labels
4. **Tasks Management**: CRUD with filtering, pagination, server-side search
5. **AI Generation**: Generate tasks using Groq AI with configurable parameters

### Admin Structure
```
admin/
├─ src/
│  ├─ api/            # API client and endpoints
│  ├─ components/     # Layout, ProtectedRoute
│  ├─ contexts/       # AuthContext
│  ├─ pages/          # Dashboard, Categories, Tasks, Generate, Login
│  ├─ theme/          # MUI theme configuration
│  ├─ types/          # TypeScript types
│  └─ App.tsx         # Main app with routing
└─ .env               # VITE_API_URL configuration
```

### Running the Admin Panel
```bash
cd admin
npm install
npm run dev
```

---

## 22. Backend Configuration

### Environment Variables (.env)
```
APP_ENV=development
PORT=8080
DB_PATH=./data/tod.db
ADMIN_OTP_KEY=your-secure-otp-key
GROQ_API_KEY=your-groq-api-key
GROQ_MODEL=llama-3.3-70b-versatile
```

### Running the Backend
```bash
cd backend
go run cmd/api/main.go
```

---

## 23. Development Run Script

A convenience script is provided to run both services:

```bash
# From project root
./run.sh           # Run both backend and admin (default)
./run.sh backend   # Run only backend
./run.sh admin     # Run only admin
./run.sh all       # Run both backend and admin
./run.sh help      # Show help message

# With custom ports
BACKEND_PORT=3000 ./run.sh
ADMIN_PORT=3001 ./run.sh admin
```

---

## 24. AI Integration

### Prompt Management
Prompts are stored in `/backend/internal/prompts/` as `.txt` files with placeholders:
- `category_labels.txt` - Generate multilingual category labels
- `generate_tasks.txt` - Generate truth/dare tasks

### AI Client
The modular AI client (`/backend/internal/ai/client.go`) supports:
- OpenAI-compatible APIs (Groq, OpenAI, etc.)
- Configurable via environment variables
- JSON response parsing
- Functional options for customization

### Prompt Loader
The prompt loader (`/backend/internal/prompts/loader.go`) provides:
- Embedded file system for prompts
- Placeholder replacement: `{{PLACEHOLDER_NAME}}`
- Caching for performance
- Singleton pattern

---

## 25. Code Audit & Improvements (January 2026)

### Backend Critical Fixes Applied

#### 1. Security: Auth Middleware Timing-Safe Comparison
**File:** `/backend/internal/middleware/auth.go`
- Added `crypto/subtle.ConstantTimeCompare` to prevent timing attacks
- Added logging for failed auth attempts (with rate limiting recommended for production)
- Added production mode check to require non-default OTP key

#### 2. Data Integrity: Seed Tasks CategoryID Fix
**File:** `/backend/internal/database/seed.go`
- Fixed `getInitialTasks()` to properly accept and assign CategoryID
- Seeded tasks are now properly linked to their categories

#### 3. Performance: CountByFilters Optimization
**File:** `/backend/internal/repository/task_repository.go`
- Replaced inefficient `FindAll()` + count pattern with proper SQL COUNT queries
- Now uses `buildFilteredQuery()` + `Count()` for better performance

#### 4. Validation: Category Existence Check Before Task Creation
**Files:** `/backend/internal/handlers/task_handler.go`, `/backend/internal/handlers/generate_handler.go`
- Added category validation before creating tasks
- Returns 400 Bad Request if category_id doesn't exist
- Added logging for invalid category attempts

#### 5. Cleanup: Removed Unused Code
- Deleted unused duplicate `/backend/internal/services/ai_service.go`
- Removed empty `/backend/internal/services/` directory

### Test Coverage Added

#### `/backend/internal/handlers/handlers_test.go`
- Category handler tests: List, Get, Create, Update, Delete, Count
- Task handler tests: List, Create, GetRandom, Count
- Category validation tests for task creation

#### `/backend/internal/repository/repository_test.go`
- Category repository tests: Create, FindByID, FindAll (with filters), Update, Delete, Count
- Task repository tests: Create, FindByID, FindAll (with filters), FindRandom, CountByFilters, DateFilters, Update, Delete

#### `/backend/internal/middleware/auth_test.go`
- Auth middleware tests: Missing header, invalid key, valid key
- Development mode default key test
- Production mode required OTP key test

#### `/backend/internal/models/models_test.go`
- MultilingualText: JSON marshal/unmarshal, Value, Scan
- Age group validation
- Language validation
- Age range helpers (GetMinAgeForGroup, GetMaxAgeForGroup)
- Model response conversion tests

### Admin Panel Improvements Applied

#### 1. Performance: Dashboard API Optimization
**File:** `/admin/src/pages/DashboardPage.tsx`
- Replaced inefficient task fetching (1000 tasks) with dedicated count APIs
- Added `getCategoryCount()` and `getTaskCount()` API functions
- Dashboard now makes lightweight count requests instead of fetching all data

#### 2. Accessibility: EmojiPicker Improvements
**File:** `/admin/src/components/EmojiPicker.tsx`
- Added ARIA labels for button, popover, search, and grid elements
- Implemented keyboard navigation (Arrow keys, Enter, Space, Escape)
- Added focus indicators for screen readers
- Category tabs now have proper role="tablist" and aria-selected attributes

#### 3. Form Validation: Zod Schemas
**File:** `/admin/src/validation/schemas.ts`
- Created validation schemas for Category, Task, Generate, and Login forms
- Requires English text for multilingual fields
- Type-safe form data types exported

#### 4. Error Handling: Global Error Boundary
**File:** `/admin/src/components/ErrorBoundary.tsx`
- Class-based error boundary component
- Shows user-friendly error message with retry options
- Displays error details in development mode
- Integrated into App.tsx as root wrapper

### Pending Improvements (TODO) - ALL COMPLETED ✅

#### Flutter App
1. ~~**Asset Directories**: Create missing `assets/images/`, `assets/sounds/`, `assets/bottles/` directories~~ ✅ DONE
2. ~~**Deprecated APIs**: Replace `withOpacity()` calls with `.withValues()` for Color class~~ ✅ DONE (all 35+ instances fixed)
3. ~~**Unused Imports**: Clean up unused import statements~~ ✅ DONE

### Flutter Improvements Applied (January 2026)

#### 1. Logging Infrastructure
**File:** `/flutter_app/lib/core/utils/logger.dart`
- Created `AppLogger` utility with debug-only logging
- Methods: `debug`, `info`, `warning`, `error`, `success`
- All methods support optional `tag` parameter for categorization
- Error/warning methods accept `error` object and `stackTrace`
- Only logs in debug mode (`kDebugMode`)

#### 2. API Client Debug Logging
**File:** `/flutter_app/lib/data/remote_api/api_client.dart`
- Replaced Dio's default `LogInterceptor` with custom `_DebugLogInterceptor`
- Only active in debug mode for production safety
- Logs request method/path, response status, and errors

#### 3. Repository Error Handling
**Files:** 
- `/flutter_app/lib/data/repositories/category_repository.dart`
- `/flutter_app/lib/data/repositories/task_repository.dart`
- Replaced silent `catch (e) {}` blocks with proper logging
- Added stack traces to error logging for debugging
- Background sync failures now log warnings instead of silent fails
- Cache parsing errors are now logged for troubleshooting

#### 4. Sync Service Error Handling
**File:** `/flutter_app/lib/data/services/sync_service.dart`
- Added `_tag` constant for consistent logging
- `syncCategories()`, `syncTasks()` now log errors with stack traces
- Success logs show count of synced items
- Uses `AppLogger.success()` for positive operations

#### 5. Provider Error Handling
**Files:**
- `/flutter_app/lib/core/providers/categories_provider.dart`
- `/flutter_app/lib/core/providers/game_provider.dart`
- Added logging for state management operations
- Task availability check failures are properly logged
- "No tasks available" now logs a warning for debugging

#### 6. Enum Consistency Fixes
**File:** `/flutter_app/lib/core/constants/enums.dart`
- Added `value` getter to `AgeGroup` (alias for `apiValue`)
- Added `value` getter to `TaskType` (alias for `apiValue`)
- Added `level` getter to `Intensity` (alias for `value`)
- Added `fromLevel()` static method to `Intensity`
- Added `value` getter and `fromString()` to `TurnMode`
- Added `completed` and `forfeited` constants to `TimerState`
- Removed duplicate `SoundEffect` and `HapticType` enums (use service file versions)

#### 7. Model Fixes
**Files:**
- `/flutter_app/lib/data/models/category.dart` - Added `icon` getter, `availableModes`, `isAvailableForMode()`
- `/flutter_app/lib/data/models/player.dart` - Added `completedTasks`, `forfeitedTasks` getters
- `/flutter_app/lib/data/models/game_session.dart` - Added `currentRound` getter
- `/flutter_app/lib/data/models/app_settings.dart` - Added `BottleSkin` enum, `language` getter, `defaultAgeGroup` field

#### 8. Theme Fixes
**File:** `/flutter_app/lib/core/theme/app_colors.dart`
- Added `primary`, `secondary` colors
- Added `gold`, `silver`, `bronze` colors for leaderboard

#### 9. Screen Fixes
**Files:**
- `/flutter_app/lib/features/settings/settings_screen.dart` - Fixed AgeGroup enum usage, removed invalid parameters
- `/flutter_app/lib/features/add_truth_dare/add_truth_dare_screen.dart` - Fixed CategoriesState usage
- `/flutter_app/lib/features/category_select/category_select_screen.dart` - Fixed loadCategories parameters
- `/flutter_app/lib/features/game_mode_select/game_mode_screen.dart` - Fixed GameMode.adult → GameMode.adults
- `/flutter_app/lib/features/results/results_screen.dart` - Renamed duplicate ScoreboardScreen

#### 10. Provider Fixes
**File:** `/flutter_app/lib/core/providers/settings_provider.dart`
- Added `setDefaultAgeGroup()` method
**File:** `/flutter_app/lib/core/providers/game_provider.dart`
- Added `endGame()` and `restartGame()` methods

### Running Tests
```bash
# Backend tests
cd backend
go test ./internal/... -v

# Run with coverage
go test ./internal/... -cover

# Run specific package
go test ./internal/handlers/... -v
go test ./internal/repository/... -v
go test ./internal/middleware/... -v
go test ./internal/models/... -v

# Admin build (includes TypeScript type checking)
cd admin
npm run build

# Flutter analysis
cd flutter_app
flutter analyze

# Flutter code generation (for Hive/Freezed)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Current Build Status (January 2026)

| Component | Status | Details |
|-----------|--------|---------|
| **Go Backend** | ✅ ALL TESTS PASSING | handlers, middleware, models, repository |
| **React Admin** | ✅ BUILD PASSING | TypeScript, no errors |
| **Flutter App** | ✅ 0 ERRORS, 0 WARNINGS | Only 9 info-level deprecation notices |

#### Flutter Deprecation Info (Non-blocking)
- 3x `Color.value` deprecation - Flutter recommending component accessors
- 1x `TextFormField.value` → use `initialValue` instead  
- 6x `Radio.groupValue/onChanged` → use `RadioGroup` ancestor

These are informational only and don't affect functionality.

---

## 26. Additional Notes

### GORM Default Behavior
When using GORM with `default:true` on boolean fields:
- Setting `field: false` explicitly may still result in `true` due to Go's zero-value behavior
- Use `.Update()` method after creation to set boolean fields to `false`
- Consider using `*bool` (pointer) for optional boolean fields

### Test Database Setup
Tests use SQLite in-memory databases (`:memory:`) for isolation:
- Each test function gets a fresh database
- AutoMigrate creates tables at test start
- No cleanup needed - database is discarded after test
