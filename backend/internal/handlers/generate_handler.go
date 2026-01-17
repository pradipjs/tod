package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/ai"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/prompts"
	"github.com/truthordare/backend/internal/repository"
)

// GenerateHandler handles AI content generation requests
type GenerateHandler struct {
	aiClient     *ai.Client
	promptLoader *prompts.PromptLoader
	taskRepo     *repository.TaskRepository
	categoryRepo *repository.CategoryRepository
}

// NewGenerateHandler creates a new GenerateHandler
func NewGenerateHandler(taskRepo *repository.TaskRepository, categoryRepo *repository.CategoryRepository) *GenerateHandler {
	return &GenerateHandler{
		aiClient:     ai.GetClient(),
		promptLoader: prompts.GetLoader(),
		taskRepo:     taskRepo,
		categoryRepo: categoryRepo,
	}
}

// GeneratedContent represents the AI response structure
type GeneratedContent struct {
	Truths []string `json:"truths"`
	Dares  []string `json:"dares"`
}

// GenerateTasksRequest is the request body for generating tasks
type GenerateTasksRequest struct {
	CategoryID   string `json:"category_id" binding:"required"`
	CategoryName string `json:"category_name" binding:"required"`
	AgeGroup     string `json:"age_group" binding:"required"`
	Language     string `json:"language" binding:"required"`
	Count        int    `json:"count"`
	ExplicitMode bool   `json:"explicit_mode"`
}

// GenerateTasksResponse is the response for task generation
type GenerateTasksResponse struct {
	Success      bool   `json:"success"`
	Message      string `json:"message"`
	TruthsCount  int    `json:"truths_count"`
	DaresCount   int    `json:"dares_count"`
	TasksCreated int    `json:"tasks_created"`
}

// Generate godoc
// @Summary Generate tasks using AI
// @Description Generate truth and dare tasks using AI for a specific category, age group, and language. Tasks are saved synchronously.
// @Tags generate
// @Accept json
// @Produce json
// @Param request body GenerateTasksRequest true "Generation parameters"
// @Success 200 {object} GenerateTasksResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /generate [post]
func (h *GenerateHandler) Generate(c *gin.Context) {
	var req GenerateTasksRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	// Validate that the category exists
	if _, err := h.categoryRepo.FindByID(req.CategoryID); err != nil {
		log.Warn().Str("category_id", req.CategoryID).Msg("Generate attempted with non-existent category")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Category not found",
		})
		return
	}

	// Validate age group
	if !models.IsValidAgeGroup(req.AgeGroup) {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Invalid age group. Must be: kids, teen, or adults",
		})
		return
	}

	// Validate language
	if !models.IsValidLanguage(req.Language) {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Invalid language code",
		})
		return
	}

	// Set default count
	if req.Count <= 0 {
		req.Count = 10
	}
	if req.Count > 50 {
		req.Count = 50 // Cap at 50
	}

	// Check if AI is configured
	if !h.aiClient.IsConfigured() {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "configuration_error",
			Message: "AI service is not configured. Please set GROQ_API_KEY.",
		})
		return
	}

	// Load and prepare the prompt
	explicitStr := "false"
	if req.ExplicitMode {
		explicitStr = "true"
	}

	prompt, err := h.promptLoader.LoadAndReplace(
		"generate_tasks",
		prompts.P("AGE_GROUP", req.AgeGroup),
		prompts.P("CATEGORY", req.CategoryName),
		prompts.P("LANGUAGE", req.Language),
		prompts.P("COUNT", strconv.Itoa(req.Count)),
		prompts.P("EXPLICIT_MODE", explicitStr),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to load prompt template: " + err.Error(),
		})
		return
	}

	// Call AI to generate content
	messages := []ai.Message{
		{Role: "user", Content: prompt},
	}

	var content GeneratedContent
	err = h.aiClient.CompleteJSON(messages, &content,
		ai.WithTemperature(0.8),
		ai.WithMaxTokens(2000),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "ai_error",
			Message: "Failed to generate content: " + err.Error(),
		})
		return
	}

	// Save generated tasks to database synchronously
	tasksCreated := 0

	// Save truths
	for _, truth := range content.Truths {
		task := &models.Task{
			CategoryID: req.CategoryID,
			Type:       models.TaskTypeTruth,
			Text:       models.MultilingualText{req.Language: truth},
			MinAge:     models.GetMinAgeForGroup(req.AgeGroup),
			IsActive:   true,
		}
		task.ID = uuid.New().String()

		if err := h.taskRepo.Create(task); err == nil {
			tasksCreated++
		}
	}

	// Save dares
	for _, dare := range content.Dares {
		task := &models.Task{
			CategoryID: req.CategoryID,
			Type:       models.TaskTypeDare,
			Text:       models.MultilingualText{req.Language: dare},
			MinAge:     models.GetMinAgeForGroup(req.AgeGroup),
			IsActive:   true,
		}
		task.ID = uuid.New().String()

		if err := h.taskRepo.Create(task); err == nil {
			tasksCreated++
		}
	}

	c.JSON(http.StatusOK, GenerateTasksResponse{
		Success:      true,
		Message:      "Tasks generated and saved successfully",
		TruthsCount:  len(content.Truths),
		DaresCount:   len(content.Dares),
		TasksCreated: tasksCreated,
	})
}
