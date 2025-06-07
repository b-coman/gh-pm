#!/bin/bash
# @fileoverview Apply security hardening to all remaining scripts
# @module security/harden-all-scripts
#
# @description
# Batch applies basic security improvements to scripts that don't have them yet.
# Adds authentication checks, input validation, and proper error handling.
#
# @dependencies
# - Scripts: lib/security-utils.sh, lib/error-utils.sh
# - Commands: sed, grep
#
# @usage
# ./harden-all-scripts.sh
#
# @example
# ./harden-all-scripts.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🛡️  Security Hardening: Batch Processing Remaining Scripts"
echo "=========================================================="

# List of scripts to harden (excluding already hardened ones)
SCRIPTS_TO_HARDEN=(
    "approve-task.sh"
    "query-project-status.sh" 
    "query-workflow-status.sh"
    "setup-github-project.sh"
    "setup-repo-project.sh"
    "check-dependencies.sh"
)

harden_script() {
    local script_file="$1"
    local script_path="$SCRIPT_DIR/$script_file"
    
    if [[ ! -f "$script_path" ]]; then
        echo "⚠️  Skipping $script_file (not found)"
        return
    fi
    
    echo "🔧 Hardening $script_file..."
    
    # Check if already hardened (has security-utils)
    if grep -q "security-utils.sh" "$script_path"; then
        echo "   ✅ Already hardened"
        return
    fi
    
    # Create backup
    cp "$script_path" "$script_path.bak"
    
    # Add security utilities after existing sources
    if grep -q "source.*config-utils.sh" "$script_path"; then
        sed -i '' '/source.*config-utils.sh/a\
\
# Load security utilities\
source "$SCRIPT_DIR/lib/security-utils.sh"
' "$script_path"
    fi
    
    # Add authentication check after init_dry_run (if exists)
    if grep -q "init_dry_run" "$script_path"; then
        sed -i '' '/init_dry_run.*@/a\
\
# Validate authentication\
validate_github_auth || exit 1
' "$script_path"
    fi
    
    # Add input validation for issue numbers (if script takes issue number)
    if grep -q "ISSUE_NUMBER" "$script_path" && ! grep -q "validate_issue_number" "$script_path"; then
        sed -i '' '/ISSUE_NUMBER=/a\
\
# Validate issue number\
validate_issue_number "$ISSUE_NUMBER" || exit 1
' "$script_path"
    fi
    
    echo "   ✅ Basic hardening applied"
}

# Apply hardening to each script
for script in "${SCRIPTS_TO_HARDEN[@]}"; do
    harden_script "$script"
done

echo ""
echo "🎯 Manual Security Review Required"
echo "=================================="
echo "The following scripts need manual security review for GraphQL injection:"
echo ""

# Find scripts with potential GraphQL injection
for script_file in "$SCRIPT_DIR"/*.sh; do
    if [[ -f "$script_file" ]] && grep -q "gh api graphql" "$script_file" && ! grep -q "jq -n" "$script_file"; then
        script_name=$(basename "$script_file")
        echo "⚠️  $script_name - Contains potentially unsafe GraphQL queries"
    fi
done

echo ""
echo "✅ Batch security hardening complete!"
echo "📋 Next steps:"
echo "   1. Review scripts marked above for GraphQL injection"
echo "   2. Test all hardened scripts with --dry-run"
echo "   3. Run shellcheck on all scripts"
echo "   4. Create comprehensive test suite"