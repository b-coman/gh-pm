#!/bin/bash
# @fileoverview Run shellcheck on all scripts to verify code quality
# @module quality/run-shellcheck
#
# @description
# Runs shellcheck linting on all bash scripts in the project.
# Reports any issues and provides a summary of code quality.
#
# @dependencies
# - Commands: shellcheck, find
#
# @usage
# ./run-shellcheck.sh [--fix]
#
# @options
# --fix    Attempt to fix simple issues automatically
#
# @example
# ./run-shellcheck.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIX_MODE=false
if [[ "${1:-}" == "--fix" ]]; then
    FIX_MODE=true
fi

echo "🔍 Running ShellCheck on all scripts..."
echo "======================================"

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo "❌ shellcheck not found. Please install it:"
    echo "   macOS: brew install shellcheck"
    echo "   Ubuntu: apt-get install shellcheck"
    exit 1
fi

# Find all shell scripts
SCRIPTS=$(find "$PROJECT_ROOT" -name "*.sh" -type f | grep -v ".git" | sort)

TOTAL_SCRIPTS=0
PASSED_SCRIPTS=0
FAILED_SCRIPTS=0
declare -a FAILED_FILES=()

echo "📋 Checking $(echo "$SCRIPTS" | wc -l | tr -d ' ') shell scripts..."
echo ""

for script in $SCRIPTS; do
    TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))
    relative_path=$(echo "$script" | sed "s|$PROJECT_ROOT/||")
    
    echo -n "  $relative_path ... "
    
    if shellcheck "$script" > /dev/null 2>&1; then
        echo "✅"
        PASSED_SCRIPTS=$((PASSED_SCRIPTS + 1))
    else
        echo "❌"
        FAILED_SCRIPTS=$((FAILED_SCRIPTS + 1))
        FAILED_FILES+=("$script")
        
        # Show specific issues
        echo "    Issues found:"
        shellcheck "$script" | sed 's/^/      /'
        echo ""
    fi
done

echo ""
echo "📊 ShellCheck Summary"
echo "===================="
echo "Total scripts: $TOTAL_SCRIPTS"
echo "Passed: $PASSED_SCRIPTS"
echo "Failed: $FAILED_SCRIPTS"

if [[ $FAILED_SCRIPTS -gt 0 ]]; then
    echo ""
    echo "❌ Failed scripts:"
    for failed_file in "${FAILED_FILES[@]}"; do
        relative_path=$(echo "$failed_file" | sed "s|$PROJECT_ROOT/||")
        echo "  - $relative_path"
    done
    
    echo ""
    echo "🔧 Common fixes:"
    echo "  - Quote variables: \"\$VARIABLE\" instead of \$VARIABLE"
    echo "  - Use [[ ]] instead of [ ] for conditions"
    echo "  - Check command existence before using"
    echo "  - Use 'local' for function variables"
    
    if [[ "$FIX_MODE" == "true" ]]; then
        echo ""
        echo "🛠️  Auto-fixing simple issues..."
        # Add simple auto-fixes here
        echo "   Auto-fix not implemented yet - manual fixes required"
    fi
    
    exit 1
else
    echo ""
    echo "🎉 All scripts passed ShellCheck!"
    echo "   Code quality: EXCELLENT"
fi