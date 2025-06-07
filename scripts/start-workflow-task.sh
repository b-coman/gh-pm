#!/bin/bash
# Start a workflow task by moving it to "In Progress" status

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared dry-run utilities
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Initialize dry-run mode
init_dry_run "$@"

# Validate arguments (filter out --dry-run)
if ! validate_dry_run_args "$(basename "$0")" 1 "$@"; then
    print_dry_run_usage "$(basename "$0")" "<issue-number>" "39"
    exit 1
fi

# Extract issue number (filtering out --dry-run)
FILTERED_ARGS=()
for arg in "$@"; do
    if [[ "$arg" != "--dry-run" ]]; then
        FILTERED_ARGS+=("$arg")
    fi
done

ISSUE_NUMBER=${FILTERED_ARGS[0]}

# Load project info
if [ ! -f "project-info.json" ]; then
    echo "❌ project-info.json not found. Run setup script first."
    exit 1
fi

PROJECT_ID=$(jq -r '.project_id' project-info.json)
WORKFLOW_STATUS_FIELD_ID=$(jq -r '.workflow_status_field_id' project-info.json)
IN_PROGRESS_OPTION_ID=$(jq -r '.in_progress_option_id' project-info.json)
READY_OPTION_ID=$(jq -r '.ready_option_id' project-info.json)

echo -e "${BLUE}🚀 Starting Task #$ISSUE_NUMBER${NC}"
echo ""

# Get issue details and current status
echo "🔍 Checking task status and dependencies..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would fetch issue data for #$ISSUE_NUMBER${NC}"
    ISSUE_DATA='{"data":{"repository":{"issue":{"id":"MOCK_ID","title":"Mock Issue for Dry Run","body":"Mock issue body for demonstration"}}}}'
    ISSUE_TITLE="Mock Issue for Dry Run #$ISSUE_NUMBER"
    ISSUE_BODY="Mock issue body for demonstration purposes"
else
    ISSUE_DATA=$(gh api graphql -f query='
      query {
        repository(owner: "b-coman", name: "prop-management") {
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
                    ... on ProjectV2ItemFieldTextValue {
                      text
                      field {
                        ... on ProjectV2Field {
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
    ISSUE_BODY=$(echo $ISSUE_DATA | jq -r '.data.repository.issue.body')
fi

# Find the project item in our project
if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would check project item for task #$ISSUE_NUMBER${NC}"
    PROJECT_ITEM_ID=$(generate_mock_project_item_id)
    CURRENT_STATUS="🔵 Ready"
else
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

# Validate task can be started
if [ "$CURRENT_STATUS" != "🔵 Ready" ]; then
    echo -e "${RED}❌ Task #$ISSUE_NUMBER is not ready to start${NC}"
    echo -e "${RED}   Current status: $CURRENT_STATUS${NC}"
    echo -e "${RED}   Only tasks in 'Ready' status can be started${NC}"
    
    if [ "$CURRENT_STATUS" = "🔒 Blocked" ]; then
        echo ""
        echo -e "${YELLOW}💡 This task is blocked by dependencies.${NC}"
        echo -e "${YELLOW}   Complete the blocking tasks first, then this will become Ready.${NC}"
    fi
    
    exit 1
fi

# Check if any other task is already in progress
echo ""
echo "🔍 Checking for other tasks in progress..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would check for other tasks in progress${NC}"
    OTHER_IN_PROGRESS=""  # Mock no conflicts for dry run
else
    OTHER_IN_PROGRESS=$(gh api graphql -f query='
      query {
        node(id: "'$PROJECT_ID'") {
          ... on ProjectV2 {
            items(first: 50) {
              nodes {
                id
                content {
                  ... on Issue {
                    number
                    title
                  }
                }
                fieldValues(first: 20) {
                  nodes {
                    ... on ProjectV2ItemFieldSingleSelectValue {
                      name
                      field {
                        ... on ProjectV2SingleSelectField {
                          id
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }' | jq -r ".data.node.items.nodes[] | select(.fieldValues.nodes[] | select(.field.id == \"$WORKFLOW_STATUS_FIELD_ID\" and .name == \"🟡 In Progress\")) | .content.number")
fi

if [ ! -z "$OTHER_IN_PROGRESS" ]; then
    echo -e "${RED}❌ Another task is already in progress: #$OTHER_IN_PROGRESS${NC}"
    echo -e "${RED}   Only one task can be active at a time${NC}"
    echo -e "${YELLOW}💡 Complete task #$OTHER_IN_PROGRESS first, or use ./scripts/complete-workflow-task.sh $OTHER_IN_PROGRESS${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Task validation passed${NC}"

# Move task to In Progress
echo ""
echo -e "${YELLOW}🔄 Moving task to 'In Progress' status...${NC}"

# Update Workflow Status field
WORKFLOW_MUTATION='
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
  }'

execute_mutation "$WORKFLOW_MUTATION" "Update Workflow Status to In Progress"

# Also update native Status field to In Progress
STATUS_FIELD_ID=$(jq -r '.status_field_id' project-info.json)
NATIVE_IN_PROGRESS_ID="47fc9ee4"  # This is the built-in "In Progress" option ID

echo -e "${YELLOW}🔄 Syncing native Status field...${NC}"

STATUS_MUTATION='
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
  }'

execute_mutation "$STATUS_MUTATION" "Update native Status field to In Progress"

if is_dry_run; then
    print_dry_run_summary "Start Workflow Task" "$ISSUE_NUMBER" "Move to In Progress status, sync native Status field"
else
    echo -e "${GREEN}✅ Task #$ISSUE_NUMBER moved to 'In Progress' (both status fields synced)${NC}"
fi

# Display task details and next steps
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}📋 TASK #$ISSUE_NUMBER NOW ACTIVE${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${GREEN}Title: $ISSUE_TITLE${NC}"
echo ""
echo -e "${YELLOW}📄 Task Description:${NC}"
echo "$ISSUE_BODY"
echo ""
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "   1. Implement the requirements according to acceptance criteria"
echo "   2. Create/modify necessary files and tests"
echo "   3. Validate implementation meets all requirements"
echo "   4. Run: ./scripts/complete-workflow-task.sh $ISSUE_NUMBER"
echo ""
echo -e "${BLUE}📊 Project Status:${NC}"
echo "   • This task is now the active work item"
echo "   • No other tasks can be started until this completes"
echo "   • Dependent tasks will become Ready when this is Done"
echo ""
echo -e "${BLUE}🛠️ Available Commands:${NC}"
echo "   📊 ./scripts/query-workflow-status.sh - Check project status"
echo "   ✅ ./scripts/complete-workflow-task.sh $ISSUE_NUMBER - Mark task complete"
echo "   📋 Visit project: $(jq -r '.project_url' project-info.json)"