# Truth or Dare - Admin Panel

A React-based admin panel for managing Truth or Dare game content, including categories, tasks, and AI-powered content generation.

## Features

- 🔐 OTP-based authentication
- 📊 Dashboard with statistics
- 📂 Category management with emoji picker
- 📝 Task management with multilingual support
- 🤖 AI-powered content generation
- 🌍 Support for 10 languages
- 🎨 Material UI components
- 📱 Responsive design

## Tech Stack

- **Framework**: React 19 with TypeScript
- **Build Tool**: Vite
- **UI Library**: Material UI (MUI)
- **State Management**: TanStack React Query
- **HTTP Client**: Axios
- **Routing**: React Router DOM

## Quick Start

### Prerequisites

- Node.js 18 or higher
- npm or yarn
- Backend API running

### Installation

```bash
# Navigate to admin
cd admin

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your settings
# - Set VITE_API_URL to your backend URL

# Start development server
npm run dev
```

The admin panel will start at `http://localhost:5173`

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| VITE_API_URL | Backend API URL | http://localhost:8080 |

## Project Structure

```
admin/
├── src/
│   ├── api/
│   │   └── index.ts          # API client and endpoints
│   ├── components/
│   │   ├── EmojiPicker.tsx   # Custom emoji picker
│   │   ├── Layout.tsx        # App layout with sidebar
│   │   └── ProtectedRoute.tsx
│   ├── contexts/
│   │   └── AuthContext.tsx   # Authentication context
│   ├── pages/
│   │   ├── CategoriesPage.tsx
│   │   ├── DashboardPage.tsx
│   │   ├── GeneratePage.tsx
│   │   ├── LoginPage.tsx
│   │   └── TasksPage.tsx
│   ├── theme/
│   │   └── index.ts          # MUI theme configuration
│   ├── types/
│   │   └── index.ts          # TypeScript types
│   ├── App.tsx               # Main app with routing
│   └── main.tsx              # Entry point
├── .env
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## Pages

### Login
- OTP-based authentication
- Validates against backend `/api/v1/auth/verify`
- Stores OTP in localStorage

### Dashboard
- Overview statistics
- Category count
- Task count by type

### Categories
- List all categories with filters
- Create/Edit/Delete categories
- Emoji picker for category icons
- **AI Generate**: Auto-translate category labels to all languages

### Tasks
- List tasks with pagination
- Filter by category, type, age group, language
- Sort by created date, updated date, intensity
- Date range filtering
- Create/Edit/Delete tasks

### Generate
- AI-powered task generation
- Select category, age group, language
- Configure count and explicit mode
- Tasks saved synchronously

## API Integration

The admin panel communicates with the backend via:
- `X-Admin-OTP` header for authentication
- RESTful endpoints under `/api/v1`

### Key API Calls

```typescript
// Authentication
verifyAuth(): Promise<boolean>

// Categories
getCategories(filter?): Promise<Category[]>
createCategory(data): Promise<Category>
updateCategory(id, data): Promise<Category>
deleteCategory(id): Promise<SuccessResponse>
generateCategoryLabels(name, languages?): Promise<Labels>

// Tasks
getTasks(filter?): Promise<PaginatedResponse<Task>>
createTask(data): Promise<Task>
updateTask(id, data): Promise<Task>
deleteTask(id): Promise<SuccessResponse>

// Generation
generateTasks(data): Promise<GenerateResponse>
```

## Development

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Lint code
npm run lint
```

## Supported Languages

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

## License

MIT
