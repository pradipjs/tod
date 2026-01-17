package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Config holds all configuration for the application.
type Config struct {
	// Server configuration
	Port string
	Env  string

	// Database configuration
	DBDriver   string
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	DBPath     string
	DBSSLMode  string

	// API configuration
	APIPrefix  string
	APIVersion string

	// CORS configuration
	CORSOrigins []string

	// Scheduler configuration
	Scheduler SchedulerConfig
}

// SchedulerConfig holds scheduler-related configuration.
type SchedulerConfig struct {
	Enabled bool

	// Cleanup job settings
	CleanupEnabled         bool
	CleanupCron            string
	CleanupRetentionMonths int

	// Auto-generate job settings
	AutoGenerateEnabled           bool
	AutoGenerateCron              string
	AutoGenerateCount             int
	AutoGenerateRetryMax          int
	AutoGenerateRetryDelaySeconds int
}

// Load loads configuration from environment variables.
func Load() (*Config, error) {
	corsOrigins := getEnv("CORS_ORIGINS", "http://localhost:3000,http://localhost:8080")

	cfg := &Config{
		Port:        getEnv("PORT", "8080"),
		Env:         getEnv("APP_ENV", "development"),
		DBDriver:    getEnv("DB_DRIVER", "sqlite"),
		DBHost:      getEnv("DB_HOST", "localhost"),
		DBPort:      getEnv("DB_PORT", "5432"),
		DBUser:      getEnv("DB_USER", "postgres"),
		DBPassword:  getEnv("DB_PASSWORD", ""),
		DBName:      getEnv("DB_NAME", "truthordare.db"),
		DBPath:      getEnv("DB_PATH", ""),
		DBSSLMode:   getEnv("DB_SSL_MODE", "disable"),
		APIPrefix:   getEnv("API_PREFIX", "/api"),
		APIVersion:  getEnv("API_VERSION", "v1"),
		CORSOrigins: strings.Split(corsOrigins, ","),
		Scheduler: SchedulerConfig{
			Enabled:                       getEnvBool("SCHEDULER_ENABLED", true),
			CleanupEnabled:                getEnvBool("CLEANUP_ENABLED", true),
			CleanupCron:                   getEnv("CLEANUP_CRON", "0 0 * * 0"),
			CleanupRetentionMonths:        getEnvInt("CLEANUP_RETENTION_MONTHS", 2),
			AutoGenerateEnabled:           getEnvBool("AUTO_GENERATE_ENABLED", true),
			AutoGenerateCron:              getEnv("AUTO_GENERATE_CRON", "0 2 * * 0"),
			AutoGenerateCount:             getEnvInt("AUTO_GENERATE_COUNT", 5),
			AutoGenerateRetryMax:          getEnvInt("AUTO_GENERATE_RETRY_MAX", 3),
			AutoGenerateRetryDelaySeconds: getEnvInt("AUTO_GENERATE_RETRY_DELAY_SECONDS", 60),
		},
	}

	return cfg, nil
}

// DSN returns the database connection string.
func (c *Config) DSN() string {
	switch c.DBDriver {
	case "postgres":
		return fmt.Sprintf(
			"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
			c.DBHost, c.DBPort, c.DBUser, c.DBPassword, c.DBName, c.DBSSLMode,
		)
	case "sqlite":
		// Use DB_PATH if specified (for production), otherwise use DB_NAME
		if c.DBPath != "" {
			return c.DBPath
		}
		return c.DBName
	default:
		if c.DBPath != "" {
			return c.DBPath
		}
		return c.DBName
	}
}

// IsDevelopment returns true if running in development mode.
func (c *Config) IsDevelopment() bool {
	return c.Env == "development"
}

// IsProduction returns true if running in production mode.
func (c *Config) IsProduction() bool {
	return c.Env == "production"
}

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value, exists := os.LookupEnv(key); exists {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value, exists := os.LookupEnv(key); exists {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}
