#!/bin/bash
# @fileoverview Complete a task by moving it to Done status and checking dependencies
# @module workflow/complete-task
#
# @description
# Moves a task to "Done" status in both workflow and native status fields.
# Automatically checks for dependent tasks and notifies about newly available work.
# Adds completion comment to the issue.
#
# @dependencies
# - Scripts: ../lib/security-utils.sh, ../lib/error-utils.sh, ../lib/config-utils.sh, ../lib/dry-run-utils.sh, ../lib/field-utils.sh
# - Commands: gh, jq
# - APIs: GitHub GraphQL v4 (updateProjectV2ItemFieldValue)
#
# @usage
# ./complete-task.sh [--dry-run] <issue-number> [completion-message]
#
# @options
# --dry-run    Preview changes without executing
#
# @example
# ./complete-task.sh 42 "Feature implementation completed"
# ./complete-task.sh --dry-run 42

set -eo pipefail

# Load utilities in dependency order
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/error-utils.sh"
source "$SCRIPT_DIR/../lib/security-utils.sh"
source "$SCRIPT_DIR/../lib/config-utils.sh"
source "$SCRIPT_DIR/../lib/dry-run-utils.sh"
source "$SCRIPT_DIR/../lib/field-utils.sh"

# Setup error handling
setup_error_handling

# Validate authentication first
validate_github_auth || exit $ERR_AUTH

# Parse arguments and initialize dry-run mode
init_dry_run "$@"

# Extract non-dry-run arguments
ARGS=()
for arg in "$@"; do
    if [[ "$arg" != "--dry-run" ]]; then
        ARGS+=("$arg")
    fi
done

# Validate arguments
if ! validate_dry_run_args "$0" 1 "${ARGS[@]}"; then
    print_dry_run_usage "$0" "<issue_number> [completion_comment]"
    exit $ERR_INVALID_INPUT
fi

ISSUE_NUMBER="${ARGS[0]}"
COMPLETION_COMMENT="${ARGS[1]:-Task completed via automation}"

# Validate and sanitize inputs
validate_issue_number "$ISSUE_NUMBER" || exit $ERR_INVALID_INPUT
COMPLETION_COMMENT=$(sanitize_text_input "$COMPLETION_COMMENT" 500)

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed. Run './gh-pm configure' to fix issues."
    exit $ERR_CONFIG
fi

# Load configuration values
PROJECT_ID=$(get_project_id)
GITHUB_OWNER=$(get_github_owner)
GITHUB_REPO=$(get_github_repo)

# Validate loaded configuration
validate_project_id "$PROJECT_ID" || exit $ERR_CONFIG
validate_github_username "$GITHUB_OWNER" || exit $ERR_CONFIG
STATUS_FIELD_ID=$(get_field_id_dynamic "status")
WORKFLOW_STATUS_FIELD_ID=$(get_field_id_dynamic "workflow_status")
DONE_OPTION_ID=$(get_field_option_id_dynamic "workflow_status" "Done")
NATIVE_DONE_ID=$(get_field_option_id_dynamic "status" "Done")
WORKFLOW_DONE_OPTION_ID="$DONE_OPTION_ID"  # Alias for consistency

print_dry_run_header "Completing Task #$ISSUE_NUMBER"

echo -e "${BLUE}📊 Project ID: $PROJECT_ID${NC}"
echo ""

# Verify issue exists
echo "🔍 Checking issue #$ISSUE_NUMBER..."

if ! verify_issue_safe "$ISSUE_NUMBER"; then
    exit 1
fi

# Get project item ID (mocked in dry-run)
if is_dry_run; then
    PROJECT_ITEM_ID=$(generate_mock_project_item_id)
    echo -e "${CYAN}🔍 DRY-RUN: Using mock Project Item ID for demonstration${NC}"
    echo -e "${BLUE}📋 Project Item ID: $PROJECT_ITEM_ID${NC}"
else
    # Query for actual project item ID
    echo "🔍 Getting project item ID..."
    
    PROJECT_ITEM_QUERY='
      query {
        repository(owner: "'$GITHUB_OWNER'", name: "'$GITHUB_REPO'") {
          issue(number: '$ISSUE_NUMBER') {
            projectItems(first: 10) {
              nodes {
                id
                project {
                  id
                }
              }
            }
          }
        }
      }'
    
    PROJECT_ITEM_DATA=$(gh api graphql -f query="$PROJECT_ITEM_QUERY")
    
    # Find the project item ID for our project
    PROJECT_ITEM_ID=$(echo "$PROJECT_ITEM_DATA" | jq -r --arg project_id "$PROJECT_ID" '
      .data.repository.issue.projectItems.nodes[] | 
      select(.project.id == $project_id) | 
      .id')
    
    if [ -z "$PROJECT_ITEM_ID" ] || [ "$PROJECT_ITEM_ID" = "null" ]; then
        echo -e "${RED}❌ Issue #$ISSUE_NUMBER is not in the project. Add it first.${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📋 Project Item ID: $PROJECT_ITEM_ID${NC}"
fi

# Check current status
echo ""
echo "📊 Checking current status..."

if is_dry_run; then
    CURRENT_STATUS="In Progress"
    echo -e "${CYAN}🔍 DRY-RUN: Mocking status check${NC}"
    echo -e "${BLUE}📊 Mock Current Status: $CURRENT_STATUS${NC}"
else
    # Get current status
    CURRENT_STATUS_QUERY='
      query {
        node(id: "'$PROJECT_ITEM_ID'") {
          ... on ProjectV2Item {
            fieldValueByName(name: "Status") {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
              }
            }
          }
        }
      }'
    
    CURRENT_DATA=$(gh api graphql -f query="$CURRENT_STATUS_QUERY")
    CURRENT_STATUS=$(echo "$CURRENT_DATA" | jq -r '.data.node.fieldValueByName.name // "None"')
    echo -e "${BLUE}📊 Current Status: $CURRENT_STATUS${NC}"
fi

# Update status to Done
echo ""
echo "✅ Moving task to 'Done'..."

# Update regular Status field
UPDATE_STATUS_MUTATION='
  mutation {
    updateProjectV2ItemFieldValue(
      input: {
        projectId: "'$PROJECT_ID'"
        itemId: "'$PROJECT_ITEM_ID'"
        fieldId: "'$STATUS_FIELD_ID'"
        value: {
          singleSelectOptionId: "'$DONE_OPTION_ID'"
        }
      }
    ) {
      projectV2Item {
        id
      }
    }
  }'

execute_mutation "$UPDATE_STATUS_MUTATION" "Status field update to Done"

# Update Workflow Status field
echo "✅ Moving workflow status to 'Done'..."

UPDATE_WORKFLOW_MUTATION='
  mutation {
    updateProjectV2ItemFieldValue(
      input: {
        projectId: "'$PROJECT_ID'"
        itemId: "'$PROJECT_ITEM_ID'"
        fieldId: "'$WORKFLOW_STATUS_FIELD_ID'"
        value: {
          singleSelectOptionId: "'$WORKFLOW_DONE_OPTION_ID'"
        }
      }
    ) {
      projectV2Item {
        id
      }
    }
  }'

execute_mutation "$UPDATE_WORKFLOW_MUTATION" "Workflow Status field update to Done"

# Add completion comment
echo ""
echo "💬 Adding completion comment..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would add comment: \"$COMPLETION_COMMENT\"${NC}"
else
    gh_issue_safe comment "$ISSUE_NUMBER" --body "✅ **Task Completed**

$COMPLETION_COMMENT

Task automatically moved to Done status.
"
fi

# Check for dependent tasks
echo ""
echo "🔗 Checking for dependent tasks..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would search for tasks that depend on Issue #$ISSUE_NUMBER${NC}"
    echo -e "${CYAN}🔍 DRY-RUN: Would check if any blocked tasks can now be moved to Ready${NC}"
    echo -e "${GREEN}✅ Mock: Found 2 dependent tasks that can now proceed${NC}"
    echo -e "${CYAN}   - Issue #45: Data Validation Components${NC}"
    echo -e "${CYAN}   - Issue #46: Integration Testing${NC}"
else
    # Check for dependent tasks
    DEPENDENCY_QUERY='
      query {
        repository(owner: "'$GITHUB_OWNER'", name: "'$GITHUB_REPO'") {
          issues(first: 100, states: OPEN) {
            nodes {
              number
              title
              projectItems(first: 10) {
                nodes {
                  fieldValueByName(name: "Dependencies") {
                    ... on ProjectV2ItemFieldTextValue {
                      text
                    }
                  }
                }
              }
            }
          }
        }
      }'
    
    DEPENDENCY_DATA=$(gh api graphql -f query="$DEPENDENCY_QUERY")
    
    # Find tasks that depend on this issue
    DEPENDENT_TASKS=$(echo "$DEPENDENCY_DATA" | jq -r --arg issue_num "$ISSUE_NUMBER" '
      .data.repository.issues.nodes[] |
      select(.projectItems.nodes[].fieldValueByName.text // "" | contains("Issue #\($issue_num)")) |
      "#\(.number): \(.title)"' | head -5)
    
    if [ -n "$DEPENDENT_TASKS" ]; then
        echo -e "${GREEN}✅ Found dependent tasks that can now proceed:${NC}"
        echo "$DEPENDENT_TASKS" | while IFS= read -r task; do
            echo -e "${CYAN}   - $task${NC}"
        done
    else
        echo "No dependent tasks found."
    fi
fi

# Print summary
if is_dry_run; then
    print_dry_run_summary "Task completion" "$ISSUE_NUMBER" "Status: Done, Comment added, Dependencies checked"
else
    echo -e "${GREEN}✅ Task #$ISSUE_NUMBER completed successfully${NC}"
fi

echo ""
echo "🔧 Next steps:"
echo "   📊 Check progress: ./gh-pm status"
echo "   🔗 Check dependencies: ./gh-pm dependencies"
echo "   🔵 Move ready tasks: ./gh-pm ready [issue]"
echo "   🔗 View project: $(get_project_url)"

if is_dry_run; then
    echo ""
    echo -e "${CYAN}🔍 To execute for real, run without --dry-run flag${NC}"
fi