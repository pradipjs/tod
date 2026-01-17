package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/truthordare/backend/internal/middleware"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	return router
}

func TestAuthMiddleware(t *testing.T) {
	originalKey := os.Getenv("ADMIN_OTP_KEY")
	os.Setenv("ADMIN_OTP_KEY", "test-otp-key")
	defer os.Setenv("ADMIN_OTP_KEY", originalKey)

	router := setupTestRouter()
	router.Use(middleware.AuthMiddleware())
	router.GET("/protected", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	t.Run("missing auth header", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/protected", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Missing authentication header")
	})

	t.Run("invalid auth key", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/protected", nil)
		req.Header.Set("X-Admin-OTP", "wrong-key")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Invalid authentication key")
	})

	t.Run("valid auth key", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/protected", nil)
		req.Header.Set("X-Admin-OTP", "test-otp-key")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), "success")
	})
}

func TestAuthMiddleware_DefaultKey(t *testing.T) {
	originalKey := os.Getenv("ADMIN_OTP_KEY")
	originalMode := os.Getenv("GIN_MODE")
	os.Unsetenv("ADMIN_OTP_KEY")
	os.Unsetenv("GIN_MODE")
	defer func() {
		if originalKey != "" {
			os.Setenv("ADMIN_OTP_KEY", originalKey)
		}
		if originalMode != "" {
			os.Setenv("GIN_MODE", originalMode)
		}
	}()

	router := setupTestRouter()
	router.Use(middleware.AuthMiddleware())
	router.GET("/protected", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	t.Run("default key in development", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/protected", nil)
		req.Header.Set("X-Admin-OTP", "TOD_ADMIN_2026_SECURE_KEY")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
	})
}

func TestAuthMiddleware_ProductionMode(t *testing.T) {
	originalKey := os.Getenv("ADMIN_OTP_KEY")
	originalMode := os.Getenv("GIN_MODE")
	os.Unsetenv("ADMIN_OTP_KEY")
	os.Setenv("GIN_MODE", "release")
	defer func() {
		if originalKey != "" {
			os.Setenv("ADMIN_OTP_KEY", originalKey)
		}
		if originalMode != "" {
			os.Setenv("GIN_MODE", originalMode)
		} else {
			os.Unsetenv("GIN_MODE")
		}
	}()

	router := setupTestRouter()
	router.Use(middleware.AuthMiddleware())
	router.GET("/protected", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	t.Run("requires OTP key in production", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/protected", nil)
		req.Header.Set("X-Admin-OTP", "any-key")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		assert.Contains(t, w.Body.String(), "configuration_error")
	})
}
