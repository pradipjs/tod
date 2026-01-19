package repository

import (
	"time"

	"github.com/truthordare/backend/internal/models"
	"gorm.io/gorm"
)

// TaskRepository handles task database operations.
type TaskRepository struct {
	db *gorm.DB
}

// NewTaskRepository creates a new TaskRepository.
func NewTaskRepository(db *gorm.DB) *TaskRepository {
	return &TaskRepository{db: db}
}

// TaskFilter contains filter options for querying tasks.
// Supports multiple values for categories, types, and languages.
type TaskFilter struct {
	CategoryID  string     // Filter by single category ID
	CategoryIDs []string   // Filter by multiple category IDs
	Type        string     // Filter by type (truth/dare)
	Types       []string   // Filter by multiple types
	Language    string     // Filter by single language code
	Languages   []string   // Filter by multiple language codes
	ExcludeIDs  []string   // Exclude specific task IDs (for rotation)
	FromDate    *time.Time // Filter tasks created after this date
	ToDate      *time.Time // Filter tasks created before this date
	SortBy      string     // Sort field (created_at, updated_at, etc.)
	SortOrder   string     // Sort order (asc, desc)
	Limit       int        // Limit results
	Offset      int        // Offset for pagination
	Random      bool       // Randomize results
}

// FindAll retrieves tasks with optional filters.
func (r *TaskRepository) FindAll(filter *TaskFilter) ([]models.Task, int64, error) {
	var tasks []models.Task
	var total int64

	query := r.db.Model(&models.Task{})

	if filter != nil {
		// Category filters
		if filter.CategoryID != "" {
			query = query.Where("category_id = ?", filter.CategoryID)
		}
		if len(filter.CategoryIDs) > 0 {
			query = query.Where("category_id IN ?", filter.CategoryIDs)
		}

		// Type filters
		if filter.Type != "" {
			query = query.Where("type = ?", filter.Type)
		}
		if len(filter.Types) > 0 {
			query = query.Where("type IN ?", filter.Types)
		}

		// Language filters
		if filter.Language != "" {
			query = query.Where("language = ?", filter.Language)
		}
		if len(filter.Languages) > 0 {
			query = query.Where("language IN ?", filter.Languages)
		}

		if len(filter.ExcludeIDs) > 0 {
			query = query.Where("id NOT IN ?", filter.ExcludeIDs)
		}

		// Date range filters
		if filter.FromDate != nil {
			query = query.Where("created_at >= ?", *filter.FromDate)
		}
		if filter.ToDate != nil {
			query = query.Where("created_at <= ?", *filter.ToDate)
		}
	}

	// Get total count before pagination
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// Apply ordering
	if filter != nil && filter.Random {
		query = query.Order("RANDOM()")
	} else if filter != nil && filter.SortBy != "" {
		// Validate sort field to prevent SQL injection
		validSortFields := map[string]bool{
			"created_at": true,
			"updated_at": true,
			"language":   true,
			"type":       true,
		}
		if validSortFields[filter.SortBy] {
			order := "DESC"
			if filter.SortOrder == "asc" {
				order = "ASC"
			}
			query = query.Order(filter.SortBy + " " + order)
		} else {
			query = query.Order("created_at DESC")
		}
	} else {
		query = query.Order("created_at DESC")
	}

	// Apply pagination
	if filter != nil {
		if filter.Limit > 0 {
			query = query.Limit(filter.Limit)
		}
		if filter.Offset > 0 {
			query = query.Offset(filter.Offset)
		}
	}

	err := query.Find(&tasks).Error
	return tasks, total, err
}

// FindByID retrieves a task by ID.
func (r *TaskRepository) FindByID(id string) (*models.Task, error) {
	var task models.Task
	err := r.db.First(&task, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &task, nil
}

// FindRandom retrieves a random task matching the filter.
func (r *TaskRepository) FindRandom(filter *TaskFilter) (*models.Task, error) {
	if filter == nil {
		filter = &TaskFilter{}
	}
	filter.Limit = 1
	filter.Random = true

	tasks, _, err := r.FindAll(filter)
	if err != nil {
		return nil, err
	}

	if len(tasks) == 0 {
		return nil, gorm.ErrRecordNotFound
	}

	return &tasks[0], nil
}

// CountByFilters returns the count of tasks matching the filters.
// Uses efficient COUNT queries instead of loading all records.
func (r *TaskRepository) CountByFilters(filter *TaskFilter) (truthCount, dareCount int64, err error) {
	// Build base query with filters (excluding type filter)
	buildQuery := func(taskType string) *gorm.DB {
		query := r.db.Model(&models.Task{}).Where("type = ?", taskType)

		if filter != nil {
			if filter.CategoryID != "" {
				query = query.Where("category_id = ?", filter.CategoryID)
			}
			if len(filter.CategoryIDs) > 0 {
				query = query.Where("category_id IN ?", filter.CategoryIDs)
			}
			if filter.Language != "" {
				query = query.Where("language = ?", filter.Language)
			}
			if len(filter.Languages) > 0 {
				query = query.Where("language IN ?", filter.Languages)
			}
			if len(filter.ExcludeIDs) > 0 {
				query = query.Where("id NOT IN ?", filter.ExcludeIDs)
			}
			if filter.FromDate != nil {
				query = query.Where("created_at >= ?", *filter.FromDate)
			}
			if filter.ToDate != nil {
				query = query.Where("created_at <= ?", *filter.ToDate)
			}
		}
		return query
	}

	// Count truths
	if err = buildQuery(models.TaskTypeTruth).Count(&truthCount).Error; err != nil {
		return 0, 0, err
	}

	// Count dares
	if err = buildQuery(models.TaskTypeDare).Count(&dareCount).Error; err != nil {
		return 0, 0, err
	}

	return truthCount, dareCount, nil
}

// Create creates a new task.
func (r *TaskRepository) Create(task *models.Task) error {
	return r.db.Create(task).Error
}

// CreateBatch creates multiple tasks.
func (r *TaskRepository) CreateBatch(tasks []models.Task) error {
	return r.db.CreateInBatches(tasks, 100).Error
}

// Update updates an existing task.
func (r *TaskRepository) Update(task *models.Task) error {
	return r.db.Save(task).Error
}

// Delete soft-deletes a task.
func (r *TaskRepository) Delete(id string) error {
	return r.db.Delete(&models.Task{}, "id = ?", id).Error
}

// CountByCategory returns task counts grouped by category.
func (r *TaskRepository) CountByCategory() (map[string]int64, error) {
	type Result struct {
		CategoryID string
		Count      int64
	}

	var results []Result
	err := r.db.Model(&models.Task{}).
		Select("category_id, count(*) as count").
		Group("category_id").
		Find(&results).Error

	if err != nil {
		return nil, err
	}

	counts := make(map[string]int64)
	for _, r := range results {
		counts[r.CategoryID] = r.Count
	}

	return counts, nil
}

// CountByType returns task counts grouped by type.
func (r *TaskRepository) CountByType() (map[string]int64, error) {
	type Result struct {
		Type  string
		Count int64
	}

	var results []Result
	err := r.db.Model(&models.Task{}).
		Select("type, count(*) as count").
		Group("type").
		Find(&results).Error

	if err != nil {
		return nil, err
	}

	counts := make(map[string]int64)
	for _, r := range results {
		counts[r.Type] = r.Count
	}

	return counts, nil
}

// Count returns the total count of tasks matching the filter.
func (r *TaskRepository) Count(filter *TaskFilter) (int64, error) {
	var count int64
	query := r.db.Model(&models.Task{})

	if filter != nil {
		// Category filters
		if filter.CategoryID != "" {
			query = query.Where("category_id = ?", filter.CategoryID)
		}
		if len(filter.CategoryIDs) > 0 {
			query = query.Where("category_id IN ?", filter.CategoryIDs)
		}

		// Type filters
		if filter.Type != "" {
			query = query.Where("type = ?", filter.Type)
		}
		if len(filter.Types) > 0 {
			query = query.Where("type IN ?", filter.Types)
		}

		// Language filters
		if filter.Language != "" {
			query = query.Where("language = ?", filter.Language)
		}
		if len(filter.Languages) > 0 {
			query = query.Where("language IN ?", filter.Languages)
		}

		// Date range filters
		if filter.FromDate != nil {
			query = query.Where("created_at >= ?", *filter.FromDate)
		}
		if filter.ToDate != nil {
			query = query.Where("created_at <= ?", *filter.ToDate)
		}
	}

	err := query.Count(&count).Error
	return count, err
}
