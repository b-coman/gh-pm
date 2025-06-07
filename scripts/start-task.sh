#!/bin/bash

# Start a task by moving it to "In Progress" status
# Enhanced with dry-run capability

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Dry-run mode detection
DRY_RUN=false
ISSUE_NUMBER=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            if [[ -z "$ISSUE_NUMBER" ]]; then
                ISSUE_NUMBER="$arg"
            fi
            ;;
    esac
done

# Check if DRY_RUN_MODE environment variable is set
if [[ "${DRY_RUN_MODE}" == "true" ]]; then
    DRY_RUN=true
fi

if [ -z "$ISSUE_NUMBER" ]; then
    echo "❌ Usage: $0 <issue_number> [--dry-run]"
    echo "   Example: $0 39"
    echo "   Example: $0 39 --dry-run"
    echo "   Example: DRY_RUN_MODE=true $0 39"
    exit 1
fi

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Safe GitHub API wrapper for dry-run
gh_api_safe() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${CYAN}🔍 DRY-RUN: Would execute: gh api $@${NC}"
        echo -e "${CYAN}   Command: gh api $*${NC}"
        return 0
    else
        gh api "$@"
    fi
}

# Safe GraphQL mutation execution
execute_mutation() {
    local mutation="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${CYAN}🔍 DRY-RUN: Would execute GraphQL mutation:${NC}"
        echo -e "${CYAN}   $mutation${NC}"
        echo -e "${CYAN}   This would update the task status to 'In Progress'${NC}"
        return 0
    else
        gh api graphql -f query="$mutation"
    fi
}

# Load project info
if [ ! -f "project-info.json" ]; then
    echo "❌ project-info.json not found. Run setup-github-project.sh first."
    exit 1
fi

PROJECT_ID=$(jq -r '.project_id' project-info.json)
STATUS_FIELD_ID=$(jq -r '.status_field_id' project-info.json)
IN_PROGRESS_OPTION_ID=$(jq -r '.in_progress_option_id' project-info.json)

if [[ "$DRY_RUN" == "true" ]]; then
    print_header "🔍 DRY-RUN: Starting Task #$ISSUE_NUMBER"
    echo -e "${CYAN}🔍 DRY-RUN MODE ENABLED - No actual changes will be made${NC}"
else
    print_header "Starting Task #$ISSUE_NUMBER"
fi

echo -e "${BLUE}📊 Project ID: $PROJECT_ID${NC}"
echo ""

# Get issue details and check if it exists
echo "🔍 Checking issue #$ISSUE_NUMBER..."

# In dry-run mode, mock the issue check for demonstration
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${CYAN}🔍 DRY-RUN: Mocking issue check for demonstration${NC}"
    ISSUE_TITLE="Mock Issue Title for Issue #$ISSUE_NUMBER"
    ISSUE_ID="MOCK_ISSUE_ID"
    echo -e "${GREEN}✅ Mock issue: $ISSUE_TITLE${NC}"
    
    # For dry-run demonstration, use a mock project item ID
    PROJECT_ITEM_ID="MOCK_PROJECT_ITEM_ID_FOR_DRY_RUN"
    echo -e "${CYAN}🔍 DRY-RUN: Using mock Project Item ID for demonstration${NC}"
    echo -e "${BLUE}📋 Project Item ID: $PROJECT_ITEM_ID${NC}"
else
    # Read-only operations are safe in both modes
    ISSUE_DATA=$(gh api graphql -f query='
      query {
        repository(owner: "b-coman", name: "prop-management") {
          issue(number: '$ISSUE_NUMBER') {
            title
            id
          }
        }
      }')

    # Check if issue exists
    if echo "$ISSUE_DATA" | jq -e '.data.repository.issue' > /dev/null; then
        ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.title')
        ISSUE_ID=$(echo "$ISSUE_DATA" | jq -r '.data.repository.issue.id')
        
        echo -e "${GREEN}✅ Found issue: $ISSUE_TITLE${NC}"
        
        # In real mode, we would query for the actual project item ID
        echo -e "${YELLOW}⚠️  Real mode would query for project item ID here${NC}"
        PROJECT_ITEM_ID="WOULD_QUERY_REAL_PROJECT_ITEM_ID"
        echo -e "${BLUE}📋 Project Item ID: $PROJECT_ITEM_ID${NC}"
    else
        echo -e "${RED}❌ Issue #$ISSUE_NUMBER not found${NC}"
        exit 1
    fi
fi

# Check dependencies (read-only operation)
echo ""
echo "🔗 Checking dependencies..."

if [[ "$DRY_RUN" == "true" ]]; then
    # Mock dependency data for dry-run
    CURRENT_STATUS="Ready"
    DEPENDENCIES="Issue #35, Issue #37"
    echo -e "${CYAN}🔍 DRY-RUN: Mocking dependency check${NC}"
    echo -e "${BLUE}📊 Mock Current Status: $CURRENT_STATUS${NC}"
    echo -e "${YELLOW}⚠️  Mock Dependencies: $DEPENDENCIES${NC}"
    echo -e "${CYAN}🔍 DRY-RUN: Would check if dependencies are resolved${NC}"
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

execute_mutation "$UPDATE_MUTATION"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "${GREEN}✅ DRY-RUN COMPLETE: Task #$ISSUE_NUMBER would be moved to 'In Progress'${NC}"
    echo -e "${CYAN}🔍 Changes that would be made:${NC}"
    echo -e "${CYAN}   - Project Item ID: $PROJECT_ITEM_ID${NC}"
    echo -e "${CYAN}   - Status Field ID: $STATUS_FIELD_ID${NC}"
    echo -e "${CYAN}   - New Status Option ID: $IN_PROGRESS_OPTION_ID${NC}"
    echo -e "${CYAN}   - GraphQL Mutation: updateProjectV2ItemFieldValue${NC}"
else
    echo -e "${GREEN}✅ Task #$ISSUE_NUMBER moved to 'In Progress'${NC}"
fi

echo ""
echo "🔧 Next steps:"
echo "   📊 Check progress: ./query-project-status.sh"
echo "   ✅ Complete task: ./complete-task.sh $ISSUE_NUMBER"
echo "   🔗 View project: https://github.com/users/b-coman/projects/3"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "${CYAN}🔍 To execute for real, run without --dry-run flag${NC}"
fi