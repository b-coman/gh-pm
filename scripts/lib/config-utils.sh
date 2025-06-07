#!/bin/bash

# Configuration utilities for gh-pm
# Provides functions to load and validate configuration

CONFIG_FILE="config.json"
CONFIG_TEMPLATE="config-template.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration from config.json
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}" >&2
        echo -e "${YELLOW}ℹ️  Run './gh-pm init' to create your configuration${NC}" >&2
        return 1
    fi
    
    if ! jq . "$CONFIG_FILE" >/dev/null 2>&1; then
        echo -e "${RED}❌ Invalid JSON in configuration file: $CONFIG_FILE${NC}" >&2
        return 1
    fi
    
    return 0
}

# Get configuration value by path (e.g., "github.owner")
get_config() {
    local path="$1"
    
    if ! load_config; then
        return 1
    fi
    
    jq -r ".$path" "$CONFIG_FILE" 2>/dev/null || echo "null"
}

# Get GitHub owner from config
get_github_owner() {
    get_config "github.owner"
}

# Get GitHub repository from config  
get_github_repo() {
    get_config "github.repository"
}

# Get project ID from config
get_project_id() {
    get_config "project.id"
}

# Get project URL from config
get_project_url() {
    get_config "project.url"
}

# Get field ID by field name
get_field_id() {
    local field_name="$1"
    get_config "fields.${field_name}.id"
}

# Get field option value
get_field_option() {
    local field_name="$1"
    local option_key="$2"
    get_config "fields.${field_name}.options.${option_key}"
}

# Validate that all required configuration is present
validate_config() {
    local errors=0
    
    if ! load_config; then
        return 1
    fi
    
    # Required GitHub configuration
    local owner=$(get_github_owner)
    local repo=$(get_github_repo)
    local project_id=$(get_project_id)
    
    if [[ "$owner" == "null" || "$owner" == "YOUR_GITHUB_USERNAME" ]]; then
        echo -e "${RED}❌ GitHub owner not configured${NC}" >&2
        ((errors++))
    fi
    
    if [[ "$repo" == "null" || "$repo" == "YOUR_REPOSITORY_NAME" ]]; then
        echo -e "${RED}❌ GitHub repository not configured${NC}" >&2
        ((errors++))
    fi
    
    if [[ "$project_id" == "null" || "$project_id" == "YOUR_PROJECT_ID" ]]; then
        echo -e "${RED}❌ Project ID not configured${NC}" >&2
        ((errors++))
    fi
    
    # Check required field IDs
    local required_fields=("task_type" "risk_level" "effort" "status")
    for field in "${required_fields[@]}"; do
        local field_id=$(get_field_id "$field")
        if [[ "$field_id" == "null" || "$field_id" == *"FIELD_ID"* ]]; then
            echo -e "${RED}❌ Field '$field' not configured${NC}" >&2
            ((errors++))
        fi
    done
    
    if [[ $errors -gt 0 ]]; then
        echo -e "${YELLOW}ℹ️  Run './gh-pm configure' to fix configuration issues${NC}" >&2
        return 1
    fi
    
    return 0
}

# Initialize configuration from template
init_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}⚠️  Configuration file already exists: $CONFIG_FILE${NC}"
        read -p "Overwrite existing configuration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}ℹ️  Configuration unchanged${NC}"
            return 0
        fi
    fi
    
    if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
        echo -e "${RED}❌ Configuration template not found: $CONFIG_TEMPLATE${NC}" >&2
        return 1
    fi
    
    cp "$CONFIG_TEMPLATE" "$CONFIG_FILE"
    echo -e "${GREEN}✅ Configuration initialized from template${NC}"
    echo -e "${YELLOW}ℹ️  Edit $CONFIG_FILE to configure your GitHub project details${NC}"
    echo -e "${YELLOW}ℹ️  Then run './gh-pm configure' to validate your setup${NC}"
    
    return 0
}

# Show current configuration
# Dynamic field lookup - get field ID by querying GitHub if not in config
get_field_id_dynamic() {
    local field_name="$1"
    local github_field_name=""
    
    # Map config field names to GitHub field names
    case "$field_name" in
        "task_type") github_field_name="Task Type" ;;
        "risk_level") github_field_name="Risk Level" ;;
        "effort") github_field_name="Effort" ;;
        "status") github_field_name="Status" ;;
        "dependencies") github_field_name="Dependencies" ;;
        "workflow_status") github_field_name="Workflow Status" ;;
        *) github_field_name="$field_name" ;;
    esac
    
    # First try to get from config
    local field_id=$(get_field_id "$field_name")
    
    # If not in config or placeholder value, query GitHub
    if [[ "$field_id" == "null" || "$field_id" == *"FIELD_ID"* || -z "$field_id" ]]; then
        local project_id=$(get_project_id)
        if [[ "$project_id" != "null" && -n "$project_id" ]]; then
            # Load field utilities
            local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            source "$script_dir/field-utils.sh"
            
            field_id=$(find_field_id_by_name "$project_id" "$github_field_name")
        fi
    fi
    
    echo "$field_id"
}

# Get field option ID dynamically
get_field_option_id_dynamic() {
    local field_name="$1"
    local option_key="$2"
    local github_field_name=""
    local github_option_name=""
    
    # Map config field names to GitHub field names
    case "$field_name" in
        "task_type") github_field_name="Task Type" ;;
        "risk_level") github_field_name="Risk Level" ;;
        "effort") github_field_name="Effort" ;;
        "status") github_field_name="Status" ;;
        "workflow_status") github_field_name="Workflow Status" ;;
        *) github_field_name="$field_name" ;;
    esac
    
    # Map option keys to GitHub option names
    github_option_name=$(get_field_option "$field_name" "$option_key")
    if [[ "$github_option_name" == "null" || -z "$github_option_name" ]]; then
        github_option_name="$option_key"
    fi
    
    # Query GitHub for the option ID
    local project_id=$(get_project_id)
    if [[ "$project_id" != "null" && -n "$project_id" ]]; then
        # Load field utilities
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        source "$script_dir/field-utils.sh"
        
        find_field_option_id "$project_id" "$github_field_name" "$github_option_name"
    else
        echo "null"
    fi
}

show_config() {
    if ! load_config; then
        return 1
    fi
    
    echo -e "${BLUE}📋 Current Configuration:${NC}"
    echo -e "${BLUE}========================${NC}"
    
    local owner=$(get_github_owner)
    local repo=$(get_github_repo) 
    local project_url=$(get_project_url)
    local project_id=$(get_project_id)
    
    echo -e "GitHub Owner: ${GREEN}$owner${NC}"
    echo -e "Repository: ${GREEN}$repo${NC}"
    echo -e "Project URL: ${GREEN}$project_url${NC}"
    echo -e "Project ID: ${GREEN}$project_id${NC}"
    
    echo -e "\n${BLUE}Field Configuration:${NC}"
    local fields=("task_type" "risk_level" "effort" "status")
    for field in "${fields[@]}"; do
        local field_id=$(get_field_id "$field")
        echo -e "  $field: ${GREEN}$field_id${NC}"
    done
}