package scheduler

import (
	"context"
	"testing"
	"time"

	"github.com/truthordare/backend/internal/config"
)

func TestScheduler_New(t *testing.T) {
	cfg := &config.Config{
		Scheduler: config.SchedulerConfig{
			Enabled: true,
		},
	}

	s := New(cfg, nil)
	if s == nil {
		t.Fatal("Expected scheduler to be created")
	}
}

func TestScheduler_AddJob(t *testing.T) {
	cfg := &config.Config{
		Scheduler: config.SchedulerConfig{
			Enabled: true,
		},
	}

	s := New(cfg, nil)

	executed := false
	job := &Job{
		Name:        "test-job",
		Description: "Test job",
		CronExpr:    "* * * * *",
		Enabled:     true,
		Fn: func(ctx context.Context) error {
			executed = true
			return nil
		},
	}

	err := s.AddJob(job)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	jobs := s.GetJobs()
	if len(jobs) != 1 {
		t.Fatalf("Expected 1 job, got %d", len(jobs))
	}

	if jobs[0].Name != "test-job" {
		t.Errorf("Expected job name 'test-job', got '%s'", jobs[0].Name)
	}

	// Suppress unused variable warning
	_ = executed
}

func TestScheduler_AddJob_Disabled(t *testing.T) {
	cfg := &config.Config{
		Scheduler: config.SchedulerConfig{
			Enabled: true,
		},
	}

	s := New(cfg, nil)

	job := &Job{
		Name:        "disabled-job",
		Description: "Disabled job",
		CronExpr:    "* * * * *",
		Enabled:     false,
		Fn: func(ctx context.Context) error {
			return nil
		},
	}

	err := s.AddJob(job)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	jobs := s.GetJobs()
	if len(jobs) != 0 {
		t.Fatalf("Expected 0 jobs (disabled job should not be added), got %d", len(jobs))
	}
}

func TestScheduler_InvalidCron(t *testing.T) {
	cfg := &config.Config{
		Scheduler: config.SchedulerConfig{
			Enabled: true,
		},
	}

	s := New(cfg, nil)

	job := &Job{
		Name:        "invalid-job",
		Description: "Invalid cron job",
		CronExpr:    "invalid cron expression",
		Enabled:     true,
		Fn: func(ctx context.Context) error {
			return nil
		},
	}

	err := s.AddJob(job)
	if err == nil {
		t.Fatal("Expected error for invalid cron expression")
	}
}

func TestScheduler_RunJobNow(t *testing.T) {
	cfg := &config.Config{
		Scheduler: config.SchedulerConfig{
			Enabled: true,
		},
	}

	s := New(cfg, nil)

	executed := false
	job := &Job{
		Name:        "manual-job",
		Description: "Manual run job",
		CronExpr:    "0 0 1 1 *",
		Enabled:     true,
		Fn: func(ctx context.Context) error {
			executed = true
			return nil
		},
	}

	err := s.AddJob(job)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	err = s.RunJobNow("manual-job")
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	if !executed {
		t.Error("Expected job to be executed")
	}
}

func TestScheduler_Stop(t *testing.T) {
	cfg := &config.Config{
		Scheduler: config.SchedulerConfig{
			Enabled: true,
		},
	}

	s := New(cfg, nil)
	s.Start()

	ctx := s.Stop()
	select {
	case <-ctx.Done():
		// Good, scheduler stopped
	case <-time.After(5 * time.Second):
		t.Error("Scheduler did not stop within timeout")
	}
}

func TestIsRetryableError(t *testing.T) {
	tests := []struct {
		name     string
		err      error
		expected bool
	}{
		{
			name:     "nil error",
			err:      nil,
			expected: false,
		},
		{
			name:     "rate limit error",
			err:      &testError{msg: "rate limit exceeded"},
			expected: true,
		},
		{
			name:     "429 error",
			err:      &testError{msg: "status code 429"},
			expected: true,
		},
		{
			name:     "timeout error",
			err:      &testError{msg: "request timeout"},
			expected: true,
		},
		{
			name:     "generic error",
			err:      &testError{msg: "some other error"},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := isRetryableError(tt.err)
			if result != tt.expected {
				t.Errorf("Expected %v, got %v", tt.expected, result)
			}
		})
	}
}

type testError struct {
	msg string
}

func (e *testError) Error() string {
	return e.msg
}
