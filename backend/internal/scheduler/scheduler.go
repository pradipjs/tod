// Package scheduler provides background job scheduling functionality.
// It uses cron expressions for scheduling and supports multiple concurrent jobs.
package scheduler

import (
	"context"
	"sync"
	"time"

	"github.com/robfig/cron/v3"
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/config"
	"gorm.io/gorm"
)

// Job represents a scheduled job with metadata.
type Job struct {
	Name        string
	Description string
	CronExpr    string
	Enabled     bool
	Fn          func(ctx context.Context) error
	entryID     cron.EntryID
}

// Scheduler manages background jobs.
type Scheduler struct {
	cron   *cron.Cron
	jobs   []*Job
	db     *gorm.DB
	cfg    *config.Config
	mu     sync.RWMutex
	ctx    context.Context
	cancel context.CancelFunc
}

// New creates a new Scheduler instance.
func New(cfg *config.Config, db *gorm.DB) *Scheduler {
	ctx, cancel := context.WithCancel(context.Background())

	// Create cron with seconds field (optional) and recover from panics
	c := cron.New(
		cron.WithParser(cron.NewParser(
			cron.Minute|cron.Hour|cron.Dom|cron.Month|cron.Dow,
		)),
		cron.WithChain(
			cron.Recover(cron.DefaultLogger),
		),
	)

	return &Scheduler{
		cron:   c,
		jobs:   make([]*Job, 0),
		db:     db,
		cfg:    cfg,
		ctx:    ctx,
		cancel: cancel,
	}
}

// AddJob adds a job to the scheduler.
func (s *Scheduler) AddJob(job *Job) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if !job.Enabled {
		log.Info().Str("job", job.Name).Msg("Job is disabled, skipping registration")
		return nil
	}

	// Wrap the job function with logging and error handling
	wrappedFn := func() {
		startTime := time.Now()
		logger := log.With().
			Str("job", job.Name).
			Time("start_time", startTime).
			Logger()

		logger.Info().Msg("Job started")

		if err := job.Fn(s.ctx); err != nil {
			logger.Error().
				Err(err).
				Dur("duration", time.Since(startTime)).
				Msg("Job failed")
			return
		}

		logger.Info().
			Dur("duration", time.Since(startTime)).
			Msg("Job completed successfully")
	}

	entryID, err := s.cron.AddFunc(job.CronExpr, wrappedFn)
	if err != nil {
		log.Error().Err(err).Str("job", job.Name).Msg("Failed to schedule job")
		return err
	}

	job.entryID = entryID
	s.jobs = append(s.jobs, job)

	log.Info().
		Str("job", job.Name).
		Str("cron", job.CronExpr).
		Str("description", job.Description).
		Msg("Job scheduled successfully")

	return nil
}

// Start starts the scheduler.
func (s *Scheduler) Start() {
	if !s.cfg.Scheduler.Enabled {
		log.Info().Msg("Scheduler is disabled")
		return
	}

	log.Info().Int("jobs", len(s.jobs)).Msg("Starting scheduler")
	s.cron.Start()
}

// Stop gracefully stops the scheduler.
func (s *Scheduler) Stop() context.Context {
	log.Info().Msg("Stopping scheduler")
	s.cancel()
	return s.cron.Stop()
}

// RunJobNow runs a job immediately by name.
func (s *Scheduler) RunJobNow(name string) error {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, job := range s.jobs {
		if job.Name == name {
			log.Info().Str("job", name).Msg("Running job manually")
			return job.Fn(s.ctx)
		}
	}

	log.Warn().Str("job", name).Msg("Job not found")
	return nil
}

// GetJobs returns information about all registered jobs.
func (s *Scheduler) GetJobs() []JobInfo {
	s.mu.RLock()
	defer s.mu.RUnlock()

	infos := make([]JobInfo, 0, len(s.jobs))
	for _, job := range s.jobs {
		entry := s.cron.Entry(job.entryID)
		info := JobInfo{
			Name:        job.Name,
			Description: job.Description,
			CronExpr:    job.CronExpr,
			Enabled:     job.Enabled,
			NextRun:     entry.Next,
			PrevRun:     entry.Prev,
		}
		infos = append(infos, info)
	}

	return infos
}

// JobInfo contains information about a scheduled job.
type JobInfo struct {
	Name        string    `json:"name"`
	Description string    `json:"description"`
	CronExpr    string    `json:"cron_expr"`
	Enabled     bool      `json:"enabled"`
	NextRun     time.Time `json:"next_run"`
	PrevRun     time.Time `json:"prev_run"`
}

// GetDB returns the database connection for use by jobs.
func (s *Scheduler) GetDB() *gorm.DB {
	return s.db
}

// GetConfig returns the configuration for use by jobs.
func (s *Scheduler) GetConfig() *config.Config {
	return s.cfg
}
