#!/bin/bash
# @fileoverview Request rework on a task - move from Review back to In Progress
# @module workflow/request-rework
#
# @description
# Moves a task from "Review" status back to "In Progress" with feedback.
# Updates both workflow and native status fields. Adds detailed feedback
# comment to guide the rework process.
#
# @dependencies
# - Scripts: ../lib/security-utils.sh, ../lib/error-utils.sh, ../lib/config-utils.sh, ../lib/dry-run-utils.sh, ../lib/field-utils.sh
# - Commands: gh, jq
# - APIs: GitHub GraphQL v4 (updateProjectV2ItemFieldValue)
#
# @usage
# ./request-rework.sh [--dry-run] <issue-number> <feedback-message>
#
# @options
# --dry-run    Preview changes without executing
#
# @example
# ./request-rework.sh 42 "Please add error handling for edge cases"
# ./request-rework.sh --dry-run 42 "Test feedback"

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
if ! validate_dry_run_args "$0" 2 "${ARGS[@]}"; then
    print_dry_run_usage "$0" "<issue-number> <feedback-message>" "42 'Please add error handling'"
    exit $ERR_INVALID_INPUT
fi

ISSUE_NUMBER="${ARGS[0]}"
FEEDBACK_MESSAGE="${ARGS[1]}"

# Validate and sanitize inputs
validate_issue_number "$ISSUE_NUMBER" || exit $ERR_INVALID_INPUT
FEEDBACK_MESSAGE=$(sanitize_text_input "$FEEDBACK_MESSAGE" 1000)  # Allow more text for feedback

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
IN_PROGRESS_OPTION_ID=$(get_field_option_id_dynamic "workflow_status" "In Progress")
NATIVE_IN_PROGRESS_ID=$(get_field_option_id_dynamic "status" "In Progress")

print_dry_run_header "🔄 Requesting Rework for Task #$ISSUE_NUMBER"

# Get issue details and current status
echo "🔍 Checking task status..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would fetch issue data for #$ISSUE_NUMBER${NC}"
    ISSUE_TITLE="Mock Rework Request Issue #$ISSUE_NUMBER"
    PROJECT_ITEM_DATA="mock_data"
    PROJECT_ITEM_ID="MOCK_PROJECT_ITEM_ID"
    CURRENT_STATUS="🟣 Review"
else
    ISSUE_DATA=$(gh api graphql -f query='
      query {
        repository(owner: "'$GITHUB_OWNER'", name: "'$GITHUB_REPO'") {
          issue(number: '$ISSUE_NUMBER') {
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
      }')
    
    ISSUE_TITLE=$(echo $ISSUE_DATA | jq -r '.data.repository.issue.title')
    
    # Find the project item in our project
    PROJECT_ITEM_DATA=$(echo $ISSUE_DATA | jq -r ".data.repository.issue.projectItems.nodes[] | select(.fieldValues.nodes[] | select(.field.id == \"$WORKFLOW_STATUS_FIELD_ID\"))")
    
    if [ -z "$PROJECT_ITEM_DATA" ] || [ "$PROJECT_ITEM_DATA" = "null" ]; then
        echo -e "${RED}❌ Task #$ISSUE_NUMBER not found in project${NC}"
        exit 1
    fi
    
    PROJECT_ITEM_ID=$(echo $PROJECT_ITEM_DATA | jq -r '.id')
    CURRENT_STATUS=$(echo $PROJECT_ITEM_DATA | jq -r ".fieldValues.nodes[] | select(.field.id == \"$WORKFLOW_STATUS_FIELD_ID\") | .name")
fi


echo -e "${BLUE}📋 Task: $ISSUE_TITLE${NC}"
echo -e "${BLUE}📊 Current Status: $CURRENT_STATUS${NC}"

# Validate task is in Review status
if [ "$CURRENT_STATUS" != "🟣 Review" ] && ! is_dry_run; then
    echo -e "${RED}❌ Task #$ISSUE_NUMBER is not in 'Review' status${NC}"
    echo -e "${RED}   Current status: $CURRENT_STATUS${NC}"
    echo -e "${RED}   Only tasks in 'Review' can have rework requested${NC}"
    echo ""
    echo -e "${YELLOW}💡 Available actions based on current status:${NC}"
    case "$CURRENT_STATUS" in
        "🟡 In Progress")
            echo "   Task is already in progress, add feedback as regular comment"
            echo "   Use: gh issue comment $ISSUE_NUMBER --body \"Your feedback\""
            ;;
        "✅ Done")
            echo "   Task is completed. Consider reopening if major changes needed"
            ;;
        "🔵 Ready")
            echo "   Use: ./scripts/start-workflow-task.sh $ISSUE_NUMBER"
            ;;
        "🔒 Blocked")
            echo "   Resolve dependencies first"
            ;;
    esac
    exit 1
fi

echo -e "${GREEN}✅ Task validation passed${NC}"

# Move task back to In Progress
echo ""
echo -e "${YELLOW}🔄 Moving task back to 'In Progress' for rework...${NC}"

# Update Workflow Status field to In Progress
execute_mutation '
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "'$PROJECT_ID'"
      itemId: "'$PROJECT_ITEM_ID'"
      fieldId: "'$WORKFLOW_STATUS_FIELD_ID'"
      value: {
        singleSelectOptionId: "'$IN_PROGRESS_OPTION_ID'"
      }
    }) {
      projectV2Item {
        id
      }
    }
  }' "Update Workflow Status to In Progress" > /dev/null

# Update native Status field to In Progress
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
  }' "Update native Status to In Progress" > /dev/null

echo -e "${ORANGE}🔄 Task #$ISSUE_NUMBER moved back to 'In Progress' for rework${NC}"

# Add rework request comment to issue
echo ""
echo "💬 Adding rework request comment..."
gh_issue_safe comment $ISSUE_NUMBER --body "## 🔄 Rework Requested

### 📝 Feedback from Review
$FEEDBACK_MESSAGE

### 🎯 Next Steps
The task has been moved back to **🟡 In Progress** status for rework based on the feedback above.

### 🔄 Rework Process
1. **Address the feedback** provided above
2. **Make necessary changes** to implementation, documentation, or tests
3. **Re-submit for review** using \`./scripts/review-workflow-task.sh $ISSUE_NUMBER\`

### 📊 Status Change
- **Previous**: 🟣 Review
- **Current**: 🟡 In Progress
- **Requested by**: Human reviewer
- **Requested at**: $(date '+%Y-%m-%d %H:%M:%S')

### 💡 Guidelines for Rework
- Carefully address each point in the feedback
- Test changes thoroughly before re-submitting
- Update documentation if implementation changes
- Consider adding tests for edge cases mentioned

---
*Rework requested through AI-assisted project management review workflow*"

echo ""
echo -e "${ORANGE}================================${NC}"
echo -e "${ORANGE}🔄 REWORK REQUESTED FOR TASK #$ISSUE_NUMBER${NC}"
echo -e "${ORANGE}================================${NC}"
echo ""
echo -e "${BLUE}📋 Task: $ISSUE_TITLE${NC}"
echo -e "${ORANGE}🔄 Status: In Progress (Rework requested)${NC}"
echo -e "${PURPLE}👤 Feedback by: Human reviewer${NC}"
echo ""
echo -e "${YELLOW}📝 Feedback Summary:${NC}"
echo "   $FEEDBACK_MESSAGE"
echo ""
echo -e "${BLUE}🎯 Next Steps for AI:${NC}"
echo "   1. Address the feedback provided"
echo "   2. Make necessary changes to implementation"
echo "   3. Update documentation and tests as needed"
echo "   4. Re-submit for review: ./scripts/review-workflow-task.sh $ISSUE_NUMBER"
echo ""
echo -e "${BLUE}🛠️ Available Commands:${NC}"
echo "   📊 ./scripts/query-workflow-status.sh - Check project status"
echo "   🟣 ./scripts/review-workflow-task.sh $ISSUE_NUMBER - Re-submit for review"
echo "   📋 Visit project: $(jq -r '.project_url' project-info.json)"
echo ""
print_dry_run_summary "Rework Request" "$ISSUE_NUMBER" "Status: 🟣 Review → 🟡 In Progress, Feedback: $FEEDBACK_MESSAGE"

if ! is_dry_run; then
    echo -e "${GREEN}💡 The iterative review process ensures high-quality deliverables!${NC}"
fi