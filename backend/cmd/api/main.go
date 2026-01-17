package main

import (
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/config"
	"github.com/truthordare/backend/internal/database"
	"github.com/truthordare/backend/internal/scheduler"
	"github.com/truthordare/backend/internal/server"
)

func main() {
	// Load .env file if exists
	_ = godotenv.Load()

	// Setup logging
	setupLogger()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to load configuration")
	}

	// Initialize database
	db, err := database.Initialize(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize database")
	}

	// Run migrations
	if err := database.Migrate(db); err != nil {
		log.Fatal().Err(err).Msg("Failed to run migrations")
	}

	// Seed initial data if needed
	if err := database.Seed(db); err != nil {
		log.Warn().Err(err).Msg("Failed to seed database")
	}

	// Setup and start scheduler
	sched := scheduler.Setup(cfg, db)
	sched.Start()

	// Create server and set scheduler
	srv := server.New(cfg, db)
	srv.SetScheduler(sched)

	// Handle graceful shutdown
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan

		log.Info().Msg("Shutdown signal received")

		// Stop scheduler gracefully
		ctx := sched.Stop()
		<-ctx.Done()

		log.Info().Msg("Scheduler stopped")
		os.Exit(0)
	}()

	log.Info().Str("port", cfg.Port).Msg("Starting server")

	if err := srv.Start(); err != nil {
		log.Fatal().Err(err).Msg("Server failed to start")
	}
}

func setupLogger() {
	// Pretty logging for development
	if os.Getenv("APP_ENV") != "production" {
		log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	}

	// Set log level
	level := os.Getenv("LOG_LEVEL")
	switch level {
	case "debug":
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
	case "info":
		zerolog.SetGlobalLevel(zerolog.InfoLevel)
	case "warn":
		zerolog.SetGlobalLevel(zerolog.WarnLevel)
	case "error":
		zerolog.SetGlobalLevel(zerolog.ErrorLevel)
	default:
		zerolog.SetGlobalLevel(zerolog.InfoLevel)
	}
}
