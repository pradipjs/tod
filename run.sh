#!/bin/bash

# =============================================================================
# Truth or Dare - Development Run Script
# =============================================================================
#
# This script runs the backend API server and/or admin panel for development.
#
# Usage:
#   ./run.sh           # Run both backend and admin (default)
#   ./run.sh backend   # Run only backend
#   ./run.sh admin     # Run only admin
#   ./run.sh all       # Run both backend and admin
#
# Environment:
#   The script sources .env files from respective directories if they exist.
#
# Requirements:
#   - Go 1.21+ for backend
#   - Node.js 18+ for admin
#   - npm for admin dependencies
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
ADMIN_DIR="$SCRIPT_DIR/admin"

# Default ports
BACKEND_PORT=${BACKEND_PORT:-8080}
ADMIN_PORT=${ADMIN_PORT:-5173}

# PID files for tracking processes
BACKEND_PID_FILE="/tmp/tod_backend.pid"
ADMIN_PID_FILE="/tmp/tod_admin.pid"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
    return 0
}

cleanup() {
    log_info "Cleaning up..."
    
    # Kill backend if running
    if [ -f "$BACKEND_PID_FILE" ]; then
        PID=$(cat "$BACKEND_PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log_info "Stopping backend (PID: $PID)..."
            kill "$PID" 2>/dev/null || true
        fi
        rm -f "$BACKEND_PID_FILE"
    fi
    
    # Kill admin if running
    if [ -f "$ADMIN_PID_FILE" ]; then
        PID=$(cat "$ADMIN_PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log_info "Stopping admin (PID: $PID)..."
            kill "$PID" 2>/dev/null || true
        fi
        rm -f "$ADMIN_PID_FILE"
    fi
    
    log_success "Cleanup complete"
}

# Trap signals for cleanup
trap cleanup EXIT INT TERM

# =============================================================================
# Backend Functions
# =============================================================================

run_backend() {
    log_info "Starting backend server..."
    
    # Check Go is installed
    if ! check_command "go"; then
        log_error "Go is required to run the backend"
        return 1
    fi
    
    # Check backend directory exists
    if [ ! -d "$BACKEND_DIR" ]; then
        log_error "Backend directory not found: $BACKEND_DIR"
        return 1
    fi
    
    cd "$BACKEND_DIR"
    
    # Source .env if exists
    if [ -f ".env" ]; then
        log_info "Loading backend environment from .env"
        export $(grep -v '^#' .env | xargs)
    fi
    
    # Run backend
    log_info "Backend starting on port $BACKEND_PORT..."
    go run cmd/api/main.go &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$BACKEND_PID_FILE"
    
    # Wait a bit and check if it started
    sleep 2
    if kill -0 "$BACKEND_PID" 2>/dev/null; then
        log_success "Backend started (PID: $BACKEND_PID)"
        log_info "Backend URL: http://localhost:$BACKEND_PORT"
        log_info "Health check: http://localhost:$BACKEND_PORT/health"
    else
        log_error "Backend failed to start"
        return 1
    fi
}

# =============================================================================
# Admin Functions
# =============================================================================

run_admin() {
    log_info "Starting admin panel..."
    
    # Check Node.js is installed
    if ! check_command "node"; then
        log_error "Node.js is required to run the admin panel"
        return 1
    fi
    
    # Check npm is installed
    if ! check_command "npm"; then
        log_error "npm is required to run the admin panel"
        return 1
    fi
    
    # Check admin directory exists
    if [ ! -d "$ADMIN_DIR" ]; then
        log_error "Admin directory not found: $ADMIN_DIR"
        return 1
    fi
    
    cd "$ADMIN_DIR"
    
    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
        log_info "Installing admin dependencies..."
        npm install
    fi
    
    # Source .env if exists
    if [ -f ".env" ]; then
        log_info "Loading admin environment from .env"
        export $(grep -v '^#' .env | xargs)
    fi
    
    # Run admin dev server
    log_info "Admin starting on port $ADMIN_PORT..."
    npm run dev &
    ADMIN_PID=$!
    echo $ADMIN_PID > "$ADMIN_PID_FILE"
    
    # Wait a bit and check if it started
    sleep 3
    if kill -0 "$ADMIN_PID" 2>/dev/null; then
        log_success "Admin started (PID: $ADMIN_PID)"
        log_info "Admin URL: http://localhost:$ADMIN_PORT"
    else
        log_error "Admin failed to start"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

show_usage() {
    echo ""
    echo "Truth or Dare - Development Run Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  backend    Run only the backend API server"
    echo "  admin      Run only the admin panel"
    echo "  all        Run both backend and admin (default)"
    echo "  help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  BACKEND_PORT  Backend server port (default: 8080)"
    echo "  ADMIN_PORT    Admin panel port (default: 5173)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run both"
    echo "  $0 backend            # Run backend only"
    echo "  $0 admin              # Run admin only"
    echo "  BACKEND_PORT=3000 $0  # Run with custom backend port"
    echo ""
}

main() {
    local COMMAND=${1:-all}
    
    echo ""
    echo "=========================================="
    echo "  Truth or Dare - Development Server"
    echo "=========================================="
    echo ""
    
    case "$COMMAND" in
        backend)
            run_backend
            wait
            ;;
        admin)
            run_admin
            wait
            ;;
        all)
            run_backend
            run_admin
            echo ""
            log_success "All services started!"
            echo ""
            echo "=========================================="
            echo "  Services Running:"
            echo "  - Backend:  http://localhost:$BACKEND_PORT"
            echo "  - Admin:    http://localhost:$ADMIN_PORT"
            echo "=========================================="
            echo ""
            log_info "Press Ctrl+C to stop all services"
            wait
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
