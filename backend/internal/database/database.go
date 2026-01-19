package database

import (
	"os"
	"path/filepath"

	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/config"
	"github.com/truthordare/backend/internal/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Initialize creates a new database connection.
func Initialize(cfg *config.Config) (*gorm.DB, error) {
	dbPath := cfg.DSN()
	log.Info().Str("db_path", dbPath).Msg("Initializing database")

	// Ensure the directory exists for the database file
	dbDir := filepath.Dir(dbPath)
	if dbDir != "." && dbDir != "" {
		log.Info().Str("db_dir", dbDir).Msg("Ensuring database directory exists")
		if err := os.MkdirAll(dbDir, 0755); err != nil {
			log.Error().Err(err).Str("db_dir", dbDir).Msg("Failed to create database directory")
			return nil, err
		}
		// Log directory info
		if info, err := os.Stat(dbDir); err == nil {
			log.Info().Str("db_dir", dbDir).Str("mode", info.Mode().String()).Msg("Database directory ready")
		}
	}

	dialector := sqlite.Open(dbPath)

	// Configure GORM logger
	gormLogger := logger.Default.LogMode(logger.Silent)
	if cfg.IsDevelopment() {
		gormLogger = logger.Default.LogMode(logger.Info)
	}

	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: gormLogger,
	})
	if err != nil {
		log.Error().Err(err).Str("db_path", dbPath).Msg("Failed to open database")
		return nil, err
	}

	// Verify database file exists after connection
	if info, err := os.Stat(dbPath); err == nil {
		log.Info().Str("db_path", dbPath).Int64("size", info.Size()).Msg("Database file created/opened")
	} else {
		log.Warn().Err(err).Str("db_path", dbPath).Msg("Database file not found after connection")
	}

	log.Info().Str("db_path", dbPath).Msg("Database connection established")

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
