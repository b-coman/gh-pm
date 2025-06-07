#!/bin/bash
# @fileoverview Start a task by moving it to In Progress status (simple version)
# @module workflow/start-task
#
# @description
# Simple version of task starter that moves a task to "In Progress" status.
# For advanced workflow with dependency checking, use start-workflow-task.sh instead.
#
# @dependencies
# - Scripts: ../lib/security-utils.sh, ../lib/error-utils.sh, ../lib/config-utils.sh, ../lib/dry-run-utils.sh, ../lib/field-utils.sh
# - Commands: gh, jq
# - APIs: GitHub GraphQL v4 (updateProjectV2ItemFieldValue)
#
# @usage
# ./start-task.sh [--dry-run] <issue-number>
#
# @options
# --dry-run    Preview changes without executing
#
# @example
# ./start-task.sh 42
# ./start-task.sh --dry-run 42

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

# Initialize dry-run mode
init_dry_run "$@"

# Parse issue number from arguments
ISSUE_NUMBER=""
for arg in "$@"; do
    case $arg in
        --dry-run)
            # Skip dry-run flag
            ;;
        *)
            if [[ -z "$ISSUE_NUMBER" ]]; then
                ISSUE_NUMBER="$arg"
            fi
            ;;
    esac
done

if [ -z "$ISSUE_NUMBER" ]; then
    print_dry_run_usage "$0" "<issue_number>" "39"
    exit 1
fi

# Validate issue number
validate_issue_number "$ISSUE_NUMBER" || exit $ERR_INVALID_INPUT

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed. Run './gh-pm configure' to fix issues."
    exit 1
fi

# Load configuration values
PROJECT_ID=$(get_project_id)
GITHUB_OWNER=$(get_github_owner)
GITHUB_REPO=$(get_github_repo)
STATUS_FIELD_ID=$(get_field_id_dynamic "status")
IN_PROGRESS_OPTION_ID=$(get_field_option_id_dynamic "status" "In Progress")
IN_PROGRESS_OPTION_ID=$(get_field_option "status" "in_progress")

print_dry_run_header "Starting Task #$ISSUE_NUMBER"

echo -e "${BLUE}📊 Project ID: $PROJECT_ID${NC}"
echo ""

# Get issue details and check if it exists
echo "🔍 Checking issue #$ISSUE_NUMBER..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Mocking issue check for demonstration${NC}"
    ISSUE_TITLE="Mock Issue Title for Issue #$ISSUE_NUMBER"
    ISSUE_ID="MOCK_ISSUE_ID"
    echo -e "${GREEN}✅ Mock issue: $ISSUE_TITLE${NC}"
    
    # For dry-run demonstration, use a mock project item ID
    PROJECT_ITEM_ID=$(generate_mock_project_item_id)
    echo -e "${CYAN}🔍 DRY-RUN: Using mock Project Item ID for demonstration${NC}"
    echo -e "${BLUE}📋 Project Item ID: $PROJECT_ITEM_ID${NC}"
else
    # Get issue details and project item ID
    ISSUE_DATA=$(gh api graphql -f query='
      query {
        repository(owner: "'$GITHUB_OWNER'", name: "'$GITHUB_REPO'") {
          issue(number: '$ISSUE_NUMBER') {
            title
            id
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
      }')

    # Check if issue exists
    if echo "$ISSUE_DATA" | jq -e '.data.repository.issue' > /dev/null; then
        ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.title')
        ISSUE_ID=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.id')
        PROJECT_ITEM_ID=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.projectItems.nodes[] | select(.project.id == "'$PROJECT_ID'") | .id')
        
        echo -e "${GREEN}✅ Found issue: $ISSUE_TITLE${NC}"
        
        if [ "$PROJECT_ITEM_ID" = "null" ] || [ -z "$PROJECT_ITEM_ID" ]; then
            echo -e "${RED}❌ Issue #$ISSUE_NUMBER not found in project${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}📋 Project Item ID: $PROJECT_ITEM_ID${NC}"
    else
        echo -e "${RED}❌ Issue #$ISSUE_NUMBER not found${NC}"
        exit 1
    fi
fi

# Check dependencies (read-only operation)
echo ""
echo "🔗 Checking dependencies..."

if is_dry_run; then
    # Mock dependency data for dry-run
    CURRENT_STATUS=$(generate_mock_status_data)
    DEPENDENCIES=$(generate_mock_dependencies)
    echo -e "${CYAN}🔍 DRY-RUN: Mocking dependency check${NC}"
    echo -e "${BLUE}📊 Mock Current Status: $CURRENT_STATUS${NC}"
    echo -e "${YELLOW}⚠️  Mock Dependencies: $DEPENDENCIES${NC}"
    echo -e "${CYAN}🔍 DRY-RUN: Would check if dependencies are resolved${NC}"
else
    # Get current status and dependencies
    CURRENT_STATUS_QUERY='
      query {
        node(id: "'$PROJECT_ITEM_ID'") {
          ... on ProjectV2Item {
            fieldValueByName(name: "Status") {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
              }
            }
            fieldValueByName(name: "Dependencies") {
              ... on ProjectV2ItemFieldTextValue {
                text
              }
            }
          }
        }
      }'

    CURRENT_DATA=$(gh api graphql -f query="$CURRENT_STATUS_QUERY")
    CURRENT_STATUS=$(echo "$CURRENT_DATA" | jq -r '.data.node.fieldValueByName.name // "None"')
    DEPENDENCIES=$(echo "$CURRENT_DATA" | jq -r '.data.node.fieldValueByName.text // ""')

    echo -e "${BLUE}📊 Current Status: $CURRENT_STATUS${NC}"

    if [ -n "$DEPENDENCIES" ] && [ "$DEPENDENCIES" != "null" ]; then
        echo -e "${YELLOW}⚠️  Dependencies found: $DEPENDENCIES${NC}"
        echo "🔍 Checking if dependencies are resolved..."
        # Dependency checking logic would go here
    fi
fi

# Update status to In Progress
echo ""
echo "🚀 Moving task to 'In Progress'..."

UPDATE_MUTATION='
  mutation {
    updateProjectV2ItemFieldValue(
      input: {
        projectId: "'$PROJECT_ID'"
        itemId: "'$PROJECT_ITEM_ID'"
        fieldId: "'$STATUS_FIELD_ID'"
        value: {
          singleSelectOptionId: "'$IN_PROGRESS_OPTION_ID'"
        }
      }
    ) {
      projectV2Item {
        id
      }
    }
  }'

execute_mutation "$UPDATE_MUTATION" "Move issue #$ISSUE_NUMBER to In Progress"

if is_dry_run; then
    print_dry_run_summary "Start Task" "$ISSUE_NUMBER" "Status: Ready → In Progress"
else
    echo -e "${GREEN}✅ Task #$ISSUE_NUMBER moved to 'In Progress'${NC}"
fi

echo ""
echo "🔧 Next steps:"
echo "   📊 Check progress: ./gh-pm status"
echo "   ✅ Complete task: ./gh-pm complete $ISSUE_NUMBER"
echo "   🔗 View project: $(get_project_url)"

if is_dry_run; then
    echo ""
    echo -e "${CYAN}🔍 To execute for real, run without --dry-run flag${NC}"
fi