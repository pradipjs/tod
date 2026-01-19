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
#!/bin/bash

# =============================================================================
# Truth or Dare - Deployment Script
# =============================================================================
#
# This script handles deployment of backend API server and/or admin panel.
# It prompts for each component and runs the appropriate deployment scripts.
#
# Usage:
#   ./run.sh           # Interactive deployment (prompts for each component)
#   ./run.sh backend   # Deploy only backend
#   ./run.sh admin     # Deploy only admin
#   ./run.sh all       # Deploy both backend and admin
#
# Environment:
#   The script sources .env files from respective directories if they exist.
#
# Requirements:
#   - Go 1.21+ for backend
#   - Node.js 18+ for admin
#   - npm for admin dependencies
#   - Appropriate deployment scripts in each directory
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
ADMIN_DIR="$SCRIPT_DIR/admin"

# Deployment log file
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/deployment_$(date +%Y%m%d_%H%M%S).log"

# =============================================================================
# Helper Functions
# =============================================================================

setup_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    log_info "Deployment log: $LOG_FILE"
}

log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_to_file "[INFO] $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_to_file "[SUCCESS] $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_to_file "[WARNING] $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_to_file "[ERROR] $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
    log_to_file "[STEP] $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
    return 0
}

ask_confirmation() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$(echo -e ${CYAN}${prompt}${NC}) " response
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo "Please answer yes or no (y/n)"
                ;;
        esac
    done
}

find_deployment_script() {
    local dir="$1"
    local scripts=("deploy.sh" "build.sh" "build_fast.sh" "build_deploy.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$dir/$script" ]; then
            echo "$script"
            return 0
        fi
    done
    
    return 1
}

# =============================================================================
# Backend Deployment Functions
# =============================================================================

deploy_backend() {
    log_step "Starting backend deployment..."
    
    # Check Go is installed
    if ! check_command "go"; then
        log_error "Go is required to deploy the backend"
        return 1
    fi
    
    # Check backend directory exists
    if [ ! -d "$BACKEND_DIR" ]; then
        log_error "Backend directory not found: $BACKEND_DIR"
        return 1
    fi
    
    cd "$BACKEND_DIR"
    
    # Find deployment script
    local deploy_script=$(find_deployment_script "$BACKEND_DIR")
    
    if [ -z "$deploy_script" ]; then
        log_warning "No deployment script found in backend directory"
        log_info "Looking for: deploy.sh, build.sh, build_fast.sh, build_deploy.sh"
        
        if ask_confirmation "Do you want to run a manual build? (y/n):"; then
            log_info "Running manual Go build..."
            log_to_file "=== Backend Manual Build Start ==="
            
            if go build -o bin/api cmd/api/main.go 2>&1 | tee -a "$LOG_FILE"; then
                log_success "Backend built successfully: bin/api"
                log_to_file "=== Backend Manual Build Success ==="
                return 0
            else
                log_error "Backend build failed"
                log_to_file "=== Backend Manual Build Failed ==="
                return 1
            fi
        else
            log_info "Skipping backend build"
            return 0
        fi
    else
        log_info "Found deployment script: $deploy_script"
        
        # Make script executable
        chmod +x "$deploy_script"
        
        # Source .env if exists
        if [ -f ".env" ]; then
            log_info "Loading backend environment from .env"
            set -a
            source .env
            set +a
        fi
        
        log_info "Executing $deploy_script..."
        log_to_file "=== Backend Deployment Start: $deploy_script ==="
        
        if ./"$deploy_script" 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Backend deployed successfully"
            log_to_file "=== Backend Deployment Success ==="
            return 0
        else
            log_error "Backend deployment failed"
            log_to_file "=== Backend Deployment Failed ==="
            return 1
        fi
    fi
}

# =============================================================================
# Admin Deployment Functions
# =============================================================================

deploy_admin() {
    log_step "Starting admin panel deployment..."
    
    # Check Node.js is installed
    if ! check_command "node"; then
        log_error "Node.js is required to deploy the admin panel"
        return 1
    fi
    
    # Check npm is installed
    if ! check_command "npm"; then
        log_error "npm is required to deploy the admin panel"
        return 1
    fi
    
    # Check admin directory exists
    if [ ! -d "$ADMIN_DIR" ]; then
        log_error "Admin directory not found: $ADMIN_DIR"
        return 1
    fi
    
    cd "$ADMIN_DIR"
    
    # Find deployment script
    local deploy_script=$(find_deployment_script "$ADMIN_DIR")
    
    if [ -z "$deploy_script" ]; then
        log_warning "No deployment script found in admin directory"
        log_info "Looking for: deploy.sh, build.sh, build_fast.sh, build_deploy.sh"
        
        if ask_confirmation "Do you want to run a manual build? (y/n):"; then
            log_info "Installing dependencies..."
            log_to_file "=== Admin Dependencies Install Start ==="
            
            if npm install 2>&1 | tee -a "$LOG_FILE"; then
                log_info "Building admin panel..."
                log_to_file "=== Admin Build Start ==="
                
                if npm run build 2>&1 | tee -a "$LOG_FILE"; then
                    log_success "Admin panel built successfully"
                    log_to_file "=== Admin Build Success ==="
                    return 0
                else
                    log_error "Admin panel build failed"
                    log_to_file "=== Admin Build Failed ==="
                    return 1
                fi
            else
                log_error "Failed to install dependencies"
                log_to_file "=== Admin Dependencies Install Failed ==="
                return 1
            fi
        else
            log_info "Skipping admin build"
            return 0
        fi
    else
        log_info "Found deployment script: $deploy_script"
        
        # Make script executable
        chmod +x "$deploy_script"
        
        # Source .env if exists
        if [ -f ".env" ]; then
            log_info "Loading admin environment from .env"
            set -a
            source .env
            set +a
        fi
        
        log_info "Executing $deploy_script..."
        log_to_file "=== Admin Deployment Start: $deploy_script ==="
        
        if ./"$deploy_script" 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Admin panel deployed successfully"
            log_to_file "=== Admin Deployment Success ==="
            return 0
        else
            log_error "Admin panel deployment failed"
            log_to_file "=== Admin Deployment Failed ==="
            return 1
        fi
    fi
}

# =============================================================================
# Main
# =============================================================================

show_usage() {
    echo ""
    echo "Truth or Dare - Deployment Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  backend    Deploy only the backend API server"
    echo "  admin      Deploy only the admin panel"
    echo "  all        Deploy both backend and admin"
    echo "  interactive Deploy with interactive prompts (default)"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive mode (prompts for each)"
    echo "  $0 backend            # Deploy backend only"
    echo "  $0 admin              # Deploy admin only"
    echo "  $0 all                # Deploy both without prompts"
    echo ""
}

main() {
    local COMMAND=${1:-interactive}
    
    echo ""
    echo "=========================================="
    echo "  Truth or Dare - Deployment"
    echo "=========================================="
    echo ""
    
    # Setup logging
    setup_logging
    
    local backend_status=0
    local admin_status=0
    
    case "$COMMAND" in
        backend)
            deploy_backend
            backend_status=$?
            ;;
        admin)
            deploy_admin
            admin_status=$?
            ;;
        all)
            log_info "Deploying all components..."
            echo ""
            deploy_backend
            backend_status=$?
            echo ""
            deploy_admin
            admin_status=$?
            ;;
        interactive)
            log_info "Interactive deployment mode"
            echo ""
            
            if ask_confirmation "Deploy backend? (y/n):"; then
                echo ""
                deploy_backend
                backend_status=$?
                echo ""
            else
                log_info "Skipping backend deployment"
                echo ""
            fi
            
            if ask_confirmation "Deploy admin panel? (y/n):"; then
                echo ""
                deploy_admin
                admin_status=$?
                echo ""
            else
                log_info "Skipping admin panel deployment"
                echo ""
            fi
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
    
    # Summary
    echo ""
    echo "=========================================="
    echo "  Deployment Summary"
    echo "=========================================="
    
    if [ "$COMMAND" != "interactive" ] || ask_confirmation "Deploy backend? (y/n):" 2>/dev/null; then
        if [ $backend_status -eq 0 ]; then
            echo -e "  Backend:  ${GREEN}✓ SUCCESS${NC}"
        else
            echo -e "  Backend:  ${RED}✗ FAILED${NC}"
        fi
    fi
    
    if [ "$COMMAND" != "interactive" ] || ask_confirmation "Deploy admin panel? (y/n):" 2>/dev/null; then
        if [ $admin_status -eq 0 ]; then
            echo -e "  Admin:    ${GREEN}✓ SUCCESS${NC}"
        else
            echo -e "  Admin:    ${RED}✗ FAILED${NC}"
        fi
    fi
    
    echo "=========================================="
    echo ""
    log_info "Deployment log saved to: $LOG_FILE"
    echo ""
    
    # Exit with error if any deployment failed
    if [ $backend_status -ne 0 ] || [ $admin_status -ne 0 ]; then
        exit 1
    fi
}

main "$@"
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
