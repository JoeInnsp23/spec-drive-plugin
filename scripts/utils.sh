#!/usr/bin/env bash
#
# Utility functions for spec-drive scripts
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# File existence check
file_exists() {
    [ -f "$1" ]
}

dir_exists() {
    [ -d "$1" ]
}

# Create directory if not exists
ensure_dir() {
    if ! dir_exists "$1"; then
        mkdir -p "$1"
        log_info "Created: $1"
    fi
}
