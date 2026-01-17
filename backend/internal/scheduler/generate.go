package scheduler

import (
	"context"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/ai"
	"github.com/truthordare/backend/internal/config"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/prompts"
	"github.com/truthordare/backend/internal/repository"
	"gorm.io/gorm"
)

// AutoGenerateJob handles automatic generation of tasks for all category+language combinations.
type AutoGenerateJob struct {
	db           *gorm.DB
	cfg          *config.SchedulerConfig
	categoryRepo *repository.CategoryRepository
	taskRepo     *repository.TaskRepository
	aiClient     *ai.Client
	promptLoader *prompts.PromptLoader
}

// NewAutoGenerateJob creates a new auto-generate job.
func NewAutoGenerateJob(
	db *gorm.DB,
	cfg *config.SchedulerConfig,
	categoryRepo *repository.CategoryRepository,
	taskRepo *repository.TaskRepository,
) *AutoGenerateJob {
	return &AutoGenerateJob{
		db:           db,
		cfg:          cfg,
		categoryRepo: categoryRepo,
		taskRepo:     taskRepo,
		aiClient:     ai.GetClient(),
		promptLoader: prompts.GetLoader(),
	}
}

// ToJob converts AutoGenerateJob to a schedulable Job.
func (a *AutoGenerateJob) ToJob() *Job {
	return &Job{
		Name:        "auto-generate",
		Description: "Generate tasks for all category+language combinations",
		CronExpr:    a.cfg.AutoGenerateCron,
		Enabled:     a.cfg.AutoGenerateEnabled,
		Fn:          a.Execute,
	}
}

// GeneratedContent represents the AI response structure.
type GeneratedContent struct {
	Truths []string `json:"truths"`
	Dares  []string `json:"dares"`
}

// Execute runs the auto-generate job.
func (a *AutoGenerateJob) Execute(ctx context.Context) error {
	logger := log.With().Str("job", "auto-generate").Logger()
	logger.Info().Msg("Starting auto-generate job")

	// Check if AI is configured
	if !a.aiClient.IsConfigured() {
		logger.Error().Msg("AI client is not configured, skipping auto-generate")
		return nil
	}

	// Get all active categories
	isActive := true
	categories, err := a.categoryRepo.FindAll(&repository.CategoryFilter{
		IsActive: &isActive,
	})
	if err != nil {
		logger.Error().Err(err).Msg("Failed to fetch categories")
		return err
	}

	if len(categories) == 0 {
		logger.Info().Msg("No active categories found, skipping generation")
		return nil
	}

	logger.Info().
		Int("categories", len(categories)).
		Int("languages", len(models.SupportedLanguages)).
		Msg("Starting task generation")

	// Track statistics
	stats := &GenerateStats{
		StartTime: time.Now(),
	}

	// Process each category
	for _, category := range categories {
		// Determine age group for the category
		ageGroup := category.AgeGroup
		if ageGroup == "" {
			ageGroup = models.AgeGroupAdults
		}

		// Process each language
		for _, language := range models.SupportedLanguages {
			select {
			case <-ctx.Done():
				logger.Warn().Msg("Auto-generate job cancelled")
				return ctx.Err()
			default:
			}

			result := a.generateForCombination(ctx, &category, language, ageGroup)
			stats.TotalAttempts++

			if result.Success {
				stats.SuccessCount++
				stats.TasksCreated += result.TasksCreated
			} else {
				stats.FailureCount++
				stats.Errors = append(stats.Errors, GenerateError{
					CategoryID: category.ID,
					Language:   language,
					Error:      result.Error,
				})
			}

			// Small delay between API calls to avoid rate limiting
			time.Sleep(500 * time.Millisecond)
		}
	}

	stats.EndTime = time.Now()
	stats.Duration = stats.EndTime.Sub(stats.StartTime)

	logger.Info().
		Int("total_attempts", stats.TotalAttempts).
		Int("success_count", stats.SuccessCount).
		Int("failure_count", stats.FailureCount).
		Int("tasks_created", stats.TasksCreated).
		Dur("duration", stats.Duration).
		Msg("Auto-generate job completed")

	return nil
}

// GenerateResult represents the result of a single generation attempt.
type GenerateResult struct {
	Success      bool
	TasksCreated int
	Error        string
}

// generateForCombination generates tasks for a specific category+language combination with retry logic.
func (a *AutoGenerateJob) generateForCombination(
	ctx context.Context,
	category *models.Category,
	language string,
	ageGroup string,
) GenerateResult {
	logger := log.With().
		Str("job", "auto-generate").
		Str("category_id", category.ID).
		Str("category_name", category.Label.Get("en")).
		Str("language", language).
		Str("age_group", ageGroup).
		Logger()

	maxRetries := a.cfg.AutoGenerateRetryMax
	retryDelay := time.Duration(a.cfg.AutoGenerateRetryDelaySeconds) * time.Second
	count := a.cfg.AutoGenerateCount

	var lastError error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		select {
		case <-ctx.Done():
			return GenerateResult{Success: false, Error: "context cancelled"}
		default:
		}

		if attempt > 1 {
			logger.Info().
				Int("attempt", attempt).
				Int("max_retries", maxRetries).
				Dur("delay", retryDelay).
				Msg("Retrying after delay")
			time.Sleep(retryDelay)
		}

		result, err := a.doGenerate(ctx, category, language, ageGroup, count)
		if err == nil {
			logger.Info().
				Int("tasks_created", result.TasksCreated).
				Int("attempt", attempt).
				Msg("Generation successful")
			return result
		}

		lastError = err
		logger.Warn().
			Err(err).
			Int("attempt", attempt).
			Int("max_retries", maxRetries).
			Msg("Generation attempt failed")

		// Check if it's a rate limit error (usually 429 status)
		if !isRetryableError(err) {
			logger.Error().Err(err).Msg("Non-retryable error, stopping attempts")
			break
		}
	}

	errorMsg := "unknown error"
	if lastError != nil {
		errorMsg = lastError.Error()
	}

	logger.Error().
		Str("error", errorMsg).
		Int("attempts", maxRetries).
		Msg("All generation attempts failed")

	return GenerateResult{
		Success: false,
		Error:   errorMsg,
	}
}

// doGenerate performs the actual generation.
func (a *AutoGenerateJob) doGenerate(
	ctx context.Context,
	category *models.Category,
	language string,
	ageGroup string,
	count int,
) (GenerateResult, error) {
	// Determine explicit mode based on category
	explicitMode := category.RequiresConsent
	explicitStr := "false"
	if explicitMode {
		explicitStr = "true"
	}

	// Get category name for prompt
	categoryName := category.Label.Get("en")
	if categoryName == "" {
		categoryName = category.Label.Get(language)
	}

	// Load and prepare the prompt
	prompt, err := a.promptLoader.LoadAndReplace(
		"generate_tasks",
		prompts.P("AGE_GROUP", ageGroup),
		prompts.P("CATEGORY", categoryName),
		prompts.P("LANGUAGE", language),
		prompts.P("COUNT", strconv.Itoa(count)),
		prompts.P("EXPLICIT_MODE", explicitStr),
	)
	if err != nil {
		return GenerateResult{}, err
	}

	// Call AI to generate content
	messages := []ai.Message{
		{Role: "user", Content: prompt},
	}

	var content GeneratedContent
	err = a.aiClient.CompleteJSON(messages, &content,
		ai.WithTemperature(0.8),
		ai.WithMaxTokens(2000),
	)
	if err != nil {
		return GenerateResult{}, err
	}

	// Save generated tasks to database
	tasksCreated := 0

	// Save truths
	for _, truth := range content.Truths {
		task := &models.Task{
			CategoryID:      category.ID,
			Type:            models.TaskTypeTruth,
			Text:            models.MultilingualText{language: truth},
			MinAge:          models.GetMinAgeForGroup(ageGroup),
			RequiresConsent: category.RequiresConsent,
			IsActive:        true,
		}
		task.ID = uuid.New().String()

		if err := a.taskRepo.Create(task); err == nil {
			tasksCreated++
		}
	}

	// Save dares
	for _, dare := range content.Dares {
		task := &models.Task{
			CategoryID:      category.ID,
			Type:            models.TaskTypeDare,
			Text:            models.MultilingualText{language: dare},
			MinAge:          models.GetMinAgeForGroup(ageGroup),
			RequiresConsent: category.RequiresConsent,
			IsActive:        true,
		}
		task.ID = uuid.New().String()

		if err := a.taskRepo.Create(task); err == nil {
			tasksCreated++
		}
	}

	return GenerateResult{
		Success:      true,
		TasksCreated: tasksCreated,
	}, nil
}

// isRetryableError checks if an error is retryable (e.g., rate limit).
func isRetryableError(err error) bool {
	if err == nil {
		return false
	}

	errStr := err.Error()
	// Check for common rate limit indicators
	retryableIndicators := []string{
		"rate limit",
		"Rate limit",
		"429",
		"too many requests",
		"Too Many Requests",
		"quota exceeded",
		"temporarily unavailable",
		"timeout",
		"Timeout",
		"connection refused",
		"connection reset",
	}

	for _, indicator := range retryableIndicators {
		if contains(errStr, indicator) {
			return true
		}
	}

	return false
}

// contains checks if a string contains a substring (case-sensitive).
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsHelper(s, substr))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// GenerateStats holds statistics from the auto-generate job.
type GenerateStats struct {
	StartTime     time.Time
	EndTime       time.Time
	Duration      time.Duration
	TotalAttempts int
	SuccessCount  int
	FailureCount  int
	TasksCreated  int
	Errors        []GenerateError
}

// GenerateError represents an error during generation.
type GenerateError struct {
	CategoryID string `json:"category_id"`
	Language   string `json:"language"`
	Error      string `json:"error"`
}
