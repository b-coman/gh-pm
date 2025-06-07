#!/bin/bash

# Move foundation tasks to "Ready" status

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared dry-run utilities
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Initialize dry-run mode
init_dry_run "$@"

# Load project info
if [ ! -f "project-info.json" ]; then
    echo "❌ project-info.json not found. Run setup-github-project.sh first."
    exit 1
fi

PROJECT_ID=$(jq -r '.project_id' project-info.json)

print_dry_run_header "Moving Foundation Tasks to Ready Status"

echo -e "${BLUE}📊 Project ID: $PROJECT_ID${NC}"
echo ""

# Get project fields and their options
echo "🔍 Getting project field information..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would fetch project field information${NC}"
    # Mock field data for dry run
    STATUS_FIELD_ID="MOCK_STATUS_FIELD_ID"
    READY_OPTION_ID="MOCK_READY_OPTION_ID"
else
    FIELDS_DATA=$(gh api graphql -f query='
      query {
        node(id: "'$PROJECT_ID'") {
          ... on ProjectV2 {
            fields(first: 20) {
              nodes {
                ... on ProjectV2SingleSelectField {
                  id
                  name
                  options {
                    id
                    name
                  }
                }
              }
            }
          }
        }
      }')
    
    # Extract Status field ID and Ready option ID
    STATUS_FIELD_ID=$(echo "$FIELDS_DATA" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .id')
    READY_OPTION_ID=$(echo "$FIELDS_DATA" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Ready") | .id')
fi

if [ "$STATUS_FIELD_ID" = "null" ] || [ -z "$STATUS_FIELD_ID" ]; then
    echo "❌ Status field not found. You may need to create it manually in the project."
    echo "💡 Go to your project and add a Status field with options: Todo, Ready, In Progress, Review, Done"
    exit 1
fi

if [ "$READY_OPTION_ID" = "null" ] || [ -z "$READY_OPTION_ID" ]; then
    echo "❌ 'Ready' option not found in Status field."
    echo "💡 Available options:"
    echo "$FIELDS_DATA" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | "   - \(.name)"'
    echo ""
    echo "Please add a 'Ready' option to your Status field or use one of the existing options."
    exit 1
fi

echo "✅ Status field found: $STATUS_FIELD_ID"
echo "✅ Ready option found: $READY_OPTION_ID"
echo ""

# Foundation tasks to move
FOUNDATION_ISSUES=(39 40 41)

echo "🚀 Moving foundation tasks to Ready status..."
echo ""

for issue_number in "${FOUNDATION_ISSUES[@]}"; do
    echo "📌 Processing issue #$issue_number..."
    
    if is_dry_run; then
        echo -e "${CYAN}🔍 DRY-RUN: Would get project item ID for issue #$issue_number${NC}"
        ISSUE_TITLE="Mock Foundation Issue #$issue_number"
        ITEM_ID=$(generate_mock_project_item_id)
    else
        # Get project item ID for this issue
        ITEM_DATA=$(gh api graphql -f query='
          query {
            repository(owner: "b-coman", name: "prop-management") {
              issue(number: '$issue_number') {
                title
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
        
        ISSUE_TITLE=$(echo "$ITEM_DATA" | jq -r '.data.repository.issue.title')
        ITEM_ID=$(echo "$ITEM_DATA" | jq -r '.data.repository.issue.projectItems.nodes[] | select(.project.id == "'$PROJECT_ID'") | .id')
        
        if [ "$ITEM_ID" = "null" ] || [ -z "$ITEM_ID" ]; then
            echo "   ⚠️  Issue #$issue_number not found in project or no project item ID"
            continue
        fi
    fi
    
    echo "   📝 Title: $ISSUE_TITLE"
    echo "   🆔 Item ID: $ITEM_ID"
    
    # Update status to Ready
    UPDATE_MUTATION='
      mutation {
        updateProjectV2ItemFieldValue(
          input: {
            projectId: "'$PROJECT_ID'"
            itemId: "'$ITEM_ID'"
            fieldId: "'$STATUS_FIELD_ID'"
            value: {
              singleSelectOptionId: "'$READY_OPTION_ID'"
            }
          }
        ) {
          projectV2Item {
            id
          }
        }
      }'
    
    if is_dry_run; then
        echo -e "${CYAN}🔍 DRY-RUN: Would move #$issue_number to Ready status${NC}"
        echo -e "   ${GREEN}✅ Mock: Moved #$issue_number to Ready${NC}"
    else
        UPDATE_RESULT=$(execute_mutation "$UPDATE_MUTATION" "Move issue #$issue_number to Ready")
        
        if echo "$UPDATE_RESULT" | jq -e '.data.updateProjectV2ItemFieldValue.projectV2Item.id' > /dev/null; then
            echo -e "   ${GREEN}✅ Moved #$issue_number to Ready${NC}"
        else
            echo "   ❌ Failed to update #$issue_number"
            echo "   Error: $UPDATE_RESULT"
        fi
    fi
    
    echo ""
done

if is_dry_run; then
    print_dry_run_summary "Move Foundation Tasks to Ready" "39, 40, 41" "Change status from 'Todo' to 'Ready' for foundation tasks"
    echo ""
fi

print_header "✅ Foundation Tasks Ready!"

if is_dry_run; then
    echo -e "${GREEN}🎉 Foundation tasks would be ready for development:${NC}"
else
    echo -e "${GREEN}🎉 Foundation tasks are now ready for development:${NC}"
fi
echo ""
echo "   📋 #39 - Create data transformation utilities"
echo "   📋 #40 - Audit and map component functionality gaps"  
echo "   📋 #41 - Document booking form integration differences"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "   1. Start working on any foundation task: ./start-task.sh [39|40|41]"
echo "   2. Check project status: ./query-project-status.sh"
echo "   3. View project board: $(jq -r '.project_url' project-info.json)"
echo ""
echo -e "${PURPLE}🔒 Blocked Tasks:${NC}"
echo "   Enhancement tasks (#42, #43, #44) remain blocked until foundation complete"
echo "   Migration tasks (#45, #46) remain blocked until enhancements complete"
echo ""
echo "🚀 Ready to start the renderer consolidation!"