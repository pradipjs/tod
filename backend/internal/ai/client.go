// Package ai provides utilities for making AI API calls.
//
// This package provides a clean, reusable interface for:
// - Making chat completion requests to AI APIs (OpenAI-compatible)
// - Handling responses and errors
// - JSON parsing of AI responses
//
// Supported providers: Groq, OpenAI, and any OpenAI-compatible API
package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sync"
	"time"
)

// Client represents an AI API client
type Client struct {
	apiKey     string
	apiURL     string
	model      string
	httpClient *http.Client
}

// ClientConfig holds configuration for creating an AI client
type ClientConfig struct {
	APIKey  string        // API key for authentication
	APIURL  string        // Base URL for the API
	Model   string        // Model to use for completions
	Timeout time.Duration // HTTP client timeout
}

// Message represents a chat message
type Message struct {
	Role    string `json:"role"`    // "system", "user", or "assistant"
	Content string `json:"content"` // Message content
}

// CompletionRequest represents a chat completion request
type CompletionRequest struct {
	Model       string    `json:"model"`
	Messages    []Message `json:"messages"`
	MaxTokens   int       `json:"max_tokens,omitempty"`
	Temperature float64   `json:"temperature,omitempty"`
}

// CompletionResponse represents the API response
type CompletionResponse struct {
	ID      string `json:"id"`
	Object  string `json:"object"`
	Created int64  `json:"created"`
	Model   string `json:"model"`
	Choices []struct {
		Index   int     `json:"index"`
		Message Message `json:"message"`
	} `json:"choices"`
	Usage struct {
		PromptTokens     int `json:"prompt_tokens"`
		CompletionTokens int `json:"completion_tokens"`
		TotalTokens      int `json:"total_tokens"`
	} `json:"usage"`
}

var (
	defaultClient *Client
	clientOnce    sync.Once
)

// DefaultConfig returns the default configuration from environment variables
// Supports both OPENAI_API_KEY/AI_MODEL and legacy GROQ_API_KEY/GROQ_MODEL
func DefaultConfig() ClientConfig {
	// Check for OPENAI_API_KEY first, then fall back to GROQ_API_KEY
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		apiKey = os.Getenv("GROQ_API_KEY")
	}

	// Check for AI_API_URL first, then GROQ_API_URL
	apiURL := os.Getenv("AI_API_URL")
	if apiURL == "" {
		apiURL = os.Getenv("GROQ_API_URL")
	}
	if apiURL == "" {
		apiURL = "https://api.groq.com/openai/v1/chat/completions"
	}

	// Check for AI_MODEL first, then GROQ_MODEL
	model := os.Getenv("AI_MODEL")
	if model == "" {
		model = os.Getenv("GROQ_MODEL")
	}
	if model == "" {
		model = "llama-3.3-70b-versatile"
	}

	return ClientConfig{
		APIKey:  apiKey,
		APIURL:  apiURL,
		Model:   model,
		Timeout: 60 * time.Second,
	}
}

// NewClient creates a new AI client with the given configuration
func NewClient(config ClientConfig) *Client {
	timeout := config.Timeout
	if timeout == 0 {
		timeout = 60 * time.Second
	}

	return &Client{
		apiKey: config.APIKey,
		apiURL: config.APIURL,
		model:  config.Model,
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}
}

// GetClient returns the singleton default AI client
func GetClient() *Client {
	clientOnce.Do(func() {
		defaultClient = NewClient(DefaultConfig())
	})
	return defaultClient
}

// IsConfigured returns true if the client has a valid API key
func (c *Client) IsConfigured() bool {
	return c.apiKey != ""
}

// Complete sends a chat completion request and returns the response
func (c *Client) Complete(messages []Message, opts ...CompletionOption) (*CompletionResponse, error) {
	if !c.IsConfigured() {
		return nil, fmt.Errorf("AI client not configured: missing API key")
	}

	// Build request with defaults
	req := CompletionRequest{
		Model:       c.model,
		Messages:    messages,
		MaxTokens:   2000,
		Temperature: 0.7,
	}

	// Apply options
	for _, opt := range opts {
		opt(&req)
	}

	return c.doRequest(req)
}

// CompleteWithSystem is a convenience method that sends a system prompt and user message
func (c *Client) CompleteWithSystem(systemPrompt, userMessage string, opts ...CompletionOption) (string, error) {
	messages := []Message{
		{Role: "system", Content: systemPrompt},
		{Role: "user", Content: userMessage},
	}

	resp, err := c.Complete(messages, opts...)
	if err != nil {
		return "", err
	}

	return resp.GetContent(), nil
}

// CompleteJSON sends a request and parses the response as JSON into the target
func (c *Client) CompleteJSON(messages []Message, target interface{}, opts ...CompletionOption) error {
	resp, err := c.Complete(messages, opts...)
	if err != nil {
		return err
	}

	content := resp.GetContent()
	if err := json.Unmarshal([]byte(content), target); err != nil {
		return fmt.Errorf("failed to parse AI response as JSON: %w (content: %s)", err, content)
	}

	return nil
}

// doRequest performs the actual HTTP request
func (c *Client) doRequest(req CompletionRequest) (*CompletionResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequest("POST", c.apiURL, bytes.NewBuffer(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("AI API error (status %d): %s", resp.StatusCode, string(respBody))
	}

	var completionResp CompletionResponse
	if err := json.Unmarshal(respBody, &completionResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &completionResp, nil
}

// GetContent returns the content from the first choice
func (r *CompletionResponse) GetContent() string {
	if len(r.Choices) == 0 {
		return ""
	}
	return r.Choices[0].Message.Content
}

// CompletionOption is a function that modifies a CompletionRequest
type CompletionOption func(*CompletionRequest)

// WithMaxTokens sets the max tokens for the completion
func WithMaxTokens(tokens int) CompletionOption {
	return func(r *CompletionRequest) {
		r.MaxTokens = tokens
	}
}

// WithTemperature sets the temperature for the completion
func WithTemperature(temp float64) CompletionOption {
	return func(r *CompletionRequest) {
		r.Temperature = temp
	}
}

// WithModel overrides the model for this request
func WithModel(model string) CompletionOption {
	return func(r *CompletionRequest) {
		r.Model = model
	}
}
