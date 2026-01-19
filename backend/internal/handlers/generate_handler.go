package handlers

import (
	"fmt"
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
// All fields are optional - null/empty means "all"
type GenerateTasksRequest struct {
	CategoryID *string `json:"category_id"` // Optional - null means all categories
	AgeGroup   *string `json:"age_group"`   // Optional - null means all age groups
	Language   *string `json:"language"`    // Optional - null means all languages
	Count      int     `json:"count"`       // Tasks per combination
}

// GenerateTasksResponse is the response for task generation
type GenerateTasksResponse struct {
	Success           bool   `json:"success"`
	Message           string `json:"message"`
	TotalTruthsCount  int    `json:"total_truths_count"`
	TotalDaresCount   int    `json:"total_dares_count"`
	TasksCreated      int    `json:"tasks_created"`
	CombinationsCount int    `json:"combinations_count"`
}

// generationParams holds parameters for a single generation
type generationParams struct {
	CategoryID   string
	CategoryName string
	AgeGroup     string
	Language     string
	ExplicitMode bool
}

// Generate godoc
// @Summary Generate tasks using AI
// @Description Generate truth and dare tasks using AI. If category_id, age_group, or language is null, generates for all combinations.
// @Tags generate
// @Accept json
// @Produce json
// @Param request body GenerateTasksRequest true "Generation parameters (null values mean 'all')"
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

	// Build list of generation combinations
	combinations, err := h.buildCombinations(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	if len(combinations) == 0 {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "No valid combinations found",
		})
		return
	}

	// Generate tasks for each combination
	totalTruths := 0
	totalDares := 0
	tasksCreated := 0

	for _, params := range combinations {
		truths, dares, created, err := h.generateForParams(params, req.Count)
		if err != nil {
			log.Error().Err(err).
				Str("category", params.CategoryName).
				Str("age_group", params.AgeGroup).
				Str("language", params.Language).
				Msg("Failed to generate tasks for combination")
			continue
		}
		totalTruths += truths
		totalDares += dares
		tasksCreated += created
	}

	c.JSON(http.StatusOK, GenerateTasksResponse{
		Success:           true,
		Message:           "Tasks generated and saved successfully",
		TotalTruthsCount:  totalTruths,
		TotalDaresCount:   totalDares,
		TasksCreated:      tasksCreated,
		CombinationsCount: len(combinations),
	})
}

// buildCombinations creates all parameter combinations based on the request
func (h *GenerateHandler) buildCombinations(req GenerateTasksRequest) ([]generationParams, error) {
	var combinations []generationParams

	// Get categories
	var categories []models.Category
	if req.CategoryID != nil && *req.CategoryID != "" {
		category, err := h.categoryRepo.FindByID(*req.CategoryID)
		if err != nil {
			return nil, err
		}
		categories = append(categories, *category)
	} else {
		// Get all active categories
		active := true
		cats, err := h.categoryRepo.FindAll(&repository.CategoryFilter{IsActive: &active})
		if err != nil {
			return nil, err
		}
		categories = cats
	}

	// Get age groups
	var ageGroups []string
	if req.AgeGroup != nil && *req.AgeGroup != "" {
		if !models.IsValidAgeGroup(*req.AgeGroup) {
			return nil, fmt.Errorf("invalid age group: %s", *req.AgeGroup)
		}
		ageGroups = append(ageGroups, *req.AgeGroup)
	} else {
		ageGroups = []string{models.AgeGroupKids, models.AgeGroupTeen, models.AgeGroupAdults}
	}

	// Get languages
	var languages []string
	if req.Language != nil && *req.Language != "" {
		if !models.IsValidLanguage(*req.Language) {
			return nil, fmt.Errorf("invalid language: %s", *req.Language)
		}
		languages = append(languages, *req.Language)
	} else {
		languages = models.SupportedLanguages
	}

	// Build combinations - filter by age group compatibility
	for _, cat := range categories {
		for _, ageGroup := range ageGroups {
			// Skip incompatible age groups
			// Adults categories can only be used by adults
			// Teen categories can be used by teen and adults
			// Kids categories can be used by all
			if cat.AgeGroup == models.AgeGroupAdults && ageGroup != models.AgeGroupAdults {
				continue
			}
			if cat.AgeGroup == models.AgeGroupTeen && ageGroup == models.AgeGroupKids {
				continue
			}

			for _, lang := range languages {
				combinations = append(combinations, generationParams{
					CategoryID:   cat.ID,
					CategoryName: cat.Label["en"],
					AgeGroup:     ageGroup,
					Language:     lang,
					ExplicitMode: cat.RequiresConsent && ageGroup == models.AgeGroupAdults,
				})
			}
		}
	}

	return combinations, nil
}

// generateForParams generates tasks for a single parameter set
func (h *GenerateHandler) generateForParams(params generationParams, count int) (int, int, int, error) {
	// Load system prompt
	systemPrompt, err := h.promptLoader.Load("generate_tasks_system")
	if err != nil {
		return 0, 0, 0, err
	}

	// Load and prepare the user prompt
	explicitStr := "false"
	if params.ExplicitMode {
		explicitStr = "true"
	}

	userPrompt, err := h.promptLoader.LoadAndReplace(
		"generate_tasks",
		prompts.P("AGE_GROUP", params.AgeGroup),
		prompts.P("CATEGORY", params.CategoryName),
		prompts.P("LANGUAGE", params.Language),
		prompts.P("COUNT", strconv.Itoa(count)),
		prompts.P("EXPLICIT_MODE", explicitStr),
	)
	if err != nil {
		return 0, 0, 0, err
	}

	// Call AI to generate content
	messages := []ai.Message{
		{Role: "system", Content: systemPrompt},
		{Role: "user", Content: userPrompt},
	}

	var content GeneratedContent
	err = h.aiClient.CompleteJSON(messages, &content,
		ai.WithTemperature(0.8),
		ai.WithMaxTokens(4000), // Increased for larger batches
	)
	if err != nil {
		return 0, 0, 0, err
	}

	// Save generated tasks to database
	tasksCreated := 0

	// Save truths
	for _, truth := range content.Truths {
		task := &models.Task{
			CategoryID: params.CategoryID,
			Type:       models.TaskTypeTruth,
			Text:       truth,
			Language:   params.Language,
		}
		task.ID = uuid.New().String()

		if err := h.taskRepo.Create(task); err == nil {
			tasksCreated++
		}
	}

	// Save dares
	for _, dare := range content.Dares {
		task := &models.Task{
			CategoryID: params.CategoryID,
			Type:       models.TaskTypeDare,
			Text:       dare,
			Language:   params.Language,
		}
		task.ID = uuid.New().String()

		if err := h.taskRepo.Create(task); err == nil {
			tasksCreated++
		}
	}

	log.Info().
		Str("category", params.CategoryName).
		Str("age_group", params.AgeGroup).
		Str("language", params.Language).
		Int("truths", len(content.Truths)).
		Int("dares", len(content.Dares)).
		Int("created", tasksCreated).
		Msg("Generated tasks for combination")

	return len(content.Truths), len(content.Dares), tasksCreated, nil
}
