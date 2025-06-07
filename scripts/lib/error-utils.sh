#!/bin/bash
# @fileoverview Error handling utilities for robust script execution
# @module lib/error-utils
#
# @description
# Provides standardized error handling, logging, and cleanup functions
# to ensure scripts fail gracefully and provide helpful debugging info.
#
# @provides
# - setup_error_handling(): Configure error traps and handlers
# - log_error(): Log errors with context
# - cleanup_on_exit(): Register cleanup functions
# - retry_with_backoff(): Retry operations with exponential backoff
#
# @usage
# source lib/error-utils.sh
# setup_error_handling

# Standard error codes
readonly ERR_GENERAL=1
readonly ERR_CONFIG=2
readonly ERR_AUTH=3
readonly ERR_API=4
readonly ERR_INVALID_INPUT=5
readonly ERR_NOT_FOUND=6
readonly ERR_CONFLICT=7
readonly ERR_DEPENDENCY=8

# Global cleanup functions array
declare -a CLEANUP_FUNCTIONS=()

# Setup error handling for the script
setup_error_handling() {
    set -eE  # Exit on error, inherit ERR trap
    # Note: set -u commented out for compatibility with existing scripts
    # set -u   # Exit on undefined variable
    set -o pipefail  # Exit on pipe failure
    
    # Set up error trap
    trap 'handle_error $? "$BASH_COMMAND" $LINENO' ERR
    
    # Set up exit trap for cleanup
    trap 'handle_exit' EXIT INT TERM
}

# Handle errors with context
handle_error() {
    local exit_code=$1
    local failed_command="$2"
    local line_number=$3
    
    echo "" >&2
    echo -e "${RED}❌ ERROR: Command failed with exit code $exit_code${NC}" >&2
    echo -e "${RED}   Command: $failed_command${NC}" >&2
    echo -e "${RED}   Line: $line_number${NC}" >&2
    echo -e "${RED}   Script: ${BASH_SOURCE[1]}${NC}" >&2
    echo "" >&2
    
    # Log to file if LOG_FILE is set
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $failed_command (line $line_number, exit $exit_code)" >> "$LOG_FILE"
    fi
    
    # Don't exit here, let the ERR trap handle it
    return $exit_code
}

# Handle script exit with cleanup
handle_exit() {
    local exit_code=$?
    
    # Run all registered cleanup functions
    if [[ ${#CLEANUP_FUNCTIONS[@]} -gt 0 ]]; then
        for cleanup_func in "${CLEANUP_FUNCTIONS[@]}"; do
            if [[ -n "$cleanup_func" ]]; then
                $cleanup_func || true  # Don't fail on cleanup errors
            fi
        done
    fi
    
    # Show exit status if non-zero
    if [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 130 ]]; then  # 130 = Ctrl+C
        echo -e "${YELLOW}Script exited with code: $exit_code${NC}" >&2
    fi
    
    return $exit_code
}

# Register a cleanup function
cleanup_on_exit() {
    local cleanup_func="$1"
    CLEANUP_FUNCTIONS+=("$cleanup_func")
}

# Log error with timestamp
log_error() {
    local message="$1"
    local log_file="${LOG_FILE:-/tmp/gh-pm-error.log}"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" >> "$log_file"
    echo -e "${RED}ERROR: $message${NC}" >&2
}

# Retry operation with exponential backoff
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local initial_delay="${2:-1}"
    shift 2
    local command=("$@")
    
    local attempt=1
    local delay=$initial_delay
    
    while [[ $attempt -le $max_attempts ]]; do
        echo -e "${YELLOW}Attempt $attempt of $max_attempts...${NC}" >&2
        
        if "${command[@]}"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            echo -e "${YELLOW}Retrying in ${delay}s...${NC}" >&2
            sleep "$delay"
            delay=$((delay * 2))  # Exponential backoff
        fi
        
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}Failed after $max_attempts attempts${NC}" >&2
    return 1
}

# Check required commands exist
check_required_commands() {
    local commands=("$@")
    local missing=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Required commands not found: ${missing[*]}${NC}" >&2
        return 1
    fi
    
    return 0
}

# Safe temporary file creation
create_temp_file() {
    local prefix="${1:-gh-pm}"
    local temp_file
    
    temp_file=$(mktemp -t "${prefix}.XXXXXX")
    
    # Register cleanup
    cleanup_on_exit "rm -f '$temp_file'"
    
    echo "$temp_file"
}