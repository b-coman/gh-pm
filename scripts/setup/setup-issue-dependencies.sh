#!/bin/bash
# @fileoverview Set up issue dependencies using GitHub's native blocking relationships
# @module setup/setup-issue-dependencies
#
# @description
# Sets up generic dependency relationships for project workflow using GitHub's
# native blocking relationships. Provides best practices guidance for dependency
# management and removes blocked labels from foundation tasks.
#
# @dependencies
# - Scripts: ../lib/dry-run-utils.sh, ../lib/config-utils.sh
# - Commands: gh
#
# @usage
# ./setup-issue-dependencies.sh [--dry-run]
#
# @options
# --dry-run    Preview dependency setup without making changes
#
# @example
# ./setup-issue-dependencies.sh
# ./setup-issue-dependencies.sh --dry-run

# Set up issue dependencies using GitHub's native blocking relationships

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared dry-run utilities
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Load configuration utilities
source "$SCRIPT_DIR/lib/config-utils.sh"

# Initialize dry-run mode
init_dry_run "$@"

print_dry_run_header "Setting up Issue Dependencies"

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed. Run './gh-pm configure' to fix issues."
    exit 1
fi

# Load configuration values
GITHUB_OWNER=$(get_github_owner)
GITHUB_REPO=$(get_github_repo)

echo ""
echo "📋 Setting up generic dependency relationships..."
echo ""
echo -e "${YELLOW}ℹ️  This script sets up basic dependency relationships for project workflow.${NC}"
echo -e "${YELLOW}ℹ️  For project-specific dependencies, edit issues manually in GitHub.${NC}"
echo ""

# Foundation tasks (no dependencies by design)
FOUNDATION_ISSUES=($(get_config "workflow.foundation_issues[]" | tr -d '[]," '))

if [ ${#FOUNDATION_ISSUES[@]} -gt 0 ]; then
    echo "📋 Foundation issues (no dependencies):"
    for issue in "${FOUNDATION_ISSUES[@]}"; do
        echo "   #$issue - Foundation task (ready to start)"
        if is_dry_run; then
            echo -e "   ${CYAN}🔍 DRY-RUN: Would ensure #$issue has no blocking dependencies${NC}"
        else
            # Remove any existing "blocked" labels from foundation tasks
            gh_issue_safe edit "$issue" --repo "$GITHUB_OWNER/$GITHUB_REPO" --remove-label "blocked" 2>/dev/null || true
        fi
    done
    echo ""
fi

# Generic workflow advice
echo "💡 Dependency Management Best Practices:"
echo ""
echo "1. 🔍 Foundation Tasks: Should have no dependencies (start here)"
echo "2. ⚡ Enhancement Tasks: Often depend on foundation completion"
echo "3. 🔄 Migration Tasks: Usually depend on enhancements"
echo "4. 🧪 QA Tasks: Depend on features being implemented"
echo "5. 📚 Documentation: Often final step, depends on completion"
echo ""

echo "🔧 Manual Dependency Setup:"
echo "   • Use GitHub issue blocking relationships"
echo "   • Add 'blocked' labels to dependent issues"
echo "   • Reference dependencies in issue descriptions"
echo "   • Use './gh-pm dependencies' to check status"
echo ""

if is_dry_run; then
    print_dry_run_summary "Setup Issue Dependencies" "Foundation issues" "Configure basic workflow dependencies"
    echo ""
fi

echo "✅ Generic dependency framework configured"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "   1. Review your project issues in GitHub"
echo "   2. Add specific blocking relationships as needed"
echo "   3. Use './gh-pm dependencies' to monitor progress"
echo "   4. Update issue descriptions with dependency information"
echo ""
echo "🚀 Ready for dependency-aware project management!"