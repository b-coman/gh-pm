#!/bin/bash
# @fileoverview Security utilities for input validation and sanitization
# @module lib/security-utils
#
# @description
# Provides functions to validate and sanitize user inputs to prevent
# injection attacks and ensure safe operation of gh-pm scripts.
#
# @provides
# - validate_issue_number(): Ensure issue number is numeric
# - sanitize_text_input(): Remove dangerous characters from text
# - validate_github_auth(): Check GitHub CLI authentication
# - safe_graphql_string(): Escape strings for GraphQL queries
#
# @usage
# source lib/security-utils.sh

# Validate issue number is numeric only
validate_issue_number() {
    local issue="$1"
    
    if [[ -z "$issue" ]]; then
        echo "Error: Issue number is required" >&2
        return 1
    fi
    
    if ! [[ "$issue" =~ ^[0-9]+$ ]]; then
        echo "Error: Issue number must be numeric (got: $issue)" >&2
        return 1
    fi
    
    # Ensure reasonable bounds
    if (( issue < 1 || issue > 999999 )); then
        echo "Error: Issue number out of valid range (1-999999)" >&2
        return 1
    fi
    
    return 0
}

# Sanitize text input to prevent injection
sanitize_text_input() {
    local input="$1"
    local max_length="${2:-1000}"
    
    # Remove null bytes and control characters
    local clean=$(echo "$input" | tr -d '\0' | sed 's/[[:cntrl:]]//g')
    
    # Truncate to max length
    clean="${clean:0:$max_length}"
    
    echo "$clean"
}

# Escape string for safe GraphQL usage
safe_graphql_string() {
    local input="$1"
    
    # Escape backslashes first, then quotes
    echo "$input" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g'
}

# Validate GitHub CLI authentication
validate_github_auth() {
    if ! gh auth status &>/dev/null; then
        echo "Error: Not authenticated with GitHub CLI" >&2
        echo "Run: gh auth login" >&2
        return 1
    fi
    
    # Check required scopes
    local scopes=$(gh auth status 2>&1 | grep -o "project, read:project" || true)
    if [[ -z "$scopes" ]]; then
        echo "Warning: May need additional scopes. Run:" >&2
        echo "  gh auth refresh -s project,read:project" >&2
    fi
    
    return 0
}

# Validate project ID format
validate_project_id() {
    local project_id="$1"
    
    if [[ -z "$project_id" ]]; then
        echo "Error: Project ID is required" >&2
        return 1
    fi
    
    # GitHub project IDs follow a specific pattern
    if ! [[ "$project_id" =~ ^PVT_[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid project ID format" >&2
        return 1
    fi
    
    return 0
}

# Validate GitHub username
validate_github_username() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        echo "Error: GitHub username is required" >&2
        return 1
    fi
    
    # GitHub usernames: alphanumeric, single hyphens, max 39 chars
    if ! [[ "$username" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$ ]]; then
        echo "Error: Invalid GitHub username format" >&2
        return 1
    fi
    
    return 0
}