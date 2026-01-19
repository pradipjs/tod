package repository

import (
	"github.com/truthordare/backend/internal/models"
	"gorm.io/gorm"
)

// CategoryRepository handles category database operations.
type CategoryRepository struct {
	db *gorm.DB
}

// NewCategoryRepository creates a new CategoryRepository.
func NewCategoryRepository(db *gorm.DB) *CategoryRepository {
	return &CategoryRepository{db: db}
}

// CategoryFilter contains filter options for querying categories.
type CategoryFilter struct {
	AgeGroups       []string // Filter by age groups (kids, teen, adults)
	RequiresConsent *bool    // Filter by consent requirement
	IsActive        *bool    // Filter by active status
}

// FindAll retrieves all categories with optional filters.
func (r *CategoryRepository) FindAll(filter *CategoryFilter) ([]models.Category, error) {
	var categories []models.Category
	query := r.db.Model(&models.Category{})

	if filter != nil {
		if len(filter.AgeGroups) > 0 {
			query = query.Where("age_group IN ?", filter.AgeGroups)
		}

		if filter.RequiresConsent != nil {
			query = query.Where("requires_consent = ?", *filter.RequiresConsent)
		}

		if filter.IsActive != nil {
			query = query.Where("is_active = ?", *filter.IsActive)
		}
	}

	err := query.Order("sort_order ASC, created_at DESC").Find(&categories).Error
	return categories, err
}

// FindByID retrieves a category by ID.
func (r *CategoryRepository) FindByID(id string) (*models.Category, error) {
	var category models.Category
	err := r.db.First(&category, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

// Create creates a new category.
func (r *CategoryRepository) Create(category *models.Category) error {
	return r.db.Create(category).Error
}

// Update updates an existing category.
func (r *CategoryRepository) Update(category *models.Category) error {
	return r.db.Save(category).Error
}

// CountTasks returns the number of tasks in a category.
func (r *CategoryRepository) CountTasks(categoryID string) (int64, error) {
	var count int64
	err := r.db.Model(&models.Task{}).Where("category_id = ?", categoryID).Count(&count).Error
	return count, err
}

// Count returns the total number of categories matching the filter.
func (r *CategoryRepository) Count(filter *CategoryFilter) (int64, error) {
	var count int64
	query := r.db.Model(&models.Category{})

	if filter != nil {
		if len(filter.AgeGroups) > 0 {
			query = query.Where("age_group IN ?", filter.AgeGroups)
		}

		if filter.RequiresConsent != nil {
			query = query.Where("requires_consent = ?", *filter.RequiresConsent)
		}

		if filter.IsActive != nil {
			query = query.Where("is_active = ?", *filter.IsActive)
		}
	}

	err := query.Count(&count).Error
	return count, err
}

// ReorderItem represents a category ID and its new sort order.
type ReorderItem struct {
	ID        string `json:"id"`
	SortOrder int    `json:"sort_order"`
}

// Reorder updates the sort order of multiple categories in a transaction.
func (r *CategoryRepository) Reorder(items []ReorderItem) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		for _, item := range items {
			if err := tx.Model(&models.Category{}).Where("id = ?", item.ID).Update("sort_order", item.SortOrder).Error; err != nil {
				return err
			}
		}
		return nil
	})
}
