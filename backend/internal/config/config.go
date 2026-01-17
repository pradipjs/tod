package config

import (
	"os"
	"strconv"
	"strings"
)

// Config holds all configuration for the application.
type Config struct {
	Port string
	Env  string

	DBPath string

	APIPrefix  string
	APIVersion string

	CORSOrigins []string

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
		DBPath:      getEnv("DB_PATH", "truthordare.db"),
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

func (c *Config) DSN() string {
	return c.DBPath
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
