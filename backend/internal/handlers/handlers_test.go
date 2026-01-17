package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/truthordare/backend/internal/handlers"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/repository"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// setupTestDB creates an in-memory SQLite database for testing
func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err, "failed to open test database")

	err = db.AutoMigrate(&models.Category{}, &models.Task{})
	require.NoError(t, err, "failed to migrate test database")

	return db
}

// setupTestRouter creates a Gin router for testing
func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	return gin.New()
}

// seedTestCategory creates a test category in the database
func seedTestCategory(t *testing.T, db *gorm.DB) *models.Category {
	category := &models.Category{
		Label: models.MultilingualText{
			"en": "Test Category",
			"hi": "परीक्षण श्रेणी",
		},
		Emoji:           "🧪",
		AgeGroup:        models.AgeGroupKids,
		RequiresConsent: false,
		IsActive:        true,
		SortOrder:       1,
	}
	err := db.Create(category).Error
	require.NoError(t, err, "failed to create test category")
	return category
}

// seedTestTask creates a test task in the database
func seedTestTask(t *testing.T, db *gorm.DB, categoryID string, taskType string) *models.Task {
	task := &models.Task{
		Text: models.MultilingualText{
			"en": "Test task text",
			"hi": "परीक्षण कार्य पाठ",
		},
		Type:            taskType,
		CategoryID:      categoryID,
		MinAge:          0,
		RequiresConsent: false,
		IsActive:        true,
	}
	err := db.Create(task).Error
	require.NoError(t, err, "failed to create test task")
	return task
}

func TestCategoryHandler_List(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	seedTestCategory(t, db)

	category2 := &models.Category{
		Label:     models.MultilingualText{"en": "Teen Category"},
		Emoji:     "🔥",
		AgeGroup:  models.AgeGroupTeen,
		IsActive:  true,
		SortOrder: 2,
	}
	db.Create(category2)

	categoryRepo := repository.NewCategoryRepository(db)
	handler := handlers.NewCategoryHandler(categoryRepo)

	router.GET("/categories", handler.List)

	t.Run("list all categories", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/categories", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response struct {
			Data  []models.CategoryResponse `json:"data"`
			Total int64                     `json:"total"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, 2, len(response.Data))
		assert.Equal(t, int64(2), response.Total)
	})

	t.Run("filter by age group", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/categories?age_groups=kids", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response struct {
			Data []models.CategoryResponse `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, 1, len(response.Data))
		assert.Equal(t, "🧪", response.Data[0].Emoji)
	})
}

func TestCategoryHandler_GetByID(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	category := seedTestCategory(t, db)

	categoryRepo := repository.NewCategoryRepository(db)
	handler := handlers.NewCategoryHandler(categoryRepo)

	router.GET("/categories/:id", handler.Get)

	t.Run("get existing category", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/categories/"+category.ID, nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.CategoryResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, category.ID, response.ID)
		assert.Equal(t, "🧪", response.Emoji)
	})

	t.Run("get non-existent category", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/categories/non-existent-id", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

func TestCategoryHandler_Create(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	categoryRepo := repository.NewCategoryRepository(db)
	handler := handlers.NewCategoryHandler(categoryRepo)

	router.POST("/categories", handler.Create)

	t.Run("create valid category", func(t *testing.T) {
		reqBody := map[string]interface{}{
			"label": map[string]string{
				"en": "New Category",
			},
			"emoji":     "✨",
			"age_group": "adults",
		}
		body, _ := json.Marshal(reqBody)

		req, _ := http.NewRequest("POST", "/categories", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response models.CategoryResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, "✨", response.Emoji)
		assert.Equal(t, "adults", response.AgeGroup)
	})

	t.Run("create category without label", func(t *testing.T) {
		reqBody := map[string]interface{}{
			"emoji":     "❌",
			"age_group": "kids",
		}
		body, _ := json.Marshal(reqBody)

		req, _ := http.NewRequest("POST", "/categories", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

func TestCategoryHandler_Update(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	category := seedTestCategory(t, db)

	categoryRepo := repository.NewCategoryRepository(db)
	handler := handlers.NewCategoryHandler(categoryRepo)

	router.PUT("/categories/:id", handler.Update)

	t.Run("update existing category", func(t *testing.T) {
		reqBody := map[string]interface{}{
			"label": map[string]string{
				"en": "Updated Category",
			},
			"emoji":     "🎉",
			"age_group": "kids", // Required field
		}
		body, _ := json.Marshal(reqBody)

		req, _ := http.NewRequest("PUT", "/categories/"+category.ID, bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.CategoryResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, "🎉", response.Emoji)
		assert.Equal(t, "Updated Category", response.Label["en"])
	})

	t.Run("update non-existent category", func(t *testing.T) {
		reqBody := map[string]interface{}{"emoji": "❓"}
		body, _ := json.Marshal(reqBody)

		req, _ := http.NewRequest("PUT", "/categories/non-existent-id", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

func TestCategoryHandler_Delete(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	category := seedTestCategory(t, db)

	categoryRepo := repository.NewCategoryRepository(db)
	handler := handlers.NewCategoryHandler(categoryRepo)

	router.DELETE("/categories/:id", handler.Delete)

	t.Run("delete existing category", func(t *testing.T) {
		req, _ := http.NewRequest("DELETE", "/categories/"+category.ID, nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// Handler returns 200 with success message, not 204
		assert.Equal(t, http.StatusOK, w.Code)

		var count int64
		db.Model(&models.Category{}).Where("id = ?", category.ID).Count(&count)
		assert.Equal(t, int64(0), count)
	})
}

func TestCategoryHandler_Count(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	seedTestCategory(t, db)
	db.Create(&models.Category{
		Label:    models.MultilingualText{"en": "Category 2"},
		Emoji:    "📦",
		AgeGroup: models.AgeGroupTeen,
	})
	inactiveCat := &models.Category{
		Label:    models.MultilingualText{"en": "Inactive"},
		Emoji:    "❌",
		AgeGroup: models.AgeGroupAdults,
	}
	db.Create(inactiveCat)
	// Update to inactive (bypasses GORM default)
	db.Model(inactiveCat).Update("is_active", false)

	categoryRepo := repository.NewCategoryRepository(db)
	handler := handlers.NewCategoryHandler(categoryRepo)

	router.GET("/categories/count", handler.Count)

	t.Run("count all categories", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/categories/count", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]int64
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, int64(3), response["count"])
	})

	t.Run("count active only", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/categories/count?active=true", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]int64
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, int64(2), response["count"])
	})
}

func TestTaskHandler_List(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	category := seedTestCategory(t, db)
	seedTestTask(t, db, category.ID, models.TaskTypeTruth)
	seedTestTask(t, db, category.ID, models.TaskTypeDare)

	categoryRepo := repository.NewCategoryRepository(db)
	taskRepo := repository.NewTaskRepository(db)
	handler := handlers.NewTaskHandler(taskRepo, categoryRepo)

	router.GET("/tasks", handler.List)

	t.Run("list all tasks", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response struct {
			Data  []models.TaskResponse `json:"data"`
			Total int64                 `json:"total"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, 2, len(response.Data))
	})

	t.Run("filter by type", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks?type=truth", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response struct {
			Data []models.TaskResponse `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, 1, len(response.Data))
		assert.Equal(t, "truth", response.Data[0].Type)
	})

	t.Run("filter by category", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks?category_id="+category.ID, nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response struct {
			Data []models.TaskResponse `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, 2, len(response.Data))
	})
}

func TestTaskHandler_Create(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	category := seedTestCategory(t, db)

	categoryRepo := repository.NewCategoryRepository(db)
	taskRepo := repository.NewTaskRepository(db)
	handler := handlers.NewTaskHandler(taskRepo, categoryRepo)

	router.POST("/tasks", handler.Create)

	t.Run("create valid task", func(t *testing.T) {
		reqBody := map[string]interface{}{
			"text": map[string]string{
				"en": "What is your favorite color?",
			},
			"type":        "truth",
			"category_id": category.ID,
			"min_age":     0,
			"intensity":   1,
		}
		body, _ := json.Marshal(reqBody)

		req, _ := http.NewRequest("POST", "/tasks", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response models.TaskResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, "truth", response.Type)
		assert.Equal(t, category.ID, response.CategoryID)
	})

	t.Run("create task with non-existent category", func(t *testing.T) {
		reqBody := map[string]interface{}{
			"text": map[string]string{
				"en": "Invalid task",
			},
			"type":        "truth",
			"category_id": "non-existent-category",
		}
		body, _ := json.Marshal(reqBody)

		req, _ := http.NewRequest("POST", "/tasks", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)

		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, "validation_error", response.Error)
		assert.Contains(t, response.Message, "Category not found")
	})

	t.Run("create task without required fields", func(t *testing.T) {
		reqBody := map[string]interface{}{
			"type": "truth",
		}
		body, _ := json.Marshal(reqBody)

		req, _ := http.NewRequest("POST", "/tasks", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

func TestTaskHandler_GetRandom(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	category := seedTestCategory(t, db)
	seedTestTask(t, db, category.ID, models.TaskTypeTruth)
	seedTestTask(t, db, category.ID, models.TaskTypeTruth)
	seedTestTask(t, db, category.ID, models.TaskTypeDare)

	categoryRepo := repository.NewCategoryRepository(db)
	taskRepo := repository.NewTaskRepository(db)
	handler := handlers.NewTaskHandler(taskRepo, categoryRepo)

	router.GET("/tasks/random", handler.GetRandom)

	t.Run("get random task", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks/random?category_id="+category.ID, nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.TaskResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, category.ID, response.CategoryID)
	})

	t.Run("get random truth", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks/random?type=truth", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.TaskResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, "truth", response.Type)
	})
}

func TestTaskHandler_Count(t *testing.T) {
	db := setupTestDB(t)
	router := setupTestRouter()

	category := seedTestCategory(t, db)
	seedTestTask(t, db, category.ID, models.TaskTypeTruth)
	seedTestTask(t, db, category.ID, models.TaskTypeTruth)
	seedTestTask(t, db, category.ID, models.TaskTypeDare)

	inactiveTask := &models.Task{
		Text:       models.MultilingualText{"en": "Inactive"},
		Type:       models.TaskTypeTruth,
		CategoryID: category.ID,
	}
	db.Create(inactiveTask)
	// Update to inactive (bypasses GORM default)
	db.Model(inactiveTask).Update("is_active", false)

	categoryRepo := repository.NewCategoryRepository(db)
	taskRepo := repository.NewTaskRepository(db)
	handler := handlers.NewTaskHandler(taskRepo, categoryRepo)

	router.GET("/tasks/count", handler.Count)

	t.Run("count all tasks", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks/count", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]int64
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, int64(4), response["count"])
	})

	t.Run("count active only", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks/count?active=true", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]int64
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, int64(3), response["count"])
	})

	t.Run("count by type", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/tasks/count?type=truth", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]int64
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, int64(3), response["count"])
	})
}
