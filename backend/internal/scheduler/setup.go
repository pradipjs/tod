package scheduler

import (
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/config"
	"github.com/truthordare/backend/internal/repository"
	"gorm.io/gorm"
)

// Setup creates and configures the scheduler with all jobs.
func Setup(cfg *config.Config, db *gorm.DB) *Scheduler {
	scheduler := New(cfg, db)

	// Create repositories for jobs that need them
	categoryRepo := repository.NewCategoryRepository(db)
	taskRepo := repository.NewTaskRepository(db)

	// Register cleanup job
	cleanupJob := NewCleanupJob(db, &cfg.Scheduler)
	if err := scheduler.AddJob(cleanupJob.ToJob()); err != nil {
		log.Error().Err(err).Msg("Failed to register cleanup job")
	}

	// Register auto-generate job
	autoGenerateJob := NewAutoGenerateJob(db, &cfg.Scheduler, categoryRepo, taskRepo)
	if err := scheduler.AddJob(autoGenerateJob.ToJob()); err != nil {
		log.Error().Err(err).Msg("Failed to register auto-generate job")
	}

	return scheduler
}
