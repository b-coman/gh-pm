#!/bin/bash

# Shared dry-run utilities for GitHub Project AI Manager scripts
# This file provides common functions for implementing dry-run capability

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global dry-run state
DRY_RUN=false

# Initialize dry-run mode based on arguments and environment
init_dry_run() {
    # Check for --dry-run flag in arguments
    for arg in "$@"; do
        if [[ "$arg" == "--dry-run" ]]; then
            DRY_RUN=true
            break
        fi
    done
    
    # Check environment variable
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        DRY_RUN=true
    fi
    
    # Display dry-run status if enabled
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${CYAN}🔍 DRY-RUN MODE ENABLED - No actual changes will be made${NC}"
    fi
}

# Check if currently in dry-run mode
is_dry_run() {
    [[ "$DRY_RUN" == "true" ]]
}

# Safe GitHub API wrapper for dry-run
gh_api_safe() {
    if is_dry_run; then
        echo -e "${CYAN}🔍 DRY-RUN: Would execute: gh api $*${NC}"
        return 0
    else
        gh api "$@"
    fi
}

# Safe GitHub issue command wrapper
gh_issue_safe() {
    if is_dry_run; then
        echo -e "${CYAN}🔍 DRY-RUN: Would execute: gh issue $*${NC}"
        return 0
    else
        gh issue "$@"
    fi
}

# Safe GraphQL mutation execution
execute_mutation() {
    local mutation="$1"
    local description="${2:-GraphQL mutation}"
    
    if is_dry_run; then
        echo -e "${CYAN}🔍 DRY-RUN: Would execute $description${NC}"
        return 0
    else
        gh api graphql -f query="$mutation"
    fi
}

# Mock data generator for dry-run mode
generate_mock_issue_data() {
    local issue_number="$1"
    if is_dry_run; then
        echo "Mock Issue Title for Issue #$issue_number"
    fi
}

generate_mock_project_item_id() {
    if is_dry_run; then
        echo "MOCK_PROJECT_ITEM_ID_FOR_DRY_RUN"
    fi
}

# Enhanced print functions for dry-run
print_dry_run_header() {
    local title="$1"
    if is_dry_run; then
        echo -e "${PURPLE}================================${NC}"
        echo -e "${PURPLE}🔍 DRY-RUN: $title${NC}"
        echo -e "${PURPLE}================================${NC}"
        echo ""
    else
        echo -e "${PURPLE}================================${NC}"
        echo -e "${PURPLE}$title${NC}"
        echo -e "${PURPLE}================================${NC}"
        echo ""
    fi
}

# Simple header function for consistency
print_header() {
    local title="$1"
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$title${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Mock dependency and status data
generate_mock_status_data() {
    if is_dry_run; then
        echo "Ready"
    fi
}

generate_mock_dependencies() {
    if is_dry_run; then
        echo "Issue #35, Issue #37"
    fi
}

# Safe issue verification with mocking
verify_issue_safe() {
    local issue_number="$1"
    local repo_owner="${2:-b-coman}"
    local repo_name="${3:-prop-management}"
    
    if is_dry_run; then
        echo -e "${CYAN}🔍 DRY-RUN: Mocking issue check for demonstration${NC}"
        local mock_title=$(generate_mock_issue_data "$issue_number")
        echo -e "${GREEN}✅ Mock issue: $mock_title${NC}"
        return 0
    else
        # Real issue verification
        ISSUE_DATA=$(gh api graphql -f query='
          query {
            repository(owner: "'$repo_owner'", name: "'$repo_name'") {
              issue(number: '$issue_number') {
                title
                id
              }
            }
          }')
        
        if echo "$ISSUE_DATA" | jq -e '.data.repository.issue' > /dev/null; then
            local issue_title=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.title')
            echo -e "${GREEN}✅ Found issue: $issue_title${NC}"
            return 0
        else
            echo -e "${RED}❌ Issue #$issue_number not found${NC}"
            return 1
        fi
    fi
}

# Print dry-run completion summary
print_dry_run_summary() {
    local operation="$1"
    local issue_number="$2"
    local additional_info="$3"
    
    if is_dry_run; then
        echo ""
        echo -e "${GREEN}✅ DRY-RUN COMPLETE: $operation for Issue #$issue_number${NC}"
        echo -e "${CYAN}🔍 Changes that would be made:${NC}"
        if [[ -n "$additional_info" ]]; then
            echo -e "${CYAN}   $additional_info${NC}"
        fi
        echo ""
        echo -e "${CYAN}🔍 To execute for real, run without --dry-run flag${NC}"
    else
        echo -e "${GREEN}✅ $operation completed for Issue #$issue_number${NC}"
    fi
}

# Help text generator
print_dry_run_usage() {
    local script_name="$1"
    local basic_usage="$2"
    local example_issue="${3:-39}"
    
    echo "❌ Usage: $script_name $basic_usage [--dry-run]"
    echo "   Example: $script_name $example_issue"
    echo "   Example: $script_name $example_issue --dry-run"
    echo "   Example: DRY_RUN_MODE=true $script_name $example_issue"
}

# Validation helper
validate_dry_run_args() {
    local script_name="$1"
    local required_args="$2"
    shift 2
    local args=("$@")
    
    # Filter out --dry-run from argument count
    local filtered_args=()
    for arg in "${args[@]}"; do
        if [[ "$arg" != "--dry-run" ]]; then
            filtered_args+=("$arg")
        fi
    done
    
    if [[ ${#filtered_args[@]} -lt $required_args ]]; then
        return 1
    fi
    return 0
}