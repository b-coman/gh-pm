#!/bin/bash
# @fileoverview Move a task to Review status for human approval
# @module workflow/review-workflow-task
#
# @description
# Transitions a task from "In Progress" to "Review" status, updating both
# native and workflow status fields. Adds a review request comment with
# guidance for the human reviewer.
#
# @dependencies
# - Scripts: ../lib/security-utils.sh, ../lib/error-utils.sh, ../lib/config-utils.sh, ../lib/dry-run-utils.sh, ../lib/field-utils.sh
# - Commands: gh, jq
# - APIs: GitHub GraphQL v4 (updateProjectV2ItemFieldValue)
#
# @usage
# ./review-workflow-task.sh [--dry-run] <issue-number> [review-message]
#
# @options
# --dry-run    Preview changes without executing
#
# @example
# ./review-workflow-task.sh 42 "Implementation complete"
# ./review-workflow-task.sh --dry-run 42

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
    print_dry_run_usage "$0" "<issue-number> [review-message]" "42 'Implementation complete'"
    exit $ERR_INVALID_INPUT
fi

ISSUE_NUMBER="${ARGS[0]}"
REVIEW_MESSAGE="${ARGS[1]:-Implementation complete, ready for human review}"

# Validate and sanitize inputs
validate_issue_number "$ISSUE_NUMBER" || exit $ERR_INVALID_INPUT
REVIEW_MESSAGE=$(sanitize_text_input "$REVIEW_MESSAGE" 500)

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
WORKFLOW_STATUS_FIELD_ID=$(get_field_id_dynamic "workflow_status")
STATUS_FIELD_ID=$(get_field_id_dynamic "status")
NATIVE_IN_PROGRESS_ID=$(get_field_option_id_dynamic "status" "In Progress")
REVIEW_OPTION_ID=$(get_field_option_id_dynamic "workflow_status" "Review")

print_dry_run_header "🟣 Moving Task #$ISSUE_NUMBER to Review"

# Get issue details and current status
echo "🔍 Checking task status..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would fetch issue data for #$ISSUE_NUMBER${NC}"
    ISSUE_TITLE="Mock Review Request Issue #$ISSUE_NUMBER"
    PROJECT_ITEM_DATA="mock_data"
    PROJECT_ITEM_ID="MOCK_PROJECT_ITEM_ID"
    CURRENT_STATUS="🟡 In Progress"
else
    # Build secure GraphQL query using jq (prevents injection)
    QUERY=$(jq -n \
        --arg owner "$(safe_graphql_string "$GITHUB_OWNER")" \
        --arg repo "$(safe_graphql_string "$GITHUB_REPO")" \
        --argjson issue "$ISSUE_NUMBER" \
        '{
            query: "query GetIssue($owner: String!, $repo: String!, $issue: Int!) {
                repository(owner: $owner, name: $repo) {
                    issue(number: $issue) {
                        id
                        title
                        body
                        projectItems(first: 10) {
                            nodes {
                                id
                                fieldValues(first: 20) {
                                    nodes {
                                        ... on ProjectV2ItemFieldSingleSelectValue {
                                            name
                                            optionId
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
    ISSUE_DATA=$(retry_with_backoff 3 2 gh api graphql --input - <<< "$QUERY")
    
    ISSUE_TITLE=$(echo $ISSUE_DATA | jq -r '.data.repository.issue.title')
    
    # Find the project item in our project
    PROJECT_ITEM_DATA=$(echo $ISSUE_DATA | jq -r ".data.repository.issue.projectItems.nodes[] | select(.fieldValues.nodes[] | select(.field.id == \"$WORKFLOW_STATUS_FIELD_ID\"))")
    
    if [ -z "$PROJECT_ITEM_DATA" ] || [ "$PROJECT_ITEM_DATA" = "null" ]; then
        echo -e "${RED}❌ Task #$ISSUE_NUMBER not found in project${NC}"
        exit $ERR_NOT_FOUND
    fi
    
    PROJECT_ITEM_ID=$(echo $PROJECT_ITEM_DATA | jq -r '.id')
    CURRENT_STATUS=$(echo $PROJECT_ITEM_DATA | jq -r ".fieldValues.nodes[] | select(.field.id == \"$WORKFLOW_STATUS_FIELD_ID\") | .name")
fi


echo -e "${BLUE}📋 Task: $ISSUE_TITLE${NC}"
echo -e "${BLUE}📊 Current Status: $CURRENT_STATUS${NC}"

# Validate task can be moved to review
if [ "$CURRENT_STATUS" != "🟡 In Progress" ] && ! is_dry_run; then
    echo -e "${RED}❌ Task #$ISSUE_NUMBER is not in 'In Progress' status${NC}"
    echo -e "${RED}   Current status: $CURRENT_STATUS${NC}"
    echo -e "${RED}   Only tasks in 'In Progress' can be moved to Review${NC}"
    exit $ERR_INVALID_INPUT
fi

echo -e "${GREEN}✅ Task validation passed${NC}"

# Move task to Review
echo ""
echo -e "${YELLOW}🔄 Moving task to 'Review' status...${NC}"

# Update Workflow Status field to Review
execute_mutation '
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "'$PROJECT_ID'"
      itemId: "'$PROJECT_ITEM_ID'"
      fieldId: "'$WORKFLOW_STATUS_FIELD_ID'"
      value: {
        singleSelectOptionId: "'$REVIEW_OPTION_ID'"
      }
    }) {
      projectV2Item {
        id
      }
    }
  }' "Update Workflow Status to Review" > /dev/null

# Keep native Status as In Progress (review is still technically in progress)
echo -e "${YELLOW}🔄 Syncing native Status field...${NC}"
execute_mutation '
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "'$PROJECT_ID'"
      itemId: "'$PROJECT_ITEM_ID'"
      fieldId: "'$STATUS_FIELD_ID'"
      value: {
        singleSelectOptionId: "'$NATIVE_IN_PROGRESS_ID'"
      }
    }) {
      projectV2Item {
        id
      }
    }
  }' "Keep native Status as In Progress" > /dev/null

echo -e "${GREEN}✅ Task #$ISSUE_NUMBER moved to 'Review' status${NC}"

# Add review comment to issue
echo ""
echo "💬 Adding review request comment..."
gh_issue_safe comment $ISSUE_NUMBER --body "## 🟣 Ready for Review

$REVIEW_MESSAGE

### 📋 Review Request
This task has been completed and is ready for human review and approval.

### 🔍 What to Review
- Implementation meets all acceptance criteria
- Code quality and standards compliance
- Integration with existing systems
- Documentation completeness

### 🎯 Next Steps for Reviewer
- **✅ Approve**: \`./scripts/approve-task.sh $ISSUE_NUMBER\` - Move to Done
- **🔄 Request Changes**: \`./scripts/request-rework.sh $ISSUE_NUMBER \"specific feedback\"\` - Return to In Progress
- **🔒 Block**: \`./scripts/block-task.sh $ISSUE_NUMBER \"reason\"\` - Block for dependencies

### 📊 Review Status
- **Status**: 🟣 Review (Awaiting human approval)
- **Submitted**: $(date '+%Y-%m-%d %H:%M:%S')
- **Reviewer**: Human oversight required

---
*Automated review request from AI-assisted project management system*"

echo ""
echo -e "${PURPLE}================================${NC}"
echo -e "${PURPLE}🟣 TASK #$ISSUE_NUMBER IN REVIEW${NC}"
echo -e "${PURPLE}================================${NC}"
echo ""
echo -e "${GREEN}Title: $ISSUE_TITLE${NC}"
echo -e "${PURPLE}Status: 🟣 Review (Awaiting human approval)${NC}"
echo ""
echo -e "${BLUE}🎯 Awaiting Human Review:${NC}"
echo "   The task implementation is complete and ready for approval"
echo "   A human reviewer should assess the work and provide feedback"
echo ""
echo -e "${BLUE}🛠️ Available Commands for Reviewer:${NC}"
echo "   ✅ ./scripts/approve-task.sh $ISSUE_NUMBER - Approve and mark Done"
echo "   🔄 ./scripts/request-rework.sh $ISSUE_NUMBER \"feedback\" - Request changes"
echo "   🔒 ./scripts/block-task.sh $ISSUE_NUMBER \"reason\" - Block for dependencies"
echo "   📊 ./scripts/query-workflow-status.sh - Check project status"
echo ""
print_dry_run_summary "Review Request" "$ISSUE_NUMBER" "Status: 🟡 In Progress → 🟣 Review, Message: $REVIEW_MESSAGE"

if ! is_dry_run; then
    echo -e "${PURPLE}📋 Project Board: $(jq -r '.project_url' project-info.json)${NC}"
fi