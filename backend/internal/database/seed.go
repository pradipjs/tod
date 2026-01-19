package database

import (
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/models"
	"gorm.io/gorm"
)

// Seed populates the database with initial data.
func Seed(db *gorm.DB) error {
	// Check if data already exists
	var count int64
	db.Model(&models.Category{}).Count(&count)
	if count > 0 {
		log.Info().Msg("Database already seeded, skipping")
		return nil
	}

	log.Info().Msg("Seeding database with initial data")

	// Use transaction for atomic seeding
	return db.Transaction(func(tx *gorm.DB) error {
		// Seed categories first
		categories := getInitialCategories()
		for _, cat := range categories {
			if err := tx.Create(&cat).Error; err != nil {
				log.Error().Err(err).Str("category", cat.ID).Msg("Failed to create category")
				return err
			}
		}

		// Get the first category for seeding tasks
		var firstCategory models.Category
		if err := tx.First(&firstCategory).Error; err != nil {
			log.Error().Err(err).Msg("Failed to get first category for tasks")
			return err
		}

		// Seed tasks with proper category ID
		tasks := getInitialTasks(firstCategory.ID)
		for _, task := range tasks {
			if err := tx.Create(&task).Error; err != nil {
				log.Error().Err(err).Str("task", task.ID).Msg("Failed to create task")
				return err
			}
		}

		log.Info().
			Int("categories", len(categories)).
			Int("tasks", len(tasks)).
			Msg("Database seeding completed")

		return nil
	})
}

func getInitialCategories() []models.Category {
	return []models.Category{
		{
			BaseModel: models.BaseModel{ID: uuid.New().String()},
			Label: models.MultilingualText{
				"en": "Getting to Know You",
				"hi": "आपको जानना",
				"ar": "التعرف عليك",
			},
			Emoji:           "👋",
			AgeGroup:        models.AgeGroupKids,
			RequiresConsent: false,
			IsActive:        true,
			SortOrder:       1,
		},
		{
			BaseModel: models.BaseModel{ID: uuid.New().String()},
			Label: models.MultilingualText{
				"en": "Funny",
				"hi": "मजेदार",
				"ar": "مضحك",
			},
			Emoji:           "😂",
			AgeGroup:        models.AgeGroupKids,
			RequiresConsent: false,
			IsActive:        true,
			SortOrder:       2,
		},
		{
			BaseModel: models.BaseModel{ID: uuid.New().String()},
			Label: models.MultilingualText{
				"en": "Embarrassing",
				"hi": "शर्मनाक",
				"ar": "محرج",
			},
			Emoji:           "😳",
			AgeGroup:        models.AgeGroupTeen,
			RequiresConsent: false,
			IsActive:        true,
			SortOrder:       3,
		},
		{
			BaseModel: models.BaseModel{ID: uuid.New().String()},
			Label: models.MultilingualText{
				"en": "Adventure",
				"hi": "साहसिक",
				"ar": "مغامرة",
			},
			Emoji:           "🏔️",
			AgeGroup:        models.AgeGroupKids,
			RequiresConsent: false,
			IsActive:        true,
			SortOrder:       4,
		},
		{
			BaseModel: models.BaseModel{ID: uuid.New().String()},
			Label: models.MultilingualText{
				"en": "Romantic",
				"hi": "रोमांटिक",
				"ar": "رومانسي",
			},
			Emoji:           "❤️",
			AgeGroup:        models.AgeGroupAdults,
			RequiresConsent: false,
			IsActive:        true,
			SortOrder:       5,
		},
		{
			BaseModel: models.BaseModel{ID: uuid.New().String()},
			Label: models.MultilingualText{
				"en": "Spicy",
				"hi": "तीखा",
				"ar": "حار",
			},
			Emoji:           "🔥",
			AgeGroup:        models.AgeGroupAdults,
			RequiresConsent: true,
			IsActive:        true,
			SortOrder:       6,
		},
	}
}

func getInitialTasks(categoryID string) []models.Task {
	return []models.Task{
		{
			BaseModel:  models.BaseModel{ID: uuid.New().String()},
			Text:       "What is your favorite movie?",
			Type:       models.TaskTypeTruth,
			CategoryID: categoryID,
			Language:   "en",
		},
		{
			BaseModel:  models.BaseModel{ID: uuid.New().String()},
			Text:       "Do 10 jumping jacks",
			Type:       models.TaskTypeDare,
			CategoryID: categoryID,
			Language:   "en",
		},
		{
			BaseModel:  models.BaseModel{ID: uuid.New().String()},
			Text:       "What is your most embarrassing moment?",
			Type:       models.TaskTypeTruth,
			CategoryID: categoryID,
			Language:   "en",
		},
		{
			BaseModel:  models.BaseModel{ID: uuid.New().String()},
			Text:       "Who was your first crush?",
			Type:       models.TaskTypeTruth,
			CategoryID: categoryID,
			Language:   "en",
		},
	}
}
