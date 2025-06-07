#!/bin/bash
# @fileoverview Securely start a task by moving it to In Progress status
# @module workflow/start-task-secure
#
# @description
# Example of a security-hardened version of start-task.sh that demonstrates
# proper input validation, error handling, and secure API calls.
#
# @dependencies
# - Scripts: lib/config-utils.sh, lib/error-utils.sh, lib/security-utils.sh
# - Commands: gh, jq
# - APIs: GitHub GraphQL v4 (updateProjectV2ItemFieldValue)
#
# @usage
# ./start-task-secure.sh <issue-number>
#
# @example
# ./start-task-secure.sh 42

set -euo pipefail

# Setup script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/error-utils.sh"
source "$SCRIPT_DIR/lib/security-utils.sh"
source "$SCRIPT_DIR/lib/config-utils.sh"

# Setup error handling
setup_error_handling

# Script metadata
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.0.0"

# Cleanup function
cleanup_on_error() {
    echo "Cleaning up after error..." >&2
    # Add any cleanup logic here
}
cleanup_on_exit cleanup_on_error

# Validate prerequisites
echo "🔐 Validating prerequisites..."

# Check authentication
validate_github_auth || exit $ERR_AUTH

# Check required commands
check_required_commands gh jq || exit $ERR_GENERAL

# Parse and validate arguments
if [[ $# -lt 1 ]]; then
    echo "Error: Issue number required" >&2
    echo "Usage: $SCRIPT_NAME <issue-number>" >&2
    exit $ERR_INVALID_INPUT
fi

ISSUE_NUMBER="$1"

# Validate issue number
echo "🔍 Validating input..."
validate_issue_number "$ISSUE_NUMBER" || exit $ERR_INVALID_INPUT

# Validate configuration
echo "⚙️  Loading configuration..."
if ! validate_config; then
    echo "❌ Configuration validation failed. Run './gh-pm configure' to fix." >&2
    exit $ERR_CONFIG
fi

# Load configuration with validation
PROJECT_ID=$(get_project_id)
validate_project_id "$PROJECT_ID" || exit $ERR_CONFIG

GITHUB_OWNER=$(get_github_owner)
validate_github_username "$GITHUB_OWNER" || exit $ERR_CONFIG

GITHUB_REPO=$(get_github_repo)

# Sanitize inputs for GraphQL
OWNER_SAFE=$(safe_graphql_string "$GITHUB_OWNER")
REPO_SAFE=$(safe_graphql_string "$GITHUB_REPO")

echo "🚀 Starting Task #$ISSUE_NUMBER"
echo ""

# Build GraphQL query safely using jq
QUERY=$(jq -n \
    --arg owner "$OWNER_SAFE" \
    --arg repo "$REPO_SAFE" \
    --argjson issue "$ISSUE_NUMBER" \
    --arg project "$PROJECT_ID" \
    '{
        query: "query GetIssue($owner: String!, $repo: String!, $issue: Int!) {
            repository(owner: $owner, name: $repo) {
                issue(number: $issue) {
                    id
                    title
                    body
                    state
                    projectItems(first: 10) {
                        nodes {
                            id
                            project {
                                id
                            }
                            fieldValues(first: 20) {
                                nodes {
                                    ... on ProjectV2ItemFieldSingleSelectValue {
                                        name
                                        field {
                                            ... on ProjectV2SingleSelectField {
                                                id
                                                name
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }",
        variables: {
            owner: $owner,
            repo: $repo,
            issue: $issue
        }
    }')

# Execute query with retry logic
echo "📊 Fetching issue details..."
ISSUE_DATA=$(retry_with_backoff 3 2 gh api graphql --input - <<< "$QUERY")

# Validate response
if [[ -z "$ISSUE_DATA" ]] || ! echo "$ISSUE_DATA" | jq -e '.data.repository.issue' >/dev/null; then
    log_error "Failed to fetch issue #$ISSUE_NUMBER"
    exit $ERR_NOT_FOUND
fi

# Extract issue details safely
ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.title // "Unknown"')
ISSUE_STATE=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.state // "UNKNOWN"')

# Check if issue is open
if [[ "$ISSUE_STATE" != "OPEN" ]]; then
    echo "❌ Issue #$ISSUE_NUMBER is not open (state: $ISSUE_STATE)" >&2
    exit $ERR_INVALID_INPUT
fi

# Find project item for our project
PROJECT_ITEM=$(echo "$ISSUE_DATA" | jq -r --arg pid "$PROJECT_ID" '
    .data.repository.issue.projectItems.nodes[] |
    select(.project.id == $pid) |
    .id')

if [[ -z "$PROJECT_ITEM" ]]; then
    echo "❌ Issue #$ISSUE_NUMBER is not in the configured project" >&2
    exit $ERR_NOT_FOUND
fi

echo "✅ Found issue: $ISSUE_TITLE"
echo "📋 Project item: $PROJECT_ITEM"

# The rest of the script would continue with the same security patterns:
# - Validate all inputs
# - Use parameterized queries
# - Handle errors gracefully
# - Retry on transient failures
# - Log important operations

echo ""
echo "✅ Task #$ISSUE_NUMBER is ready to start"
echo ""
echo "🔒 Security features demonstrated:"
echo "  - Input validation for all parameters"
echo "  - Secure GraphQL query construction"
echo "  - Error handling with cleanup"
echo "  - Authentication verification"
echo "  - Retry logic for API calls"