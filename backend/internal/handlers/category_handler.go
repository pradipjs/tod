package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/repository"
)

// CategoryHandler handles category-related HTTP requests.
type CategoryHandler struct {
	repo *repository.CategoryRepository
}

// NewCategoryHandler creates a new CategoryHandler.
func NewCategoryHandler(repo *repository.CategoryRepository) *CategoryHandler {
	return &CategoryHandler{repo: repo}
}

// List godoc
// @Summary List categories
// @Description Get all categories with optional filters (no pagination)
// @Tags categories
// @Accept json
// @Produce json
// @Param age_groups query string false "Comma-separated age groups (kids,teen,adults)"
// @Param requires_consent query bool false "Filter by consent requirement"
// @Param active query bool false "Filter by active status"
// @Success 200 {object} map[string]interface{}
// @Failure 500 {object} models.ErrorResponse
// @Router /categories [get]
func (h *CategoryHandler) List(c *gin.Context) {
	filter := &repository.CategoryFilter{}

	// Parse age_groups (comma-separated)
	if ageGroups := c.Query("age_groups"); ageGroups != "" {
		filter.AgeGroups = strings.Split(ageGroups, ",")
	}

	// Parse requires_consent
	if consent := c.Query("requires_consent"); consent != "" {
		if val, err := strconv.ParseBool(consent); err == nil {
			filter.RequiresConsent = &val
		}
	}

	// Parse active status
	if active := c.Query("active"); active != "" {
		if val, err := strconv.ParseBool(active); err == nil {
			filter.IsActive = &val
		}
	} else {
		// Default to active only
		active := true
		filter.IsActive = &active
	}

	categories, err := h.repo.FindAll(filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to fetch categories",
		})
		return
	}

	// Convert to response format
	response := make([]models.CategoryResponse, len(categories))
	for i, cat := range categories {
		response[i] = cat.ToResponse()
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  response,
		"total": len(response),
	})
}

// Get godoc
// @Summary Get category by ID
// @Description Get a specific category by its ID
// @Tags categories
// @Accept json
// @Produce json
// @Param id path string true "Category ID"
// @Success 200 {object} models.CategoryResponse
// @Failure 404 {object} models.ErrorResponse
// @Router /categories/{id} [get]
func (h *CategoryHandler) Get(c *gin.Context) {
	id := c.Param("id")

	category, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "not_found",
			Message: "Category not found",
		})
		return
	}

	c.JSON(http.StatusOK, category.ToResponse())
}

// CreateCategoryRequest is the request body for creating a category.
type CreateCategoryRequest struct {
	Emoji           string                  `json:"emoji"`
	AgeGroup        string                  `json:"age_group" binding:"required"`
	Label           models.MultilingualText `json:"label" binding:"required"`
	RequiresConsent bool                    `json:"requires_consent"`
	SortOrder       int                     `json:"sort_order"`
	IsActive        bool                    `json:"is_active"`
}

// Create godoc
// @Summary Create category
// @Description Create a new category
// @Tags categories
// @Accept json
// @Produce json
// @Param category body CreateCategoryRequest true "Category data"
// @Success 201 {object} models.CategoryResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /categories [post]
func (h *CategoryHandler) Create(c *gin.Context) {
	var req CreateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
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

	// Set defaults
	if req.Emoji == "" {
		req.Emoji = "📝"
	}

	category := &models.Category{
		Emoji:           req.Emoji,
		AgeGroup:        req.AgeGroup,
		Label:           req.Label,
		RequiresConsent: req.RequiresConsent,
		IsActive:        true,
		SortOrder:       req.SortOrder,
	}

	if err := h.repo.Create(category); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to create category",
		})
		return
	}

	c.JSON(http.StatusCreated, category.ToResponse())
}

// Update godoc
// @Summary Update category
// @Description Update an existing category
// @Tags categories
// @Accept json
// @Produce json
// @Param id path string true "Category ID"
// @Param category body CreateCategoryRequest true "Category data"
// @Success 200 {object} models.CategoryResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /categories/{id} [put]
func (h *CategoryHandler) Update(c *gin.Context) {
	id := c.Param("id")

	category, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "not_found",
			Message: "Category not found",
		})
		return
	}

	var req CreateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	// Validate age group
	if req.AgeGroup != "" && !models.IsValidAgeGroup(req.AgeGroup) {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Invalid age group. Must be: kids, teen, or adults",
		})
		return
	}

	// Update fields
	if req.Emoji != "" {
		category.Emoji = req.Emoji
	}
	if req.AgeGroup != "" {
		category.AgeGroup = req.AgeGroup
	}
	if len(req.Label) > 0 {
		category.Label = req.Label
	}
	category.RequiresConsent = req.RequiresConsent
	category.SortOrder = req.SortOrder
	category.IsActive = req.IsActive

	if err := h.repo.Update(category); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to update category",
		})
		return
	}

	c.JSON(http.StatusOK, category.ToResponse())
}

// Delete godoc
// @Summary Delete category
// @Description Delete a category (soft delete)
// @Tags categories
// @Accept json
// @Produce json
// @Param id path string true "Category ID"
// @Success 200 {object} models.SuccessResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /categories/{id} [delete]
func (h *CategoryHandler) Delete(c *gin.Context) {
	id := c.Param("id")

	if _, err := h.repo.FindByID(id); err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "not_found",
			Message: "Category not found",
		})
		return
	}

	if err := h.repo.Delete(id); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to delete category",
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Category deleted successfully",
	})
}

// Count godoc
// @Summary Get category count
// @Description Get total count of categories with optional filters
// @Tags categories
// @Accept json
// @Produce json
// @Param age_groups query string false "Comma-separated age groups (kids,teen,adults)"
// @Param requires_consent query bool false "Filter by consent requirement"
// @Param active query bool false "Filter by active status"
// @Success 200 {object} map[string]interface{}
// @Failure 500 {object} models.ErrorResponse
// @Router /categories/count [get]
func (h *CategoryHandler) Count(c *gin.Context) {
	filter := &repository.CategoryFilter{}

	// Parse age_groups (comma-separated)
	if ageGroups := c.Query("age_groups"); ageGroups != "" {
		filter.AgeGroups = strings.Split(ageGroups, ",")
	}

	// Parse requires_consent
	if consent := c.Query("requires_consent"); consent != "" {
		if val, err := strconv.ParseBool(consent); err == nil {
			filter.RequiresConsent = &val
		}
	}

	// Parse active status
	if active := c.Query("active"); active != "" {
		if val, err := strconv.ParseBool(active); err == nil {
			filter.IsActive = &val
		}
	}

	count, err := h.repo.Count(filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "database_error",
			Message: "Failed to count categories",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"count": count,
	})
}
