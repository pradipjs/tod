
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache gcc musl-dev sqlite-dev

# Copy go mod files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the Go app (CGO enabled for SQLite)
RUN CGO_ENABLED=1 go build -o main ./cmd/api

# Final minimal image
FROM alpine:3.19

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ca-certificates sqlite-libs tzdata

# Copy the built binary and prompts
COPY --from=builder /app/main .
COPY --from=builder /app/internal/prompts ./internal/prompts

# Expose port
EXPOSE 8080

# Run the app
CMD ["./main"]
