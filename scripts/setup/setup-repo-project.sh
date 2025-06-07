#!/bin/bash

# Alternative setup using repository projects (no special permissions needed)

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared dry-run utilities
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Load configuration utilities
source "$SCRIPT_DIR/lib/config-utils.sh"

# Load security utilities
source "$SCRIPT_DIR/lib/security-utils.sh"

# Initialize dry-run mode
init_dry_run "$@"

# Validate authentication
validate_github_auth || exit 1

print_dry_run_header "Repository Project Setup (Alternative Method)"

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed. Run './gh-pm configure' to fix issues."
    exit 1
fi

# Load configuration values
GITHUB_OWNER=$(get_github_owner)
GITHUB_REPO=$(get_github_repo)
PROJECT_TITLE=$(get_config "project.title")

echo ""
echo -e "${BLUE}📊 Repository: $GITHUB_OWNER/$GITHUB_REPO${NC}"
echo ""

echo "🔄 Repository project setup (alternative to user projects)..."
echo ""

if is_dry_run; then
    echo -e "${CYAN}🔍 DRY-RUN: Would create repository project with title: $PROJECT_TITLE${NC}"
    echo -e "${CYAN}🔍 DRY-RUN: Would configure project board with standard columns${NC}"
else
    echo "ℹ️  This method creates a classic GitHub project board in your repository."
    echo "ℹ️  Use this if you don't have access to GitHub Projects v2."
    echo ""
    
    # Note: Classic projects are deprecated, so we provide guidance instead
    echo "⚠️  Note: Classic project boards are deprecated. We recommend using GitHub Projects v2 instead."
    echo ""
fi

echo "📋 Manual Repository Project Setup Steps:"
echo ""
echo "1. 🔧 Create Repository Project:"
echo "   • Go to: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/projects"
echo "   • Click 'New project'"
echo "   • Choose 'Board' layout"
echo "   • Name: '$PROJECT_TITLE'"
echo ""

echo "2. 📋 Create Standard Columns:"
echo "   • Backlog - New issues and tasks"
echo "   • Ready - Tasks ready to start"
echo "   • In Progress - Currently being worked on"
echo "   • Review - Completed, awaiting review"
echo "   • Done - Fully completed"
echo ""

echo "3. 🏷️  Add Issues to Project:"
echo "   • Add your repository issues to the project"
echo "   • Start with foundation issues in 'Ready' column"
echo "   • Place dependent issues in 'Backlog'"
echo ""

echo "4. 🔗 Configure Dependencies:"
echo "   • Foundation tasks → Ready column (no dependencies)"
echo "   • Enhancement tasks → Backlog (depend on foundation)"
echo "   • QA tasks → Backlog (depend on features)"
echo "   • Documentation → Backlog (usually last)"
echo ""

if is_dry_run; then
    print_dry_run_summary "Repository Project Setup" "Classic project board" "Provide setup guidance for repository-level projects"
    echo ""
fi

echo -e "${BLUE}🔧 Alternative: GitHub Projects v2${NC}"
echo "   For better features, use: './gh-pm setup-complete'"
echo "   • Custom fields for task classification"
echo "   • Advanced automation and filtering"
echo "   • Better integration with gh-pm commands"
echo ""

echo -e "${BLUE}📚 Next Steps:${NC}"
echo "   1. Follow the manual setup steps above"
echo "   2. Configure your issues with appropriate labels"
echo "   3. Use './gh-pm status' to monitor progress"
echo ""

echo "🚀 Repository project guidance complete!"