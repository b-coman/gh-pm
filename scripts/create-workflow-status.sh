#!/bin/bash
# Create a new Workflow Status field with our complete workflow

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared dry-run utilities
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Initialize dry-run mode
init_dry_run "$@"

# Load project info
if [ ! -f "project-info.json" ]; then
    echo "❌ project-info.json not found. Run setup script first."
    exit 1
fi

PROJECT_ID=$(jq -r '.project_id' project-info.json)

print_dry_run_header "Creating Workflow Status Field"

# Create new Status field with complete workflow
WORKFLOW_MUTATION='
  mutation {
    createProjectV2Field(input: {
      projectId: "'$PROJECT_ID'"
      dataType: SINGLE_SELECT
      name: "Workflow Status"
      singleSelectOptions: [
        {name: "📋 Backlog", color: GRAY, description: "Future work, not yet analyzed"},
        {name: "🔵 Ready", color: BLUE, description: "Can start immediately - no blocking dependencies"},
        {name: "🔒 Blocked", color: RED, description: "Waiting for dependencies to complete"},
        {name: "🟡 In Progress", color: YELLOW, description: "Currently active work"},
        {name: "🟣 Review", color: PURPLE, description: "Awaiting human approval/review"},
        {name: "✅ Done", color: GREEN, description: "Completed and validated"}
      ]
    }) {
      projectV2Field {
        ... on ProjectV2SingleSelectField {
          id
          name
          options {
            id
            name
            color
          }
        }
      }
    }
  }'

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would create Workflow Status field with 6 options${NC}"
    # Mock response data for dry run
    WORKFLOW_STATUS_FIELD_ID="MOCK_WORKFLOW_STATUS_FIELD_ID"
    BACKLOG_OPTION_ID="MOCK_BACKLOG_OPTION"
    READY_OPTION_ID="MOCK_READY_OPTION"
    BLOCKED_OPTION_ID="MOCK_BLOCKED_OPTION"
    IN_PROGRESS_OPTION_ID="MOCK_IN_PROGRESS_OPTION"
    REVIEW_OPTION_ID="MOCK_REVIEW_OPTION"
    DONE_OPTION_ID="MOCK_DONE_OPTION"
else
    WORKFLOW_STATUS_RESPONSE=$(execute_mutation "$WORKFLOW_MUTATION" "Create Workflow Status field")
    
    WORKFLOW_STATUS_FIELD_ID=$(echo $WORKFLOW_STATUS_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.id')
    
    # Extract all option IDs
    BACKLOG_OPTION_ID=$(echo $WORKFLOW_STATUS_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name=="📋 Backlog") | .id')
    READY_OPTION_ID=$(echo $WORKFLOW_STATUS_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name=="🔵 Ready") | .id')
    BLOCKED_OPTION_ID=$(echo $WORKFLOW_STATUS_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name=="🔒 Blocked") | .id')
    IN_PROGRESS_OPTION_ID=$(echo $WORKFLOW_STATUS_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name=="🟡 In Progress") | .id')
    REVIEW_OPTION_ID=$(echo $WORKFLOW_STATUS_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name=="🟣 Review") | .id')
    DONE_OPTION_ID=$(echo $WORKFLOW_STATUS_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.options[] | select(.name=="✅ Done") | .id')
fi

echo "✅ Workflow Status field created: $WORKFLOW_STATUS_FIELD_ID"
echo "   📋 Backlog: $BACKLOG_OPTION_ID"
echo "   🔵 Ready: $READY_OPTION_ID"
echo "   🔒 Blocked: $BLOCKED_OPTION_ID"
echo "   🟡 In Progress: $IN_PROGRESS_OPTION_ID"
echo "   🟣 Review: $REVIEW_OPTION_ID"
echo "   ✅ Done: $DONE_OPTION_ID"

# Update project-info.json with workflow status info
if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would update project-info.json with workflow status field info${NC}"
else
    jq --arg workflow_status_field_id "$WORKFLOW_STATUS_FIELD_ID" \
       --arg backlog_option_id "$BACKLOG_OPTION_ID" \
       --arg ready_option_id "$READY_OPTION_ID" \
       --arg blocked_option_id "$BLOCKED_OPTION_ID" \
       --arg in_progress_option_id "$IN_PROGRESS_OPTION_ID" \
       --arg review_option_id "$REVIEW_OPTION_ID" \
       --arg done_option_id "$DONE_OPTION_ID" \
       '. + {
         "workflow_status_field_id": $workflow_status_field_id,
         "backlog_option_id": $backlog_option_id,
         "ready_option_id": $ready_option_id,
         "blocked_option_id": $blocked_option_id,
         "in_progress_option_id": $in_progress_option_id,
         "review_option_id": $review_option_id,
         "done_option_id": $done_option_id
       }' project-info.json > project-info-updated.json

    mv project-info-updated.json project-info.json
fi

echo "✅ Workflow Status configuration saved"

echo ""
echo "🚀 Setting initial workflow statuses..."

# Get all project items
if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would fetch all project items${NC}"
else
    ITEMS_RESPONSE=$(gh api graphql -f query='
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
              }
            }
          }
        }
      }')
fi

# Set foundation tasks to Ready
echo "   Setting foundation tasks (#39, #40, #41) to Ready..."
for issue_num in 39 40 41; do
  if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would set #$issue_num → Ready${NC}"
  else
    ITEM_ID=$(echo "$ITEMS_RESPONSE" | jq -r ".data.node.items.nodes[] | select(.content.number == $issue_num) | .id")
    
    if [ "$ITEM_ID" != "null" ] && [ ! -z "$ITEM_ID" ]; then
      echo "     #$issue_num → Ready"
      READY_MUTATION='
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: "'$PROJECT_ID'"
            itemId: "'$ITEM_ID'"
            fieldId: "'$WORKFLOW_STATUS_FIELD_ID'"
            value: {
              singleSelectOptionId: "'$READY_OPTION_ID'"
            }
          }) {
            projectV2Item { id }
          }
        }'
      execute_mutation "$READY_MUTATION" "Set issue #$issue_num to Ready" > /dev/null
    fi
  fi
done

# Set dependent tasks to Blocked
echo "   Setting dependent tasks to Blocked..."
for issue_num in 42 43 44 45 46 47 48 49 50; do
  if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would set #$issue_num → Blocked${NC}"
  else
    ITEM_ID=$(echo "$ITEMS_RESPONSE" | jq -r ".data.node.items.nodes[] | select(.content.number == $issue_num) | .id")
    
    if [ "$ITEM_ID" != "null" ] && [ ! -z "$ITEM_ID" ]; then
      echo "     #$issue_num → Blocked"
      BLOCKED_MUTATION='
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: "'$PROJECT_ID'"
            itemId: "'$ITEM_ID'"
            fieldId: "'$WORKFLOW_STATUS_FIELD_ID'"
            value: {
              singleSelectOptionId: "'$BLOCKED_OPTION_ID'"
            }
          }) {
            projectV2Item { id }
          }
        }'
      execute_mutation "$BLOCKED_MUTATION" "Set issue #$issue_num to Blocked" > /dev/null
    fi
  fi
done

echo ""

if is_dry_run; then
    print_dry_run_summary "Create Workflow Status" "Field + Issues" "Create workflow field, set foundation tasks to Ready, dependent tasks to Blocked"
    echo ""
fi

if is_dry_run; then
    echo "🎉 Workflow Status setup would be complete!"
else
    echo "🎉 Workflow Status setup complete!"
fi
echo ""
echo "📊 Current Status:"
echo "   🔵 Ready: #39, #40, #41 (foundation tasks)"
echo "   🔒 Blocked: #42-#50 (waiting for dependencies)"
echo ""
echo "🔗 Next: Set up issue dependencies for automatic status transitions"
echo "📋 Visit project: $(jq -r '.project_url' project-info.json)"