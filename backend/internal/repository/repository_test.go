package repository_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/repository"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err, "failed to open test database")

	err = db.AutoMigrate(&models.Category{}, &models.Task{})
	require.NoError(t, err, "failed to migrate test database")

	return db
}

func TestCategoryRepository_Create(t *testing.T) {
	db := setupTestDB(t)
	repo := repository.NewCategoryRepository(db)

	category := &models.Category{
		Label: models.MultilingualText{
			"en": "Test Category",
			"hi": "परीक्षण",
		},
		Emoji:           "🎯",
		AgeGroup:        models.AgeGroupKids,
		RequiresConsent: false,
		IsActive:        true,
		SortOrder:       1,
	}

	err := repo.Create(category)
	require.NoError(t, err)
	assert.NotEmpty(t, category.ID)
	assert.NotZero(t, category.CreatedAt)
}

func TestCategoryRepository_FindByID(t *testing.T) {
	db := setupTestDB(t)
	repo := repository.NewCategoryRepository(db)

	category := &models.Category{
		Label:    models.MultilingualText{"en": "Test"},
		Emoji:    "🔍",
		AgeGroup: models.AgeGroupTeen,
		IsActive: true,
	}
	repo.Create(category)

	t.Run("find existing category", func(t *testing.T) {
		found, err := repo.FindByID(category.ID)
		require.NoError(t, err)
		assert.Equal(t, category.ID, found.ID)
		assert.Equal(t, "🔍", found.Emoji)
	})

	t.Run("find non-existent category", func(t *testing.T) {
		_, err := repo.FindByID("non-existent")
		assert.Error(t, err)
	})
}

func TestCategoryRepository_FindAll(t *testing.T) {
	db := setupTestDB(t)
	repo := repository.NewCategoryRepository(db)

	// Create 4 categories: 2 Kids (active), 1 Teen (active), 1 Adult (inactive)
	// Note: GORM has default:true for IsActive, so we create first then update to false
	cat1 := &models.Category{Label: models.MultilingualText{"en": "Kids 1"}, Emoji: "1️⃣", AgeGroup: models.AgeGroupKids, SortOrder: 1}
	cat2 := &models.Category{Label: models.MultilingualText{"en": "Kids 2"}, Emoji: "2️⃣", AgeGroup: models.AgeGroupKids, SortOrder: 2}
	cat3 := &models.Category{Label: models.MultilingualText{"en": "Teen"}, Emoji: "3️⃣", AgeGroup: models.AgeGroupTeen, SortOrder: 3}
	cat4 := &models.Category{Label: models.MultilingualText{"en": "Adult"}, Emoji: "4️⃣", AgeGroup: models.AgeGroupAdults, SortOrder: 4}

	repo.Create(cat1)
	repo.Create(cat2)
	repo.Create(cat3)
	repo.Create(cat4)

	// Update cat4 to be inactive (using raw update to bypass default)
	db.Model(cat4).Update("is_active", false)

	t.Run("find all without filter", func(t *testing.T) {
		result, err := repo.FindAll(nil)
		require.NoError(t, err)
		assert.Equal(t, 4, len(result))
	})

	t.Run("filter by age group", func(t *testing.T) {
		result, err := repo.FindAll(&repository.CategoryFilter{
			AgeGroups: []string{models.AgeGroupKids},
		})
		require.NoError(t, err)
		assert.Equal(t, 2, len(result))
		// Verify they are the right categories
		for _, cat := range result {
			assert.Equal(t, models.AgeGroupKids, cat.AgeGroup)
		}
	})

	t.Run("filter by active status true", func(t *testing.T) {
		active := true
		result, err := repo.FindAll(&repository.CategoryFilter{
			IsActive: &active,
		})
		require.NoError(t, err)
		// Should get only the 3 active categories
		assert.Equal(t, 3, len(result))
		for _, cat := range result {
			assert.True(t, cat.IsActive)
		}
	})

	t.Run("filter by active status false", func(t *testing.T) {
		active := false
		result, err := repo.FindAll(&repository.CategoryFilter{
			IsActive: &active,
		})
		require.NoError(t, err)
		// Should get only the 1 inactive category
		assert.Equal(t, 1, len(result))
		for _, cat := range result {
			assert.False(t, cat.IsActive)
		}
	})
}

func TestCategoryRepository_Update(t *testing.T) {
	db := setupTestDB(t)
	repo := repository.NewCategoryRepository(db)

	category := &models.Category{
		Label:    models.MultilingualText{"en": "Original"},
		Emoji:    "🔄",
		AgeGroup: models.AgeGroupKids,
		IsActive: true,
	}
	repo.Create(category)

	category.Label = models.MultilingualText{"en": "Updated"}
	category.Emoji = "✅"
	err := repo.Update(category)
	require.NoError(t, err)

	found, _ := repo.FindByID(category.ID)
	assert.Equal(t, "Updated", found.Label["en"])
	assert.Equal(t, "✅", found.Emoji)
}

func TestCategoryRepository_Delete(t *testing.T) {
	db := setupTestDB(t)
	repo := repository.NewCategoryRepository(db)

	category := &models.Category{
		Label:    models.MultilingualText{"en": "To Delete"},
		Emoji:    "🗑️",
		AgeGroup: models.AgeGroupKids,
		IsActive: true,
	}
	repo.Create(category)

	err := repo.Delete(category.ID)
	require.NoError(t, err)

	_, err = repo.FindByID(category.ID)
	assert.Error(t, err)
}

func TestCategoryRepository_Count(t *testing.T) {
	db := setupTestDB(t)
	repo := repository.NewCategoryRepository(db)

	// Create 2 active, 1 inactive
	cat1 := &models.Category{Label: models.MultilingualText{"en": "1"}, Emoji: "1️⃣", AgeGroup: models.AgeGroupKids}
	cat2 := &models.Category{Label: models.MultilingualText{"en": "2"}, Emoji: "2️⃣", AgeGroup: models.AgeGroupKids}
	cat3 := &models.Category{Label: models.MultilingualText{"en": "3"}, Emoji: "3️⃣", AgeGroup: models.AgeGroupTeen}

	repo.Create(cat1)
	repo.Create(cat2)
	repo.Create(cat3)

	// Set cat3 to inactive (bypasses GORM default)
	db.Model(cat3).Update("is_active", false)

	t.Run("count all", func(t *testing.T) {
		count, err := repo.Count(nil)
		require.NoError(t, err)
		assert.Equal(t, int64(3), count)
	})

	t.Run("count active only", func(t *testing.T) {
		active := true
		count, err := repo.Count(&repository.CategoryFilter{IsActive: &active})
		require.NoError(t, err)
		assert.Equal(t, int64(2), count)
	})

	t.Run("count inactive only", func(t *testing.T) {
		inactive := false
		count, err := repo.Count(&repository.CategoryFilter{IsActive: &inactive})
		require.NoError(t, err)
		assert.Equal(t, int64(1), count)
	})
}

func TestTaskRepository_Create(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{
		Label:    models.MultilingualText{"en": "Test"},
		Emoji:    "📝",
		AgeGroup: models.AgeGroupKids,
		IsActive: true,
	}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)
	task := &models.Task{
		Text: models.MultilingualText{
			"en": "What is your name?",
		},
		Type:            models.TaskTypeTruth,
		CategoryID:      category.ID,
		MinAge:          0,
		RequiresConsent: false,
		IsActive:        true,
	}

	err := taskRepo.Create(task)
	require.NoError(t, err)
	assert.NotEmpty(t, task.ID)
}

func TestTaskRepository_FindByID(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{Label: models.MultilingualText{"en": "Test"}, Emoji: "📝", AgeGroup: models.AgeGroupKids, IsActive: true}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)
	task := &models.Task{
		Text:       models.MultilingualText{"en": "Test task"},
		Type:       models.TaskTypeDare,
		CategoryID: category.ID,
		IsActive:   true,
	}
	taskRepo.Create(task)

	t.Run("find existing task", func(t *testing.T) {
		found, err := taskRepo.FindByID(task.ID)
		require.NoError(t, err)
		assert.Equal(t, task.ID, found.ID)
		assert.Equal(t, models.TaskTypeDare, found.Type)
	})

	t.Run("find non-existent task", func(t *testing.T) {
		_, err := taskRepo.FindByID("non-existent")
		assert.Error(t, err)
	})
}

func TestTaskRepository_FindAll(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{Label: models.MultilingualText{"en": "Test"}, Emoji: "📝", AgeGroup: models.AgeGroupKids}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)

	task1 := &models.Task{Text: models.MultilingualText{"en": "Truth 1"}, Type: models.TaskTypeTruth, CategoryID: category.ID, MinAge: 0}
	task2 := &models.Task{Text: models.MultilingualText{"en": "Truth 2"}, Type: models.TaskTypeTruth, CategoryID: category.ID, MinAge: 13}
	task3 := &models.Task{Text: models.MultilingualText{"en": "Dare 1"}, Type: models.TaskTypeDare, CategoryID: category.ID, MinAge: 0}
	task4 := &models.Task{Text: models.MultilingualText{"en": "Dare 2"}, Type: models.TaskTypeDare, CategoryID: category.ID, MinAge: 18}

	taskRepo.Create(task1)
	taskRepo.Create(task2)
	taskRepo.Create(task3)
	taskRepo.Create(task4)

	// Set task4 to inactive (bypasses GORM default)
	db.Model(task4).Update("is_active", false)

	t.Run("find all without filter", func(t *testing.T) {
		result, total, err := taskRepo.FindAll(nil)
		require.NoError(t, err)
		assert.Equal(t, 4, len(result))
		assert.Equal(t, int64(4), total)
	})

	t.Run("filter by type", func(t *testing.T) {
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			Type: models.TaskTypeTruth,
		})
		require.NoError(t, err)
		assert.Equal(t, 2, len(result))
	})

	t.Run("filter by category", func(t *testing.T) {
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			CategoryID: category.ID,
		})
		require.NoError(t, err)
		assert.Equal(t, 4, len(result))
	})

	t.Run("filter by active status", func(t *testing.T) {
		active := true
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			IsActive: &active,
		})
		require.NoError(t, err)
		assert.Equal(t, 3, len(result))
	})

	t.Run("filter by min age", func(t *testing.T) {
		minAge := 13
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			MinAge: &minAge,
		})
		require.NoError(t, err)
		assert.Equal(t, 3, len(result))
	})

	t.Run("pagination", func(t *testing.T) {
		result, total, err := taskRepo.FindAll(&repository.TaskFilter{
			Limit:  2,
			Offset: 0,
		})
		require.NoError(t, err)
		assert.Equal(t, 2, len(result))
		assert.Equal(t, int64(4), total)
	})

	t.Run("sort by min_age ascending", func(t *testing.T) {
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			SortBy:    "min_age",
			SortOrder: "asc",
		})
		require.NoError(t, err)
		assert.Equal(t, 0, result[0].MinAge)
	})
}

func TestTaskRepository_FindRandom(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{Label: models.MultilingualText{"en": "Test"}, Emoji: "🎲", AgeGroup: models.AgeGroupKids, IsActive: true}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)

	for i := 0; i < 5; i++ {
		taskRepo.Create(&models.Task{
			Text:       models.MultilingualText{"en": "Task"},
			Type:       models.TaskTypeTruth,
			CategoryID: category.ID,
			IsActive:   true,
		})
	}

	t.Run("get random task", func(t *testing.T) {
		task, err := taskRepo.FindRandom(&repository.TaskFilter{
			Type: models.TaskTypeTruth,
		})
		require.NoError(t, err)
		assert.NotNil(t, task)
		assert.Equal(t, models.TaskTypeTruth, task.Type)
	})

	t.Run("no matching task", func(t *testing.T) {
		_, err := taskRepo.FindRandom(&repository.TaskFilter{
			Type: models.TaskTypeDare,
		})
		assert.Error(t, err)
	})
}

func TestTaskRepository_CountByFilters(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{Label: models.MultilingualText{"en": "Test"}, Emoji: "📊", AgeGroup: models.AgeGroupKids, IsActive: true}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)

	for i := 0; i < 3; i++ {
		taskRepo.Create(&models.Task{
			Text:       models.MultilingualText{"en": "Truth"},
			Type:       models.TaskTypeTruth,
			CategoryID: category.ID,
			IsActive:   true,
		})
	}
	for i := 0; i < 2; i++ {
		taskRepo.Create(&models.Task{
			Text:       models.MultilingualText{"en": "Dare"},
			Type:       models.TaskTypeDare,
			CategoryID: category.ID,
			IsActive:   true,
		})
	}

	truthCount, dareCount, err := taskRepo.CountByFilters(&repository.TaskFilter{
		CategoryID: category.ID,
	})
	require.NoError(t, err)
	assert.Equal(t, int64(3), truthCount)
	assert.Equal(t, int64(2), dareCount)
}

func TestTaskRepository_DateFilters(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{Label: models.MultilingualText{"en": "Test"}, Emoji: "📅", AgeGroup: models.AgeGroupKids, IsActive: true}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)

	task := &models.Task{
		Text:       models.MultilingualText{"en": "Task"},
		Type:       models.TaskTypeTruth,
		CategoryID: category.ID,
		IsActive:   true,
	}
	taskRepo.Create(task)

	now := time.Now()
	yesterday := now.Add(-24 * time.Hour)
	tomorrow := now.Add(24 * time.Hour)

	t.Run("filter from date", func(t *testing.T) {
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			FromDate: &yesterday,
		})
		require.NoError(t, err)
		assert.Equal(t, 1, len(result))
	})

	t.Run("filter to date in past excludes task", func(t *testing.T) {
		pastDate := now.Add(-48 * time.Hour)
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			ToDate: &pastDate,
		})
		require.NoError(t, err)
		assert.Equal(t, 0, len(result))
	})

	t.Run("filter date range", func(t *testing.T) {
		result, _, err := taskRepo.FindAll(&repository.TaskFilter{
			FromDate: &yesterday,
			ToDate:   &tomorrow,
		})
		require.NoError(t, err)
		assert.Equal(t, 1, len(result))
	})
}

func TestTaskRepository_Update(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{Label: models.MultilingualText{"en": "Test"}, Emoji: "📝", AgeGroup: models.AgeGroupKids, IsActive: true}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)
	task := &models.Task{
		Text:       models.MultilingualText{"en": "Original"},
		Type:       models.TaskTypeTruth,
		CategoryID: category.ID,
		IsActive:   true,
	}
	taskRepo.Create(task)

	task.Text = models.MultilingualText{"en": "Updated"}
	err := taskRepo.Update(task)
	require.NoError(t, err)

	found, _ := taskRepo.FindByID(task.ID)
	assert.Equal(t, "Updated", found.Text["en"])
}

func TestTaskRepository_Delete(t *testing.T) {
	db := setupTestDB(t)

	categoryRepo := repository.NewCategoryRepository(db)
	category := &models.Category{Label: models.MultilingualText{"en": "Test"}, Emoji: "🗑️", AgeGroup: models.AgeGroupKids, IsActive: true}
	categoryRepo.Create(category)

	taskRepo := repository.NewTaskRepository(db)
	task := &models.Task{
		Text:       models.MultilingualText{"en": "To Delete"},
		Type:       models.TaskTypeTruth,
		CategoryID: category.ID,
		IsActive:   true,
	}
	taskRepo.Create(task)

	err := taskRepo.Delete(task.ID)
	require.NoError(t, err)

	_, err = taskRepo.FindByID(task.ID)
	assert.Error(t, err)
}
