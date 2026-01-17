package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/truthordare/backend/internal/ai"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/prompts"
)

// GenerateCategoryLabelsHandler handles AI-based category label generation
type GenerateCategoryLabelsHandler struct {
	aiClient     *ai.Client
	promptLoader *prompts.PromptLoader
}

// NewGenerateCategoryLabelsHandler creates a new handler instance
func NewGenerateCategoryLabelsHandler() *GenerateCategoryLabelsHandler {
	return &GenerateCategoryLabelsHandler{
		aiClient:     ai.GetClient(),
		promptLoader: prompts.GetLoader(),
	}
}

// GenerateCategoryLabelsRequest represents the request body
type GenerateCategoryLabelsRequest struct {
	// CategoryName is the English name of the category to translate
	CategoryName string `json:"category_name" binding:"required"`
	// Languages is an optional list of language codes to translate to
	// If empty, all supported languages will be used
	Languages []string `json:"languages,omitempty"`
}

// GenerateCategoryLabelsResponse represents the response body
type GenerateCategoryLabelsResponse struct {
	Success bool                    `json:"success"`
	Labels  models.MultilingualText `json:"labels"`
}

// SupportedLanguages returns the list of supported language codes
var SupportedLanguages = []string{"en", "zh", "es", "hi", "ar", "fr", "pt", "bn", "ru", "ur"}

// GenerateCategoryLabels godoc
// @Summary Generate category labels using AI
// @Description Generate multilingual labels for a category name using AI translation
// @Tags generate
// @Accept json
// @Produce json
// @Param request body GenerateCategoryLabelsRequest true "Category name and optional languages"
// @Success 200 {object} GenerateCategoryLabelsResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /generate/category-labels [post]
func (h *GenerateCategoryLabelsHandler) GenerateCategoryLabels(c *gin.Context) {
	var req GenerateCategoryLabelsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	// Validate category name
	req.CategoryName = strings.TrimSpace(req.CategoryName)
	if req.CategoryName == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Category name is required",
		})
		return
	}

	// Use default languages if not specified
	languages := req.Languages
	if len(languages) == 0 {
		languages = SupportedLanguages
	}

	// Validate languages
	for _, lang := range languages {
		if !isValidLanguage(lang) {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "validation_error",
				Message: "Invalid language code: " + lang,
			})
			return
		}
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
	prompt, err := h.promptLoader.LoadAndReplace(
		"category_labels",
		prompts.P("CATEGORY_NAME", req.CategoryName),
		prompts.P("LANGUAGES", strings.Join(languages, ", ")),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to load prompt template: " + err.Error(),
		})
		return
	}

	// Call AI to generate labels
	messages := []ai.Message{
		{Role: "user", Content: prompt},
	}

	var labels models.MultilingualText
	err = h.aiClient.CompleteJSON(messages, &labels,
		ai.WithTemperature(0.3), // Lower temperature for more consistent translations
		ai.WithMaxTokens(500),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "ai_error",
			Message: "Failed to generate labels: " + err.Error(),
		})
		return
	}

	// Ensure English label is set to original if not provided
	if labels["en"] == "" {
		labels["en"] = req.CategoryName
	}

	c.JSON(http.StatusOK, GenerateCategoryLabelsResponse{
		Success: true,
		Labels:  labels,
	})
}

// isValidLanguage checks if a language code is supported
func isValidLanguage(lang string) bool {
	for _, supported := range SupportedLanguages {
		if lang == supported {
			return true
		}
	}
	return false
}
