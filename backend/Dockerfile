# Build stage
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev sqlite-dev

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application with CGO enabled for SQLite
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/api

# Final stage
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache ca-certificates sqlite-libs tzdata

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/main .

# Copy prompt templates
COPY --from=builder /app/internal/prompts/*.txt ./internal/prompts/

# Create data directory for database volume
RUN mkdir -p /data

# Environment variables (can be overridden)
ENV APP_ENV=production
ENV PORT=8080
ENV DB_PATH=/data/truthordare.db
ENV CORS_ORIGINS=http://localhost:3000
ENV LOG_LEVEL=info

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/v1/health || exit 1

# Run the application
CMD ["./main"]
