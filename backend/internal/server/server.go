package server

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/truthordare/backend/internal/config"
	"github.com/truthordare/backend/internal/handlers"
	"github.com/truthordare/backend/internal/middleware"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/repository"
	"github.com/truthordare/backend/internal/scheduler"
	"gorm.io/gorm"
)

// Server represents the HTTP server.
type Server struct {
	cfg       *config.Config
	db        *gorm.DB
	router    *gin.Engine
	scheduler *scheduler.Scheduler
}

// New creates a new Server instance.
func New(cfg *config.Config, db *gorm.DB) *Server {
	// Set Gin mode based on environment
	if cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Add middleware
	router.Use(gin.Recovery())
	router.Use(corsMiddleware(cfg))
	router.Use(loggerMiddleware())

	s := &Server{
		cfg:    cfg,
		db:     db,
		router: router,
	}

	s.setupRoutes()

	return s
}

// SetScheduler sets the scheduler for the server (used for API endpoints).
func (s *Server) SetScheduler(sched *scheduler.Scheduler) {
	s.scheduler = sched
	s.setupSchedulerRoutes()
}

// Start starts the HTTP server.
func (s *Server) Start() error {
	addr := fmt.Sprintf(":%s", s.cfg.Port)
	return s.router.Run(addr)
}

func (s *Server) setupRoutes() {
	// Health check
	s.router.GET("/health", s.healthCheck)

	// API v1 routes
	v1 := s.router.Group(s.cfg.APIPrefix + "/" + s.cfg.APIVersion)
	{
		// Initialize repositories
		categoryRepo := repository.NewCategoryRepository(s.db)
		taskRepo := repository.NewTaskRepository(s.db)

		// Initialize handlers
		categoryHandler := handlers.NewCategoryHandler(categoryRepo)
		taskHandler := handlers.NewTaskHandler(taskRepo, categoryRepo)
		generateHandler := handlers.NewGenerateHandler(taskRepo, categoryRepo)
		generateCategoryLabelsHandler := handlers.NewGenerateCategoryLabelsHandler()

		// ========== PUBLIC ROUTES (No Auth) ==========

		// Static data endpoints
		v1.GET("/languages", s.listLanguages)
		v1.GET("/age-groups", s.listAgeGroups)

		// Category routes - Public
		categories := v1.Group("/categories")
		{
			categories.GET("", categoryHandler.List) // List all categories (with filters)
		}

		// Task routes - Public
		tasks := v1.Group("/tasks")
		{
			tasks.GET("", taskHandler.List) // List tasks (with filters, sort, pagination)
			tasks.GET("/availability", taskHandler.CheckAvailability)
		}

		// ========== RESTRICTED ROUTES (Requires Auth) ==========
		restricted := v1.Group("")
		restricted.Use(middleware.AuthMiddleware())
		{
			// Auth verification
			restricted.GET("/auth/verify", s.verifyAuth)

			// Category management - Restricted
			restrictedCategories := restricted.Group("/categories")
			{
				restrictedCategories.GET("/count", categoryHandler.Count)
				restrictedCategories.GET("/:id", categoryHandler.Get)
				restrictedCategories.POST("", categoryHandler.Create)
				restrictedCategories.PUT("/:id", categoryHandler.Update)
				restrictedCategories.DELETE("/:id", categoryHandler.Delete)
			}

			// Task management - Restricted
			restrictedTasks := restricted.Group("/tasks")
			{
				restrictedTasks.GET("/count", taskHandler.Count)
				restrictedTasks.GET("/:id", taskHandler.Get)
				restrictedTasks.POST("", taskHandler.Create)
				restrictedTasks.POST("/batch", taskHandler.CreateBatch)
				restrictedTasks.PUT("/:id", taskHandler.Update)
				restrictedTasks.DELETE("/:id", taskHandler.Delete)
				restrictedTasks.GET("/stats", taskHandler.Stats)
				restrictedTasks.GET("/random", taskHandler.GetRandom)
			}

			// AI Generation - Restricted
			restricted.POST("/generate", generateHandler.Generate)
			restricted.POST("/generate/category-labels", generateCategoryLabelsHandler.GenerateCategoryLabels)
		}
	}
}

func (s *Server) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, models.HealthResponse{
		Status:  "healthy",
		Version: "1.0.0",
	})
}

// verifyAuth validates the authentication and returns success if valid
func (s *Server) verifyAuth(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Authentication valid",
	})
}

// listLanguages returns all supported languages (static)
func (s *Server) listLanguages(c *gin.Context) {
	languages := []map[string]string{
		{"code": "en", "name": "English", "native_name": "English", "icon": "🇬🇧"},
		{"code": "zh", "name": "Chinese", "native_name": "中文", "icon": "🇨🇳"},
		{"code": "es", "name": "Spanish", "native_name": "Español", "icon": "🇪🇸"},
		{"code": "hi", "name": "Hindi", "native_name": "हिन्दी", "icon": "🇮🇳"},
		{"code": "ar", "name": "Arabic", "native_name": "العربية", "icon": "🇸🇦"},
		{"code": "fr", "name": "French", "native_name": "Français", "icon": "🇫🇷"},
		{"code": "pt", "name": "Portuguese", "native_name": "Português", "icon": "🇵🇹"},
		{"code": "bn", "name": "Bengali", "native_name": "বাংলা", "icon": "🇧🇩"},
		{"code": "ru", "name": "Russian", "native_name": "Русский", "icon": "🇷🇺"},
		{"code": "ur", "name": "Urdu", "native_name": "اردو", "icon": "🇵🇰"},
	}
	c.JSON(http.StatusOK, gin.H{
		"data": languages,
	})
}

// listAgeGroups returns all age groups (static)
func (s *Server) listAgeGroups(c *gin.Context) {
	ageGroups := []map[string]interface{}{
		{"value": "kids", "label": "Kids", "min_age": 0, "max_age": 12, "description": "Content suitable for children aged 0-12"},
		{"value": "teen", "label": "Teen", "min_age": 13, "max_age": 17, "description": "Content suitable for teenagers aged 13-17"},
		{"value": "adults", "label": "Adults", "min_age": 18, "max_age": 99, "description": "Content for adults 18 and above"},
	}
	c.JSON(http.StatusOK, gin.H{
		"data": ageGroups,
	})
}

// Middleware

func corsMiddleware(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// Check if origin is allowed
		allowed := false
		for _, o := range cfg.CORSOrigins {
			if o == origin || o == "*" {
				allowed = true
				break
			}
		}

		if allowed || cfg.IsDevelopment() {
			c.Header("Access-Control-Allow-Origin", origin)
		}

		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization, X-Admin-OTP")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Max-Age", "86400")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

func loggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		method := c.Request.Method

		gin.DefaultWriter.Write([]byte(
			fmt.Sprintf("[GIN] %s | %d | %v | %s %s\n",
				time.Now().Format("2006/01/02 - 15:04:05"),
				status, latency, method, path),
		))
	}
}

// setupSchedulerRoutes adds scheduler management endpoints.
func (s *Server) setupSchedulerRoutes() {
	if s.scheduler == nil {
		return
	}

	schedulerHandler := handlers.NewSchedulerHandler(s.scheduler)

	// Scheduler routes (restricted)
	v1 := s.router.Group(s.cfg.APIPrefix + "/" + s.cfg.APIVersion)
	restricted := v1.Group("")
	restricted.Use(middleware.AuthMiddleware())
	{
		schedulerGroup := restricted.Group("/scheduler")
		{
			schedulerGroup.GET("/jobs", schedulerHandler.GetJobs)
			schedulerGroup.POST("/run", schedulerHandler.RunJob)
		}
	}
}
