// Package prompts provides utilities for loading and processing prompt templates.
//
// This package handles:
// - Loading prompt templates from files
// - Replacing placeholders with actual values
// - Caching prompts for performance
//
// Placeholder format: {{PLACEHOLDER_NAME}}
package prompts

import (
	"embed"
	"fmt"
	"strings"
	"sync"
)

//go:embed *.txt
var promptFiles embed.FS

// PromptLoader handles loading and caching of prompt templates
type PromptLoader struct {
	cache map[string]string
	mu    sync.RWMutex
}

// Placeholder represents a key-value pair for template substitution
type Placeholder struct {
	Key   string
	Value string
}

var (
	// defaultLoader is the singleton instance of PromptLoader
	defaultLoader *PromptLoader
	once          sync.Once
)

// GetLoader returns the singleton PromptLoader instance
func GetLoader() *PromptLoader {
	once.Do(func() {
		defaultLoader = &PromptLoader{
			cache: make(map[string]string),
		}
	})
	return defaultLoader
}

// Load loads a prompt template by name (without .txt extension)
// Returns the raw template content with placeholders intact
func (l *PromptLoader) Load(name string) (string, error) {
	// Check cache first
	l.mu.RLock()
	if cached, ok := l.cache[name]; ok {
		l.mu.RUnlock()
		return cached, nil
	}
	l.mu.RUnlock()

	// Load from embedded files
	filename := name + ".txt"
	content, err := promptFiles.ReadFile(filename)
	if err != nil {
		return "", fmt.Errorf("failed to load prompt '%s': %w", name, err)
	}

	// Cache the content
	l.mu.Lock()
	l.cache[name] = string(content)
	l.mu.Unlock()

	return string(content), nil
}

// LoadAndReplace loads a prompt template and replaces placeholders
// Placeholders are in the format {{KEY}} and are replaced with corresponding values
func (l *PromptLoader) LoadAndReplace(name string, placeholders ...Placeholder) (string, error) {
	template, err := l.Load(name)
	if err != nil {
		return "", err
	}

	return ReplacePlaceholders(template, placeholders...), nil
}

// ReplacePlaceholders replaces all {{KEY}} placeholders in the template with values
func ReplacePlaceholders(template string, placeholders ...Placeholder) string {
	result := template
	for _, p := range placeholders {
		placeholder := "{{" + p.Key + "}}"
		result = strings.ReplaceAll(result, placeholder, p.Value)
	}
	return result
}

// MustLoad loads a prompt template or panics if it fails
// Use this only during initialization
func (l *PromptLoader) MustLoad(name string) string {
	content, err := l.Load(name)
	if err != nil {
		panic(err)
	}
	return content
}

// ClearCache clears the prompt cache (useful for testing)
func (l *PromptLoader) ClearCache() {
	l.mu.Lock()
	l.cache = make(map[string]string)
	l.mu.Unlock()
}

// ListAvailable returns a list of available prompt template names
func (l *PromptLoader) ListAvailable() ([]string, error) {
	entries, err := promptFiles.ReadDir(".")
	if err != nil {
		return nil, fmt.Errorf("failed to list prompts: %w", err)
	}

	var names []string
	for _, entry := range entries {
		if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".txt") {
			name := strings.TrimSuffix(entry.Name(), ".txt")
			names = append(names, name)
		}
	}
	return names, nil
}

// P is a helper function to create a Placeholder
// Usage: P("KEY", "value")
func P(key, value string) Placeholder {
	return Placeholder{Key: key, Value: value}
}
