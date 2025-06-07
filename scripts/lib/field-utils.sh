#!/bin/bash

# Field management utilities for gh-pm
# Handles dynamic field creation and lookup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create a single select field with predefined options
create_single_select_field() {
    local project_id="$1"
    local field_name="$2"
    local field_options="$3"  # JSON array of option names
    
    echo "🔧 Creating field: $field_name"
    
    # Build the options array for GraphQL
    local options_graphql=""
    for option in $(echo "$field_options" | jq -r '.[]'); do
        if [[ -n "$options_graphql" ]]; then
            options_graphql+=", "
        fi
        options_graphql+="{name: \"$option\"}"
    done
    
    local mutation='
    mutation {
        createProjectV2Field(input: {
            projectId: "'$project_id'"
            dataType: SINGLE_SELECT
            name: "'$field_name'"
            singleSelectOptions: ['$options_graphql']
        }) {
            projectV2Field {
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
    }'
    
    local result=$(gh api graphql -f query="$mutation")
    local field_id=$(echo "$result" | jq -r '.data.createProjectV2Field.projectV2Field.id')
    
    if [[ "$field_id" != "null" && -n "$field_id" ]]; then
        echo "   ✅ Created: $field_name (ID: $field_id)"
        echo "$result"
    else
        echo "   ❌ Failed to create field: $field_name"
        echo "   Error: $result"
        return 1
    fi
}

# Create a text field
create_text_field() {
    local project_id="$1"
    local field_name="$2"
    
    echo "🔧 Creating text field: $field_name"
    
    local mutation='
    mutation {
        createProjectV2Field(input: {
            projectId: "'$project_id'"
            dataType: TEXT
            name: "'$field_name'"
        }) {
            projectV2Field {
                ... on ProjectV2Field {
                    id
                    name
                }
            }
        }
    }'
    
    local result=$(gh api graphql -f query="$mutation")
    local field_id=$(echo "$result" | jq -r '.data.createProjectV2Field.projectV2Field.id')
    
    if [[ "$field_id" != "null" && -n "$field_id" ]]; then
        echo "   ✅ Created: $field_name (ID: $field_id)"
        echo "$result"
    else
        echo "   ❌ Failed to create field: $field_name"
        echo "   Error: $result"
        return 1
    fi
}

# Query all fields for a project and return as JSON
get_project_fields() {
    local project_id="$1"
    
    local query='
    query {
        node(id: "'$project_id'") {
            ... on ProjectV2 {
                fields(first: 50) {
                    nodes {
                        ... on ProjectV2Field {
                            id
                            name
                            dataType
                        }
                        ... on ProjectV2SingleSelectField {
                            id
                            name
                            dataType
                            options {
                                id
                                name
                            }
                        }
                    }
                }
            }
        }
    }'
    
    gh api graphql -f query="$query"
}

# Find field ID by name
find_field_id_by_name() {
    local project_id="$1"
    local field_name="$2"
    
    local fields_data=$(get_project_fields "$project_id")
    echo "$fields_data" | jq -r ".data.node.fields.nodes[] | select(.name == \"$field_name\") | .id"
}

# Find field option ID by field name and option name
find_field_option_id() {
    local project_id="$1"
    local field_name="$2"
    local option_name="$3"
    
    local fields_data=$(get_project_fields "$project_id")
    echo "$fields_data" | jq -r "
        .data.node.fields.nodes[] | 
        select(.name == \"$field_name\") | 
        .options[]? | 
        select(.name == \"$option_name\") | 
        .id"
}

# Check if field exists
field_exists() {
    local project_id="$1"
    local field_name="$2"
    
    local field_id=$(find_field_id_by_name "$project_id" "$field_name")
    [[ "$field_id" != "null" && -n "$field_id" ]]
}

# Create all standard gh-pm fields
create_standard_fields() {
    local project_id="$1"
    
    echo ""
    echo -e "${BLUE}🏗️  Creating standard gh-pm project fields...${NC}"
    echo ""
    
    # Task Type field
    if ! field_exists "$project_id" "Task Type"; then
        local task_type_options='["🔍 Foundation", "⚡ Enhancement", "🐛 Bug Fix", "📚 Documentation", "🔄 Migration", "🧪 QA"]'
        create_single_select_field "$project_id" "Task Type" "$task_type_options"
    else
        echo "   ℹ️  Field already exists: Task Type"
    fi
    
    # Risk Level field
    if ! field_exists "$project_id" "Risk Level"; then
        local risk_level_options='["🟢 Low", "🟡 Medium", "🔴 High", "🚨 Critical"]'
        create_single_select_field "$project_id" "Risk Level" "$risk_level_options"
    else
        echo "   ℹ️  Field already exists: Risk Level"
    fi
    
    # Effort field
    if ! field_exists "$project_id" "Effort"; then
        local effort_options='["🟦 Small", "🟨 Medium", "🟥 Large"]'
        create_single_select_field "$project_id" "Effort" "$effort_options"
    else
        echo "   ℹ️  Field already exists: Effort"
    fi
    
    # Dependencies field (text)
    if ! field_exists "$project_id" "Dependencies"; then
        create_text_field "$project_id" "Dependencies"
    else
        echo "   ℹ️  Field already exists: Dependencies"
    fi
    
    # Workflow Status field (alternative to built-in Status)
    if ! field_exists "$project_id" "Workflow Status"; then
        local workflow_status_options='["Todo", "Ready", "In Progress", "Review", "Done"]'
        create_single_select_field "$project_id" "Workflow Status" "$workflow_status_options"
    else
        echo "   ℹ️  Field already exists: Workflow Status"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Standard field creation completed!${NC}"
}

# Dynamic field ID lookup - maps config field names to GitHub field names
get_field_id_dynamic() {
    local field_name="$1"
    local github_field_name=""
    
    # Map config field names to GitHub field names
    case "$field_name" in
        "task_type") github_field_name="Task Type" ;;
        "risk_level") github_field_name="Risk Level" ;;
        "effort") github_field_name="Effort" ;;
        "status") github_field_name="Status" ;;
        "workflow_status") github_field_name="Workflow Status" ;;
        "dependencies") github_field_name="Dependencies" ;;
        *) 
            echo "❌ Unknown field name: $field_name" >&2
            return 1
            ;;
    esac
    
    local project_id=$(get_project_id)
    find_field_id_by_name "$project_id" "$github_field_name"
}

# Dynamic field option ID lookup 
get_field_option_id_dynamic() {
    local field_name="$1"
    local option_name="$2"
    local github_field_name=""
    
    # Map config field names to GitHub field names
    case "$field_name" in
        "task_type") github_field_name="Task Type" ;;
        "risk_level") github_field_name="Risk Level" ;;
        "effort") github_field_name="Effort" ;;
        "status") github_field_name="Status" ;;
        "workflow_status") github_field_name="Workflow Status" ;;
        *) 
            echo "❌ Unknown field name: $field_name" >&2
            return 1
            ;;
    esac
    
    local project_id=$(get_project_id)
    find_field_option_id "$project_id" "$github_field_name" "$option_name"
}

# Update config.json with discovered field IDs
update_config_with_field_ids() {
    local project_id="$1"
    
    echo ""
    echo "🔍 Discovering field IDs..."
    
    # Get all fields
    local fields_data=$(get_project_fields "$project_id")
    
    # Extract field IDs
    local task_type_id=$(echo "$fields_data" | jq -r '.data.node.fields.nodes[] | select(.name == "Task Type") | .id')
    local risk_level_id=$(echo "$fields_data" | jq -r '.data.node.fields.nodes[] | select(.name == "Risk Level") | .id')
    local effort_id=$(echo "$fields_data" | jq -r '.data.node.fields.nodes[] | select(.name == "Effort") | .id')
    local status_id=$(echo "$fields_data" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .id')
    local dependencies_id=$(echo "$fields_data" | jq -r '.data.node.fields.nodes[] | select(.name == "Dependencies") | .id')
    local workflow_status_id=$(echo "$fields_data" | jq -r '.data.node.fields.nodes[] | select(.name == "Workflow Status") | .id')
    
    # Update config.json with the discovered IDs
    if [[ -f "config.json" ]]; then
        # Create a temporary config with updated field IDs
        jq --arg task_type_id "$task_type_id" \
           --arg risk_level_id "$risk_level_id" \
           --arg effort_id "$effort_id" \
           --arg status_id "$status_id" \
           --arg dependencies_id "$dependencies_id" \
           --arg workflow_status_id "$workflow_status_id" \
           '.fields.task_type.id = $task_type_id |
            .fields.risk_level.id = $risk_level_id |
            .fields.effort.id = $effort_id |
            .fields.status.id = $status_id |
            .fields.dependencies.id = $dependencies_id |
            .fields.workflow_status.id = $workflow_status_id' \
           config.json > config.json.tmp && mv config.json.tmp config.json
        
        echo "✅ Updated config.json with field IDs"
        echo "   Task Type: $task_type_id"
        echo "   Risk Level: $risk_level_id"
        echo "   Effort: $effort_id"
        echo "   Status: $status_id"
        echo "   Dependencies: $dependencies_id"
        echo "   Workflow Status: $workflow_status_id"
    else
        echo "❌ config.json not found"
        return 1
    fi
}