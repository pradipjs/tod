package database

import (
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/config"
	"github.com/truthordare/backend/internal/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Initialize creates a new database connection.
func Initialize(cfg *config.Config) (*gorm.DB, error) {
	dialector := sqlite.Open(cfg.DSN())

	// Configure GORM logger
	gormLogger := logger.Default.LogMode(logger.Silent)
	if cfg.IsDevelopment() {
		gormLogger = logger.Default.LogMode(logger.Info)
	}

	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: gormLogger,
	})
	if err != nil {
		return nil, err
	}

	log.Info().Msg("Database connection established")

	return db, nil
}

// Migrate runs database migrations.
func Migrate(db *gorm.DB) error {
	log.Info().Msg("Running database migrations")

	err := db.AutoMigrate(
		&models.Category{},
		&models.Task{},
	)
	if err != nil {
		return err
	}

	log.Info().Msg("Database migrations completed")
	return nil
}
