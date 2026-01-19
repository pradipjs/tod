package models_test

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/truthordare/backend/internal/models"
)

func TestMultilingualText_JSON(t *testing.T) {
	t.Run("marshal to JSON", func(t *testing.T) {
		text := models.MultilingualText{
			"en": "Hello",
			"hi": "नमस्ते",
			"es": "Hola",
		}

		data, err := json.Marshal(text)
		require.NoError(t, err)

		var parsed map[string]string
		err = json.Unmarshal(data, &parsed)
		require.NoError(t, err)

		assert.Equal(t, "Hello", parsed["en"])
		assert.Equal(t, "नमस्ते", parsed["hi"])
		assert.Equal(t, "Hola", parsed["es"])
	})

	t.Run("unmarshal from JSON", func(t *testing.T) {
		jsonData := `{"en":"Hello","fr":"Bonjour"}`

		var text models.MultilingualText
		err := json.Unmarshal([]byte(jsonData), &text)
		require.NoError(t, err)

		assert.Equal(t, "Hello", text["en"])
		assert.Equal(t, "Bonjour", text["fr"])
	})
}

func TestMultilingualText_Value(t *testing.T) {
	text := models.MultilingualText{
		"en": "Test",
		"hi": "परीक्षण",
	}

	value, err := text.Value()
	require.NoError(t, err)

	var parsed map[string]string
	err = json.Unmarshal(value.([]byte), &parsed)
	require.NoError(t, err)
	assert.Equal(t, "Test", parsed["en"])
}

func TestMultilingualText_Scan(t *testing.T) {
	t.Run("scan from bytes", func(t *testing.T) {
		var text models.MultilingualText
		jsonBytes := []byte(`{"en":"Hello"}`)

		err := text.Scan(jsonBytes)
		require.NoError(t, err)
		assert.Equal(t, "Hello", text["en"])
	})

	t.Run("scan from nil", func(t *testing.T) {
		var text models.MultilingualText
		err := text.Scan(nil)
		require.NoError(t, err)
		// When scanning nil, it initializes an empty map
		assert.NotNil(t, text)
		assert.Empty(t, text)
	})
}

func TestIsValidAgeGroup(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"kids", true},
		{"teen", true},
		{"adults", true},
		{"KIDS", false},
		{"invalid", false},
		{"", false},
	}

	for _, test := range tests {
		t.Run(test.input, func(t *testing.T) {
			result := models.IsValidAgeGroup(test.input)
			assert.Equal(t, test.expected, result)
		})
	}
}

func TestIsValidLanguage(t *testing.T) {
	// Supported languages: "en", "zh", "es", "hi", "ar", "fr", "pt", "bn", "ru", "ur"
	tests := []struct {
		input    string
		expected bool
	}{
		{"en", true},
		{"hi", true},
		{"zh", true},
		{"es", true},
		{"fr", true},
		{"pt", true},
		{"bn", true},
		{"ru", true},
		{"ur", true},
		{"ar", true},
		{"gu", false}, // Gujarati not supported
		{"de", false}, // German not supported
		{"EN", false}, // Case-sensitive
		{"invalid", false},
		{"xyz", false},
		{"", false},
	}

	for _, test := range tests {
		t.Run(test.input, func(t *testing.T) {
			result := models.IsValidLanguage(test.input)
			assert.Equal(t, test.expected, result)
		})
	}
}

func TestGetMaxAgeForGroup(t *testing.T) {
	tests := []struct {
		group    string
		expected int
	}{
		{models.AgeGroupKids, 12},
		{models.AgeGroupTeen, 17},
		{models.AgeGroupAdults, 99},
		{"invalid", 99},
	}

	for _, test := range tests {
		t.Run(test.group, func(t *testing.T) {
			result := models.GetMaxAgeForGroup(test.group)
			assert.Equal(t, test.expected, result)
		})
	}
}

func TestGetMinAgeForGroup(t *testing.T) {
	tests := []struct {
		group    string
		expected int
	}{
		{models.AgeGroupKids, 0},
		{models.AgeGroupTeen, 13},
		{models.AgeGroupAdults, 18},
		{"invalid", 0},
	}

	for _, test := range tests {
		t.Run(test.group, func(t *testing.T) {
			result := models.GetMinAgeForGroup(test.group)
			assert.Equal(t, test.expected, result)
		})
	}
}

func TestCategory_ToResponse(t *testing.T) {
	category := &models.Category{
		BaseModel: models.BaseModel{ID: "test-id"},
		Label: models.MultilingualText{
			"en": "Test Category",
		},
		Emoji:           "🎯",
		AgeGroup:        models.AgeGroupKids,
		RequiresConsent: true,
		IsActive:        true,
		SortOrder:       5,
	}

	response := category.ToResponse()

	assert.Equal(t, "test-id", response.ID)
	assert.Equal(t, "Test Category", response.Label["en"])
	assert.Equal(t, "🎯", response.Emoji)
	assert.Equal(t, models.AgeGroupKids, response.AgeGroup)
	assert.True(t, response.RequiresConsent)
	assert.Equal(t, 5, response.SortOrder)
}

func TestTask_ToResponse(t *testing.T) {
	task := &models.Task{
		BaseModel:  models.BaseModel{ID: "task-id"},
		Text:       "Test task",
		Language:   "en",
		Type:       models.TaskTypeTruth,
		CategoryID: "cat-id",
	}

	response := task.ToResponse()

	assert.Equal(t, "task-id", response.ID)
	assert.Equal(t, "Test task", response.Text)
	assert.Equal(t, "en", response.Language)
	assert.Equal(t, models.TaskTypeTruth, response.Type)
	assert.Equal(t, "cat-id", response.CategoryID)
}

func TestConstants(t *testing.T) {
	assert.Equal(t, "truth", models.TaskTypeTruth)
	assert.Equal(t, "dare", models.TaskTypeDare)
	assert.Equal(t, "kids", models.AgeGroupKids)
	assert.Equal(t, "teen", models.AgeGroupTeen)
	assert.Equal(t, "adults", models.AgeGroupAdults)
}
