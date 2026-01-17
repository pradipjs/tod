package scheduler

import (
	"context"
	"database/sql"
	"time"

	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/config"
	"gorm.io/gorm"
)

// CleanupJob handles cleanup of deprecated/soft-deleted data.
type CleanupJob struct {
	db  *gorm.DB
	cfg *config.SchedulerConfig
}

// NewCleanupJob creates a new cleanup job.
func NewCleanupJob(db *gorm.DB, cfg *config.SchedulerConfig) *CleanupJob {
	return &CleanupJob{
		db:  db,
		cfg: cfg,
	}
}

// ToJob converts CleanupJob to a schedulable Job.
func (c *CleanupJob) ToJob() *Job {
	return &Job{
		Name:        "cleanup",
		Description: "Clean up soft-deleted data older than retention period and run VACUUM",
		CronExpr:    c.cfg.CleanupCron,
		Enabled:     c.cfg.CleanupEnabled,
		Fn:          c.Execute,
	}
}

// Execute runs the cleanup job.
func (c *CleanupJob) Execute(ctx context.Context) error {
	logger := log.With().Str("job", "cleanup").Logger()

	retentionMonths := c.cfg.CleanupRetentionMonths
	cutoffDate := time.Now().AddDate(0, -retentionMonths, 0)

	logger.Info().
		Int("retention_months", retentionMonths).
		Time("cutoff_date", cutoffDate).
		Msg("Starting cleanup job")

	// Track cleanup statistics
	var stats CleanupStats

	// Clean up tasks
	taskResult, err := c.cleanupTable(ctx, "tasks", cutoffDate)
	if err != nil {
		logger.Error().Err(err).Msg("Failed to cleanup tasks table")
		return err
	}
	stats.TasksDeleted = taskResult

	// Clean up categories
	categoryResult, err := c.cleanupTable(ctx, "categories", cutoffDate)
	if err != nil {
		logger.Error().Err(err).Msg("Failed to cleanup categories table")
		return err
	}
	stats.CategoriesDeleted = categoryResult

	logger.Info().
		Int64("tasks_deleted", stats.TasksDeleted).
		Int64("categories_deleted", stats.CategoriesDeleted).
		Msg("Soft-deleted records permanently removed")

	// Run VACUUM to reclaim disk space
	if err := c.runVacuum(ctx); err != nil {
		logger.Error().Err(err).Msg("Failed to run VACUUM")
		return err
	}

	logger.Info().Msg("Cleanup job completed successfully")
	return nil
}

// cleanupTable permanently deletes soft-deleted records older than cutoff date.
func (c *CleanupJob) cleanupTable(ctx context.Context, tableName string, cutoffDate time.Time) (int64, error) {
	// Use raw SQL to permanently delete soft-deleted records
	// GORM's soft delete uses deleted_at column
	result := c.db.WithContext(ctx).Exec(
		"DELETE FROM "+tableName+" WHERE deleted_at IS NOT NULL AND deleted_at < ?",
		cutoffDate,
	)

	if result.Error != nil {
		return 0, result.Error
	}

	return result.RowsAffected, nil
}

// runVacuum runs SQLite VACUUM command to reclaim disk space.
func (c *CleanupJob) runVacuum(ctx context.Context) error {
	logger := log.With().Str("job", "cleanup").Logger()
	logger.Info().Msg("Running VACUUM to reclaim disk space")

	// Get underlying SQL DB
	sqlDB, err := c.db.DB()
	if err != nil {
		return err
	}

	// Get database size before VACUUM (for SQLite)
	var sizeBefore int64
	row := sqlDB.QueryRowContext(ctx, "SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()")
	_ = row.Scan(&sizeBefore)

	// Run VACUUM - must be executed outside of a transaction
	_, err = sqlDB.ExecContext(ctx, "VACUUM")
	if err != nil {
		return err
	}

	// Get database size after VACUUM
	var sizeAfter int64
	row = sqlDB.QueryRowContext(ctx, "SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()")
	_ = row.Scan(&sizeAfter)

	spaceSaved := sizeBefore - sizeAfter
	logger.Info().
		Int64("size_before_bytes", sizeBefore).
		Int64("size_after_bytes", sizeAfter).
		Int64("space_saved_bytes", spaceSaved).
		Msg("VACUUM completed")

	return nil
}

// CleanupStats holds statistics from the cleanup job.
type CleanupStats struct {
	TasksDeleted      int64
	CategoriesDeleted int64
	SpaceSavedBytes   int64
}

// GetCleanupPreview returns a preview of what would be cleaned up.
func (c *CleanupJob) GetCleanupPreview(ctx context.Context) (*CleanupPreview, error) {
	retentionMonths := c.cfg.CleanupRetentionMonths
	cutoffDate := time.Now().AddDate(0, -retentionMonths, 0)

	preview := &CleanupPreview{
		CutoffDate:      cutoffDate,
		RetentionMonths: retentionMonths,
	}

	// Count tasks to be deleted
	var taskCount int64
	err := c.db.WithContext(ctx).Raw(
		"SELECT COUNT(*) FROM tasks WHERE deleted_at IS NOT NULL AND deleted_at < ?",
		cutoffDate,
	).Scan(&taskCount).Error
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	preview.TasksToDelete = taskCount

	// Count categories to be deleted
	var categoryCount int64
	err = c.db.WithContext(ctx).Raw(
		"SELECT COUNT(*) FROM categories WHERE deleted_at IS NOT NULL AND deleted_at < ?",
		cutoffDate,
	).Scan(&categoryCount).Error
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	preview.CategoriesToDelete = categoryCount

	return preview, nil
}

// CleanupPreview shows what would be cleaned up without actually doing it.
type CleanupPreview struct {
	CutoffDate         time.Time `json:"cutoff_date"`
	RetentionMonths    int       `json:"retention_months"`
	TasksToDelete      int64     `json:"tasks_to_delete"`
	CategoriesToDelete int64     `json:"categories_to_delete"`
}
