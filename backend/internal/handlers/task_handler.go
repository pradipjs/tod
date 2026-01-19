package handlers

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/repository"
)

// TaskHandler handles task-related HTTP requests.
type TaskHandler struct {
	repo         *repository.TaskRepository
	categoryRepo *repository.CategoryRepository
}

// NewTaskHandler creates a new TaskHandler.
func NewTaskHandler(repo *repository.TaskRepository, categoryRepo *repository.CategoryRepository) *TaskHandler {
	return &TaskHandler{
		repo:         repo,
		categoryRepo: categoryRepo,
	}
}

// List godoc
// @Summary List tasks
// @Description Get all tasks with optional filters. Supports multiple values for categories, types, and languages.
// @Tags tasks
// @Accept json
// @Produce json
// @Param category_id query string false "Single category ID filter"
// @Param category_ids query string false "Multiple category IDs (comma-separated)"
// @Param type query string false "Single task type (truth, dare)"
// @Param types query string false "Multiple task types (comma-separated)"
// @Param language query string false "Single language code (en, hi, ur, etc.)"
// @Param languages query string false "Language codes (comma-separated: en,hi,ur)"
// @Param exclude query string false "Comma-separated task IDs to exclude"
// @Param from_date query string false "Filter tasks created after this date (RFC3339 format)"
// @Param to_date query string false "Filter tasks created before this date (RFC3339 format)"
// @Param sort_by query string false "Sort field (created_at, updated_at, language, type)"
// @Param sort_order query string false "Sort order (asc, desc)"
// @Param limit query int false "Limit results"
// @Param offset query int false "Offset for pagination"
// @Param random query bool false "Randomize results"
// @Success 200 {object} models.PaginatedResponse[models.TaskResponse]
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks [get]
func (h *TaskHandler) List(c *gin.Context) {
	filter := &repository.TaskFilter{}

	// Single category ID
	if categoryID := c.Query("category_id"); categoryID != "" {
		filter.CategoryID = categoryID
	}

	// Multiple category IDs
	if categoryIDs := c.Query("category_ids"); categoryIDs != "" {
		filter.CategoryIDs = splitAndTrim(categoryIDs)
	}

	// Single task type
	if taskType := c.Query("type"); taskType != "" {
		filter.Type = taskType
	}

	// Multiple task types
	if types := c.Query("types"); types != "" {
		filter.Types = splitAndTrim(types)
	}

	// Single language
	if language := c.Query("language"); language != "" {
		filter.Language = language
	}

	// Multiple languages
	if languages := c.Query("languages"); languages != "" {
		filter.Languages = splitAndTrim(languages)
	}

	if exclude := c.Query("exclude"); exclude != "" {
		filter.ExcludeIDs = splitAndTrim(exclude)
	}

	// Date range filters
	if fromDate := c.Query("from_date"); fromDate != "" {
		if t, err := time.Parse(time.RFC3339, fromDate); err == nil {
			filter.FromDate = &t
		}
	}
	if toDate := c.Query("to_date"); toDate != "" {
		if t, err := time.Parse(time.RFC3339, toDate); err == nil {
			filter.ToDate = &t
		}
	}

	// Sort parameters
	if sortBy := c.Query("sort_by"); sortBy != "" {
		filter.SortBy = sortBy
	}
	if sortOrder := c.Query("sort_order"); sortOrder != "" {
		filter.SortOrder = strings.ToLower(sortOrder)
	}

	if limit := c.Query("limit"); limit != "" {
		if val, err := strconv.Atoi(limit); err == nil {
			filter.Limit = val
		}
	}

	if offset := c.Query("offset"); offset != "" {
		if val, err := strconv.Atoi(offset); err == nil {
			filter.Offset = val
		}
	}

	if random := c.Query("random"); random != "" {
		if val, err := strconv.ParseBool(random); err == nil {
			filter.Random = val
		}
	}

	tasks, total, err := h.repo.FindAll(filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to fetch tasks",
		})
		return
	}

	// Convert to response format
	taskResponses := make([]models.TaskResponse, len(tasks))
	for i, task := range tasks {
		taskResponses[i] = task.ToResponse()
	}

	// Calculate pagination info
	page := 1
	pageSize := len(tasks)
	if filter.Limit > 0 {
		pageSize = filter.Limit
		page = (filter.Offset / filter.Limit) + 1
	}
	totalPages := 1
	if pageSize > 0 && total > 0 {
		totalPages = int((total + int64(pageSize) - 1) / int64(pageSize))
	}

	response := models.PaginatedResponse[models.TaskResponse]{
		Data:       taskResponses,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}

	c.JSON(http.StatusOK, response)
}

// splitAndTrim splits a comma-separated string and trims whitespace.
func splitAndTrim(s string) []string {
	parts := strings.Split(s, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

// CheckAvailability godoc
// @Summary Check task availability
// @Description Check if tasks are available for the given filters. Returns count of truths and dares.
// @Tags tasks
// @Accept json
// @Produce json
// @Param category_ids query string false "Category IDs (comma-separated)"
// @Param languages query string false "Language codes (comma-separated)"
// @Success 200 {object} TaskAvailabilityResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/availability [get]
func (h *TaskHandler) CheckAvailability(c *gin.Context) {
	filter := &repository.TaskFilter{}

	if categoryIDs := c.Query("category_ids"); categoryIDs != "" {
		filter.CategoryIDs = splitAndTrim(categoryIDs)
	}

	if languages := c.Query("languages"); languages != "" {
		filter.Languages = splitAndTrim(languages)
	}

	truthCount, dareCount, err := h.repo.CountByFilters(filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to check availability",
		})
		return
	}

	c.JSON(http.StatusOK, TaskAvailabilityResponse{
		TruthCount:  truthCount,
		DareCount:   dareCount,
		HasTruths:   truthCount > 0,
		HasDares:    dareCount > 0,
		IsAvailable: truthCount > 0 || dareCount > 0,
	})
}

// TaskAvailabilityResponse is the response for availability check.
type TaskAvailabilityResponse struct {
	TruthCount  int64 `json:"truth_count"`
	DareCount   int64 `json:"dare_count"`
	HasTruths   bool  `json:"has_truths"`
	HasDares    bool  `json:"has_dares"`
	IsAvailable bool  `json:"is_available"`
}

// Get godoc
// @Summary Get task by ID
// @Description Get a specific task by its ID
// @Tags tasks
// @Accept json
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} models.TaskResponse
// @Failure 404 {object} models.ErrorResponse
// @Router /tasks/{id} [get]
func (h *TaskHandler) Get(c *gin.Context) {
	id := c.Param("id")

	task, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "not_found",
			Message: "Task not found",
		})
		return
	}

	c.JSON(http.StatusOK, task.ToResponse())
}

// GetRandom godoc
// @Summary Get random task
// @Description Get a random task matching the filters
// @Tags tasks
// @Accept json
// @Produce json
// @Param category_id query string false "Category ID filter"
// @Param category_ids query string false "Multiple category IDs (comma-separated)"
// @Param type query string false "Task type (truth, dare)"
// @Param language query string false "Language code (en, hi, ur, etc.)"
// @Param languages query string false "Language codes (comma-separated)"
// @Param exclude query string false "Comma-separated task IDs to exclude"
// @Success 200 {object} models.TaskResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/random [get]
func (h *TaskHandler) GetRandom(c *gin.Context) {
	filter := &repository.TaskFilter{}

	if categoryID := c.Query("category_id"); categoryID != "" {
		filter.CategoryID = categoryID
	}

	if categoryIDs := c.Query("category_ids"); categoryIDs != "" {
		filter.CategoryIDs = strings.Split(categoryIDs, ",")
	}

	if taskType := c.Query("type"); taskType != "" {
		filter.Type = taskType
	}

	if language := c.Query("language"); language != "" {
		filter.Language = language
	}

	if languages := c.Query("languages"); languages != "" {
		filter.Languages = strings.Split(languages, ",")
	}

	if exclude := c.Query("exclude"); exclude != "" {
		filter.ExcludeIDs = strings.Split(exclude, ",")
	}

	task, err := h.repo.FindRandom(filter)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "not_found",
			Message: "No matching task found",
		})
		return
	}

	c.JSON(http.StatusOK, task.ToResponse())
}

// CreateTaskRequest is the request body for creating a task.
type CreateTaskRequest struct {
	Text       string `json:"text" binding:"required"`
	Type       string `json:"type" binding:"required,oneof=truth dare"`
	CategoryID string `json:"category_id" binding:"required"`
	Language   string `json:"language" binding:"required,len=2"`
}

// Create godoc
// @Summary Create task
// @Description Create a new task
// @Tags tasks
// @Accept json
// @Produce json
// @Param task body CreateTaskRequest true "Task data"
// @Success 201 {object} models.TaskResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks [post]
func (h *TaskHandler) Create(c *gin.Context) {
	var req CreateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	// Validate that the category exists
	if _, err := h.categoryRepo.FindByID(req.CategoryID); err != nil {
		log.Warn().Str("category_id", req.CategoryID).Msg("Task creation attempted with non-existent category")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Category not found",
		})
		return
	}

	task := &models.Task{
		Text:       req.Text,
		Type:       req.Type,
		CategoryID: req.CategoryID,
		Language:   req.Language,
	}

	if err := h.repo.Create(task); err != nil {
		log.Error().Err(err).Msg("Failed to create task")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to create task",
		})
		return
	}

	c.JSON(http.StatusCreated, task.ToResponse())
}

// CreateBatchRequest is the request for creating multiple tasks.
type CreateBatchRequest struct {
	Tasks []CreateTaskRequest `json:"tasks" binding:"required,dive"`
}

// CreateBatch godoc
// @Summary Create multiple tasks
// @Description Create multiple tasks at once
// @Tags tasks
// @Accept json
// @Produce json
// @Param tasks body CreateBatchRequest true "Tasks data"
// @Success 201 {object} models.SuccessResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/batch [post]
func (h *TaskHandler) CreateBatch(c *gin.Context) {
	var req CreateBatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	tasks := make([]models.Task, len(req.Tasks))
	for i, t := range req.Tasks {
		tasks[i] = models.Task{
			Text:       t.Text,
			Type:       t.Type,
			CategoryID: t.CategoryID,
			Language:   t.Language,
		}
	}

	if err := h.repo.CreateBatch(tasks); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to create tasks",
		})
		return
	}

	c.JSON(http.StatusCreated, models.SuccessResponse{
		Success: true,
		Message: "Tasks created successfully",
	})
}

// Update godoc
// @Summary Update task
// @Description Update an existing task
// @Tags tasks
// @Accept json
// @Produce json
// @Param id path string true "Task ID"
// @Param task body CreateTaskRequest true "Task data"
// @Success 200 {object} models.TaskResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/{id} [put]
func (h *TaskHandler) Update(c *gin.Context) {
	id := c.Param("id")

	task, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "not_found",
			Message: "Task not found",
		})
		return
	}

	var req CreateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	task.Text = req.Text
	task.Type = req.Type
	task.CategoryID = req.CategoryID
	task.Language = req.Language

	if err := h.repo.Update(task); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to update task",
		})
		return
	}

	c.JSON(http.StatusOK, task.ToResponse())
}

// Delete godoc
// @Summary Delete task
// @Description Delete a task (soft delete)
// @Tags tasks
// @Accept json
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} models.SuccessResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/{id} [delete]
func (h *TaskHandler) Delete(c *gin.Context) {
	id := c.Param("id")

	if _, err := h.repo.FindByID(id); err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "not_found",
			Message: "Task not found",
		})
		return
	}

	if err := h.repo.Delete(id); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to delete task",
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Task deleted successfully",
	})
}

// Stats godoc
// @Summary Get task statistics
// @Description Get task counts by category and type
// @Tags tasks
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/stats [get]
func (h *TaskHandler) Stats(c *gin.Context) {
	byCategory, err := h.repo.CountByCategory()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to fetch statistics",
		})
		return
	}

	byType, err := h.repo.CountByType()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to fetch statistics",
		})
		return
	}

	var total int64
	for _, count := range byType {
		total += count
	}

	c.JSON(http.StatusOK, gin.H{
		"total":       total,
		"by_category": byCategory,
		"by_type":     byType,
	})
}

// Count godoc
// @Summary Get task count
// @Description Get total count of tasks with optional filters
// @Tags tasks
// @Accept json
// @Produce json
// @Param category_id query string false "Single category ID filter"
// @Param category_ids query string false "Multiple category IDs (comma-separated)"
// @Param type query string false "Single task type (truth, dare)"
// @Param types query string false "Multiple task types (comma-separated)"
// @Param language query string false "Single language code (en, hi, ur, etc.)"
// @Param languages query string false "Language codes (comma-separated)"
// @Param from_date query string false "Filter tasks created after this date (RFC3339 format)"
// @Param to_date query string false "Filter tasks created before this date (RFC3339 format)"
// @Success 200 {object} map[string]interface{}
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/count [get]
func (h *TaskHandler) Count(c *gin.Context) {
	filter := &repository.TaskFilter{}

	if categoryID := c.Query("category_id"); categoryID != "" {
		filter.CategoryID = categoryID
	}

	if categoryIDs := c.Query("category_ids"); categoryIDs != "" {
		filter.CategoryIDs = splitAndTrim(categoryIDs)
	}

	if taskType := c.Query("type"); taskType != "" {
		filter.Type = taskType
	}

	if types := c.Query("types"); types != "" {
		filter.Types = splitAndTrim(types)
	}

	if language := c.Query("language"); language != "" {
		filter.Language = language
	}

	if languages := c.Query("languages"); languages != "" {
		filter.Languages = splitAndTrim(languages)
	}

	if fromDate := c.Query("from_date"); fromDate != "" {
		if t, err := time.Parse(time.RFC3339, fromDate); err == nil {
			filter.FromDate = &t
		}
	}

	if toDate := c.Query("to_date"); toDate != "" {
		if t, err := time.Parse(time.RFC3339, toDate); err == nil {
			filter.ToDate = &t
		}
	}

	count, err := h.repo.Count(filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to count tasks",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"count": count,
	})
}
