#!/bin/bash

# Configure field values for project issues
# Provides guidance for setting up project field configurations

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared dry-run utilities
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Load configuration utilities
source "$SCRIPT_DIR/lib/config-utils.sh"

# Initialize dry-run mode
init_dry_run "$@"

print_dry_run_header "Project Field Configuration Guide"

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed. Run './gh-pm configure' to fix issues."
    exit 1
fi

# Load configuration values
PROJECT_ID=$(get_project_id)
GITHUB_OWNER=$(get_github_owner)
GITHUB_REPO=$(get_github_repo)

echo ""
echo -e "${BLUE}📊 Project: $GITHUB_OWNER/$GITHUB_REPO${NC}"
echo -e "${BLUE}🆔 Project ID: $PROJECT_ID${NC}"
echo ""

# Show available field configuration
echo "📋 Standard Field Configuration:"
echo ""
echo "🏷️  Task Type Field Options:"
echo "   🔍 Foundation - Core infrastructure and setup tasks"
echo "   ⚡ Enhancement - New features and improvements"
echo "   🐛 Bug Fix - Issues and problem resolution"
echo "   📚 Documentation - Documentation and guides"
echo "   🔄 Migration - Data and system migrations"
echo "   🧪 QA - Quality assurance and testing"
echo ""

echo "⚠️  Risk Level Field Options:"
echo "   🟢 Low - Minimal impact, safe changes"
echo "   🟡 Medium - Moderate complexity and risk"
echo "   🔴 High - Complex changes requiring careful review"
echo "   🚨 Critical - High-impact changes requiring extensive testing"
echo ""

echo "📏 Effort Field Options:"
echo "   🟦 Small - Quick tasks (1-2 hours)"
echo "   🟨 Medium - Standard tasks (half day to full day)"
echo "   🟥 Large - Complex tasks (multiple days)"
echo ""

echo "🔄 Status Field Options:"
echo "   📋 Todo - Not yet started"
echo "   🔵 Ready - Ready to begin work"
echo "   🟡 In Progress - Currently being worked on"
echo "   🟣 Review - Completed, awaiting review"
echo "   ✅ Done - Fully completed and verified"
echo ""

if is_dry_run; then
    print_dry_run_summary "Field Configuration Guide" "Project field structure" "Display standard field options and configuration guidance"
    echo ""
fi

echo "💡 Field Configuration Guidance:"
echo ""
echo "1. 🎯 Task Classification:"
echo "   • Start with Foundation tasks to establish project base"
echo "   • Group related Enhancements together"
echo "   • Schedule QA tasks after implementation phases"
echo ""

echo "2. 📊 Risk Assessment:"
echo "   • High-risk tasks should have detailed acceptance criteria"
echo "   • Critical tasks may need additional review processes"
echo "   • Low-risk tasks can often be batched together"
echo ""

echo "3. ⏱️  Effort Planning:"
echo "   • Balance Large tasks with smaller quick wins"
echo "   • Break down Large tasks when possible"
echo "   • Use Small tasks for learning and exploration"
echo ""

echo "4. 🔗 Dependencies:"
echo "   • Use the Dependencies field to track blocking relationships"
echo "   • Foundation tasks should generally have no dependencies"
echo "   • Document dependencies clearly in issue descriptions"
echo ""

echo -e "${BLUE}🔧 Manual Configuration Steps:${NC}"
echo "   1. Visit your GitHub Project: $(get_project_url)"
echo "   2. Edit each issue to set appropriate field values"
echo "   3. Use the field options listed above for consistency"
echo "   4. Run './gh-pm dependencies' to verify relationships"
echo ""

echo "🚀 Ready for structured project management!"