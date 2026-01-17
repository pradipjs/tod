package middleware

import (
	"crypto/subtle"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"github.com/truthordare/backend/internal/models"
)

const (
	// AuthHeader is the header name for the OTP key
	AuthHeader = "X-Admin-OTP"
)

// AuthMiddleware validates the admin OTP key from header.
// Uses timing-safe comparison to prevent timing attacks.
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		otpKey := c.GetHeader(AuthHeader)

		expectedKey := os.Getenv("ADMIN_OTP_KEY")
		if expectedKey == "" {
			// In production, require the env var to be set
			if os.Getenv("GIN_MODE") == "release" {
				log.Error().Msg("ADMIN_OTP_KEY not set in production mode")
				c.JSON(http.StatusInternalServerError, models.ErrorResponse{
					Error:   "configuration_error",
					Message: "Server configuration error",
				})
				c.Abort()
				return
			}
			// Only use default in development
			expectedKey = "TOD_ADMIN_2026_SECURE_KEY"
		}

		if otpKey == "" {
			log.Warn().
				Str("ip", c.ClientIP()).
				Str("path", c.Request.URL.Path).
				Msg("Missing authentication header")
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "unauthorized",
				Message: "Missing authentication header",
			})
			c.Abort()
			return
		}

		// Use timing-safe comparison to prevent timing attacks
		if subtle.ConstantTimeCompare([]byte(otpKey), []byte(expectedKey)) != 1 {
			log.Warn().
				Str("ip", c.ClientIP()).
				Str("path", c.Request.URL.Path).
				Msg("Invalid authentication attempt")
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "unauthorized",
				Message: "Invalid authentication key",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
