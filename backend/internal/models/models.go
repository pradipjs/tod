package models

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// MultilingualText represents text in multiple languages.
// Keys are ISO 639-1 language codes (en, zh, es, hi, ar, fr, pt, bn, ru, ur)
type MultilingualText map[string]string

// Value implements the driver.Valuer interface for database storage.
func (m MultilingualText) Value() (driver.Value, error) {
	return json.Marshal(m)
}

// Scan implements the sql.Scanner interface for database retrieval.
func (m *MultilingualText) Scan(value interface{}) error {
	if value == nil {
		*m = make(MultilingualText)
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("failed to unmarshal MultilingualText")
	}

	return json.Unmarshal(bytes, m)
}

// Get returns the text for a language with fallback to English.
func (m MultilingualText) Get(lang string) string {
	if text, ok := m[lang]; ok {
		return text
	}
	if text, ok := m["en"]; ok {
		return text
	}
	for _, text := range m {
		return text
	}
	return ""
}

// BaseModel contains common fields for all models.
type BaseModel struct {
	ID        string         `gorm:"type:varchar(36);primaryKey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// BeforeCreate generates a UUID for new records.
func (b *BaseModel) BeforeCreate(tx *gorm.DB) error {
	if b.ID == "" {
		b.ID = uuid.New().String()
	}
	return nil
}

// Category represents a question/task category.
// Schema: { id, emoji, agegroup, label: { en, es, hi, ur, ... } }
type Category struct {
	BaseModel
	Emoji           string           `gorm:"type:varchar(50);default:'📝'" json:"emoji"`
	AgeGroup        string           `gorm:"type:varchar(20);not null;index;default:'adults'" json:"age_group"`
	Label           MultilingualText `gorm:"type:json;not null" json:"label"`
	RequiresConsent bool             `gorm:"default:false;index" json:"requires_consent"`
	IsActive        bool             `gorm:"default:true;index" json:"is_active"`
	SortOrder       int              `gorm:"default:0;index" json:"sort_order"`
	Tasks           []Task           `gorm:"foreignKey:CategoryID" json:"-"`
}

// TableName returns the table name for Category.
func (Category) TableName() string {
	return "categories"
}

// StringArray is a custom type for storing string arrays in JSON.
type StringArray []string

// Value implements the driver.Valuer interface.
func (s StringArray) Value() (driver.Value, error) {
	return json.Marshal(s)
}

// Scan implements the sql.Scanner interface.
func (s *StringArray) Scan(value interface{}) error {
	if value == nil {
		*s = []string{}
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("failed to unmarshal StringArray")
	}

	return json.Unmarshal(bytes, s)
}

// Task represents a truth or dare task/question.
// Schema: { id, category_id, type (truth/dare), text: { en, es, hi, ... }, min_age }
type Task struct {
	BaseModel
	CategoryID      string           `gorm:"type:varchar(36);not null;index:idx_task_category" json:"category_id"`
	Category        *Category        `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
	Type            string           `gorm:"type:varchar(10);not null;index:idx_task_type" json:"type"` // "truth" or "dare"
	Text            MultilingualText `gorm:"type:json;not null" json:"text"`
	Hint            MultilingualText `gorm:"type:json" json:"hint,omitempty"`
	MinAge          int              `gorm:"default:0;index:idx_task_min_age" json:"min_age"`
	RequiresConsent bool             `gorm:"default:false" json:"requires_consent"`
	IsActive        bool             `gorm:"default:true;index:idx_task_active" json:"is_active"`
}

// TableName returns the table name for Task.
func (Task) TableName() string {
	return "tasks"
}

// TaskType constants.
const (
	TaskTypeTruth = "truth"
	TaskTypeDare  = "dare"
)

// AgeGroup constants.
const (
	AgeGroupKids   = "kids"
	AgeGroupTeen   = "teen"
	AgeGroupAdults = "adults"
)

// GetMinAgeForGroup returns minimum age for an age group.
func GetMinAgeForGroup(group string) int {
	switch group {
	case AgeGroupKids:
		return 0
	case AgeGroupTeen:
		return 13
	case AgeGroupAdults:
		return 18
	default:
		return 0
	}
}

// GetMaxAgeForGroup returns maximum age for an age group.
func GetMaxAgeForGroup(group string) int {
	switch group {
	case AgeGroupKids:
		return 12
	case AgeGroupTeen:
		return 17
	case AgeGroupAdults:
		return 99
	default:
		return 99
	}
}

// SupportedLanguages list of all supported language codes.
var SupportedLanguages = []string{"en", "zh", "es", "hi", "ar", "fr", "pt", "bn", "ru", "ur"}

// IsValidLanguage checks if a language code is supported.
func IsValidLanguage(code string) bool {
	for _, lang := range SupportedLanguages {
		if lang == code {
			return true
		}
	}
	return false
}

// IsValidAgeGroup checks if an age group is valid.
func IsValidAgeGroup(group string) bool {
	return group == AgeGroupKids || group == AgeGroupTeen || group == AgeGroupAdults
}

// IsValidTaskType checks if a task type is valid.
func IsValidTaskType(taskType string) bool {
	return taskType == TaskTypeTruth || taskType == TaskTypeDare
}

// ============ RESPONSE TYPES ============

// CategoryResponse is the API response format for a category.
type CategoryResponse struct {
	ID              string           `json:"id"`
	Emoji           string           `json:"emoji"`
	AgeGroup        string           `json:"age_group"`
	Label           MultilingualText `json:"label"`
	RequiresConsent bool             `json:"requires_consent"`
	IsActive        bool             `json:"is_active"`
	SortOrder       int              `json:"sort_order"`
	CreatedAt       string           `json:"created_at"`
	UpdatedAt       string           `json:"updated_at"`
}

// ToResponse converts a Category to CategoryResponse.
func (c *Category) ToResponse() CategoryResponse {
	return CategoryResponse{
		ID:              c.ID,
		Emoji:           c.Emoji,
		AgeGroup:        c.AgeGroup,
		Label:           c.Label,
		RequiresConsent: c.RequiresConsent,
		IsActive:        c.IsActive,
		SortOrder:       c.SortOrder,
		CreatedAt:       c.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:       c.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
}

// TaskResponse is the API response format for a task.
type TaskResponse struct {
	ID              string            `json:"id"`
	CategoryID      string            `json:"category_id"`
	Category        *CategoryResponse `json:"category,omitempty"`
	Type            string            `json:"type"`
	AgeGroup        string            `json:"age_group"`
	Text            MultilingualText  `json:"text"`
	Hint            MultilingualText  `json:"hint,omitempty"`
	RequiresConsent bool              `json:"requires_consent"`
	IsActive        bool              `json:"is_active"`
	CreatedAt       string            `json:"created_at"`
	UpdatedAt       string            `json:"updated_at"`
}

// ToResponse converts a Task to TaskResponse.
func (t *Task) ToResponse() TaskResponse {
	resp := TaskResponse{
		ID:              t.ID,
		CategoryID:      t.CategoryID,
		Type:            t.Type,
		AgeGroup:        GetAgeGroupForMinAge(t.MinAge),
		Text:            t.Text,
		Hint:            t.Hint,
		RequiresConsent: t.RequiresConsent,
		IsActive:        t.IsActive,
		CreatedAt:       t.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:       t.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
	if t.Category != nil {
		catResp := t.Category.ToResponse()
		resp.Category = &catResp
	}
	return resp
}

// GetAgeGroupForMinAge returns the age group for a given minimum age.
func GetAgeGroupForMinAge(minAge int) string {
	if minAge >= 18 {
		return AgeGroupAdults
	} else if minAge >= 13 {
		return AgeGroupTeen
	}
	return AgeGroupKids
}

// ErrorResponse is the standard error response format.
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
}

// SuccessResponse is the standard success response format.
type SuccessResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// HealthResponse is the health check response format.
type HealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version"`
}

// PaginatedResponse is a generic paginated response.
type PaginatedResponse[T any] struct {
	Data       []T   `json:"data"`
	Total      int64 `json:"total"`
	Page       int   `json:"page"`
	PageSize   int   `json:"page_size"`
	TotalPages int   `json:"total_pages"`
}
