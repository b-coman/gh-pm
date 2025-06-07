#!/bin/bash

# GitHub Project Setup Script for Property Renderer Consolidation
# Enhanced with dry-run capability - CRITICAL for preventing accidental project creation

set -e

# Load shared dry-run utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Parse arguments and initialize dry-run mode
init_dry_run "$@"

print_dry_run_header "Setting up GitHub Project: Property Renderer Consolidation"

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: This will show what would be created without making actual changes${NC}"
    echo ""
fi

# Step 1: Create the project
echo "📋 Creating project..."

if is_dry_run; then
    # Mock project creation
    PROJECT_ID="MOCK_PROJECT_ID_PVT_kwHOCOLa384AXXXX"
    PROJECT_URL="https://github.com/users/b-coman/projects/MOCK"
    PROJECT_NUMBER="MOCK_NUMBER"
    
    echo -e "${CYAN}🔍 DRY-RUN: Would execute GraphQL mutation:${NC}"
    echo -e "${CYAN}   mutation { createProjectV2(input: { ownerId: \"U_kgDOCOLa3w\", title: \"Property Renderer Consolidation\" }) }${NC}"
    echo -e "${GREEN}✅ Mock project created successfully!${NC}"
    echo -e "${CYAN}   Mock Project ID: $PROJECT_ID${NC}"
    echo -e "${CYAN}   Mock Project URL: $PROJECT_URL${NC}"
else
    PROJECT_RESPONSE=$(gh_api_safe graphql -f query='
      mutation{
        createProjectV2(
          input: {
            ownerId: "U_kgDOCOLa3w",
            title: "Property Renderer Consolidation"
          }
        ){
          projectV2 {
            id
            url
            number
          }
         }
      }')
    
    PROJECT_ID=$(echo $PROJECT_RESPONSE | jq -r '.data.createProjectV2.projectV2.id')
    PROJECT_URL=$(echo $PROJECT_RESPONSE | jq -r '.data.createProjectV2.projectV2.url')
    PROJECT_NUMBER=$(echo $PROJECT_RESPONSE | jq -r '.data.createProjectV2.projectV2.number')
    
    echo "✅ Project created successfully!"
    echo "   Project ID: $PROJECT_ID"
    echo "   Project URL: $PROJECT_URL"
fi

echo ""

# Step 2: Create custom fields
echo "🏷️  Creating custom fields..."

# Task Type field
echo "   Creating Task Type field..."

if is_dry_run; then
    TASK_TYPE_FIELD_ID="MOCK_TASK_TYPE_FIELD_ID"
    echo -e "${CYAN}🔍 DRY-RUN: Would create Task Type field with options:${NC}"
    echo -e "${CYAN}     - 🔍 Foundation (Blue)${NC}"
    echo -e "${CYAN}     - ⚡ Enhancement (Green)${NC}"
    echo -e "${CYAN}     - 🔄 Migration (Orange)${NC}"
    echo -e "${CYAN}     - 🧪 QA (Purple)${NC}"
    echo -e "${CYAN}     - 📚 Documentation (Gray)${NC}"
    echo -e "${CYAN}   Mock Task Type Field ID: $TASK_TYPE_FIELD_ID${NC}"
else
    TASK_TYPE_RESPONSE=$(execute_mutation '
      mutation {
        createProjectV2Field(input: {
          projectId: "'$PROJECT_ID'"
          dataType: SINGLE_SELECT
          name: "Task Type"
          singleSelectOptions: [
            {name: "🔍 Foundation", color: BLUE, description: "Analysis & Planning"},
            {name: "⚡ Enhancement", color: GREEN, description: "Building Capabilities"},
            {name: "🔄 Migration", color: ORANGE, description: "Moving & Adapting"},
            {name: "🧪 QA", color: PURPLE, description: "Testing & Validation"},
            {name: "📚 Documentation", color: GRAY, description: "Knowledge & Guides"}
          ]
        }) {
          projectV2Field {
            ... on ProjectV2SingleSelectField {
              id
            }
          }
        }
      }' "Task Type field creation")
    
    TASK_TYPE_FIELD_ID=$(echo $TASK_TYPE_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.id // "null"')
    echo "   ✅ Task Type field created: $TASK_TYPE_FIELD_ID"
fi

# Risk Level field
echo "   Creating Risk Level field..."

if is_dry_run; then
    RISK_LEVEL_FIELD_ID="MOCK_RISK_LEVEL_FIELD_ID"
    echo -e "${CYAN}🔍 DRY-RUN: Would create Risk Level field with options:${NC}"
    echo -e "${CYAN}     - 🔴 Critical (Red)${NC}"
    echo -e "${CYAN}     - 🟡 Medium (Yellow)${NC}"
    echo -e "${CYAN}     - 🟢 Low (Green)${NC}"
    echo -e "${CYAN}   Mock Risk Level Field ID: $RISK_LEVEL_FIELD_ID${NC}"
else
    RISK_LEVEL_RESPONSE=$(execute_mutation '
      mutation {
        createProjectV2Field(input: {
          projectId: "'$PROJECT_ID'"
          dataType: SINGLE_SELECT
          name: "Risk Level"
          singleSelectOptions: [
            {name: "🔴 Critical", color: RED, description: "High impact, immediate attention"},
            {name: "🟡 Medium", color: YELLOW, description: "Moderate impact, planned approach"},
            {name: "🟢 Low", color: GREEN, description: "Low impact, flexible timing"}
          ]
        }) {
          projectV2Field {
            ... on ProjectV2SingleSelectField {
              id
            }
          }
        }
      }' "Risk Level field creation")
    
    RISK_LEVEL_FIELD_ID=$(echo $RISK_LEVEL_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.id // "null"')
    echo "   ✅ Risk Level field created: $RISK_LEVEL_FIELD_ID"
fi

# Effort field
echo "   Creating Effort field..."

if is_dry_run; then
    EFFORT_FIELD_ID="MOCK_EFFORT_FIELD_ID"
    echo -e "${CYAN}🔍 DRY-RUN: Would create Effort field with options:${NC}"
    echo -e "${CYAN}     - 🔸 Small (1-2 hours)${NC}"
    echo -e "${CYAN}     - 🔶 Medium (Half day)${NC}"
    echo -e "${CYAN}     - 🔺 Large (Full day+)${NC}"
    echo -e "${CYAN}   Mock Effort Field ID: $EFFORT_FIELD_ID${NC}"
else
    EFFORT_RESPONSE=$(execute_mutation '
      mutation {
        createProjectV2Field(input: {
          projectId: "'$PROJECT_ID'"
          dataType: SINGLE_SELECT
          name: "Effort"
          singleSelectOptions: [
            {name: "🔸 Small", color: GREEN, description: "1-2 hours"},
            {name: "🔶 Medium", color: YELLOW, description: "Half day"},
            {name: "🔺 Large", color: RED, description: "Full day+"}
          ]
        }) {
          projectV2Field {
            ... on ProjectV2SingleSelectField {
              id
            }
          }
        }
      }' "Effort field creation")
    
    EFFORT_FIELD_ID=$(echo $EFFORT_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.id // "null"')
    echo "   ✅ Effort field created: $EFFORT_FIELD_ID"
fi

# Dependencies field
echo "   Creating Dependencies field..."

if is_dry_run; then
    DEPENDENCIES_FIELD_ID="MOCK_DEPENDENCIES_FIELD_ID"
    echo -e "${CYAN}🔍 DRY-RUN: Would create Dependencies text field${NC}"
    echo -e "${CYAN}   Mock Dependencies Field ID: $DEPENDENCIES_FIELD_ID${NC}"
else
    DEPENDENCIES_RESPONSE=$(execute_mutation '
      mutation {
        createProjectV2Field(input: {
          projectId: "'$PROJECT_ID'"
          dataType: TEXT
          name: "Dependencies"
        }) {
          projectV2Field {
            ... on ProjectV2Field {
              id
            }
          }
        }
      }' "Dependencies field creation")
    
    DEPENDENCIES_FIELD_ID=$(echo $DEPENDENCIES_RESPONSE | jq -r '.data.createProjectV2Field.projectV2Field.id // "null"')
    echo "   ✅ Dependencies field created: $DEPENDENCIES_FIELD_ID"
fi

# Step 3: Get Status field
echo ""
echo "📋 Getting Status field..."

if is_dry_run; then
    STATUS_FIELD_ID="MOCK_STATUS_FIELD_ID"
    TODO_OPTION_ID="MOCK_TODO_OPTION_ID"
    IN_PROGRESS_OPTION_ID="MOCK_IN_PROGRESS_OPTION_ID"
    DONE_OPTION_ID="MOCK_DONE_OPTION_ID"
    
    echo -e "${CYAN}🔍 DRY-RUN: Would query for default Status field and extract option IDs${NC}"
    echo -e "${CYAN}   Mock Status Field ID: $STATUS_FIELD_ID${NC}"
    echo -e "${CYAN}   Mock Option IDs: Todo, In Progress, Done${NC}"
else
    echo "   ⚠️  Real mode would query for Status field and option IDs"
    STATUS_FIELD_ID="WOULD_QUERY_STATUS_FIELD_ID"
    TODO_OPTION_ID="WOULD_QUERY_TODO_OPTION_ID"
    IN_PROGRESS_OPTION_ID="WOULD_QUERY_IN_PROGRESS_OPTION_ID"
    DONE_OPTION_ID="WOULD_QUERY_DONE_OPTION_ID"
fi

# Step 4: Save configuration
echo ""
echo "💾 Saving project configuration..."

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would save project-info.json with:${NC}"
    echo -e "${CYAN}   {${NC}"
    echo -e "${CYAN}     \"project_id\": \"$PROJECT_ID\",${NC}"
    echo -e "${CYAN}     \"project_url\": \"$PROJECT_URL\",${NC}"
    echo -e "${CYAN}     \"project_number\": \"$PROJECT_NUMBER\",${NC}"
    echo -e "${CYAN}     \"task_type_field_id\": \"$TASK_TYPE_FIELD_ID\",${NC}"
    echo -e "${CYAN}     \"risk_level_field_id\": \"$RISK_LEVEL_FIELD_ID\",${NC}"
    echo -e "${CYAN}     \"effort_field_id\": \"$EFFORT_FIELD_ID\",${NC}"
    echo -e "${CYAN}     \"dependencies_field_id\": \"$DEPENDENCIES_FIELD_ID\",${NC}"
    echo -e "${CYAN}     \"status_field_id\": \"$STATUS_FIELD_ID\",${NC}"
    echo -e "${CYAN}     \"todo_option_id\": \"$TODO_OPTION_ID\",${NC}"
    echo -e "${CYAN}     \"in_progress_option_id\": \"$IN_PROGRESS_OPTION_ID\",${NC}"
    echo -e "${CYAN}     \"done_option_id\": \"$DONE_OPTION_ID\"${NC}"
    echo -e "${CYAN}   }${NC}"
else
    cat > project-info.json << EOF
{
  "project_id": "$PROJECT_ID",
  "project_url": "$PROJECT_URL",
  "project_number": "$PROJECT_NUMBER",
  "task_type_field_id": "$TASK_TYPE_FIELD_ID",
  "risk_level_field_id": "$RISK_LEVEL_FIELD_ID", 
  "effort_field_id": "$EFFORT_FIELD_ID",
  "dependencies_field_id": "$DEPENDENCIES_FIELD_ID",
  "status_field_id": "$STATUS_FIELD_ID",
  "todo_option_id": "$TODO_OPTION_ID",
  "in_progress_option_id": "$IN_PROGRESS_OPTION_ID",
  "done_option_id": "$DONE_OPTION_ID"
}
EOF
    echo "✅ Project configuration saved to project-info.json"
fi

# Final summary
echo ""
if is_dry_run; then
    print_dry_run_summary "GitHub Project setup" "N/A" "Project, custom fields, and configuration file"
    echo ""
    echo -e "${CYAN}🔍 This dry-run prevented creating a real GitHub Project${NC}"
    echo -e "${CYAN}🔍 In real mode, this would create a complete project infrastructure${NC}"
else
    echo -e "${GREEN}✅ GitHub Project setup completed successfully!${NC}"
    echo ""
    echo "🔧 Next steps:"
    echo "   📊 Configure fields: ./configure-project-fields.sh"
    echo "   🔗 Add issues: Add issues to the project manually or via scripts"
    echo "   📋 Check status: ./query-project-status.sh"
    echo "   🔗 View project: $PROJECT_URL"
fi

if is_dry_run; then
    echo ""
    echo -e "${CYAN}🔍 To create the real project, run without --dry-run flag${NC}"
fi