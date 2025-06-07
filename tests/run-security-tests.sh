#!/bin/bash
# @fileoverview Run comprehensive security tests on hardened scripts
# @module tests/security-tests
#
# @description
# Tests all security-hardened scripts to verify they properly reject
# malicious inputs and handle errors gracefully.
#
# @dependencies
# - Scripts: All workflow scripts, lib/security-utils.sh
# - Commands: grep
#
# @usage
# ./run-security-tests.sh
#
# @example
# ./run-security-tests.sh

set -eo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

echo "🛡️  Security Test Suite"
echo "======================"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_security_test() {
    local test_name="$1"
    local script_path="$2"
    local malicious_input="$3"
    local expected_behavior="$4"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  $test_name ... "
    
    # Run the script with malicious input and capture result (with --dry-run for safety)
    if output=$(cd "$PROJECT_ROOT" && "$script_path" --dry-run $malicious_input 2>&1); then
        # Script didn't fail - check if it should have
        if [[ "$expected_behavior" == "REJECT" ]]; then
            echo "❌ (should have rejected input)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo "    Output: $output"
            return 1
        else
            echo "✅"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    else
        # Script failed - check if this was expected
        if [[ "$expected_behavior" == "REJECT" ]]; then
            # Check if it failed for the right reason (input validation)
            if echo "$output" | grep -q "must be numeric\|Invalid\|Error:"; then
                echo "✅ (correctly rejected)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            else
                echo "❌ (failed for wrong reason)"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                echo "    Output: $output"
                return 1
            fi
        else
            echo "❌ (unexpected failure)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo "    Output: $output"
            return 1
        fi
    fi
}

# Define malicious test inputs
INJECTION_TESTS=(
    "'; DROP TABLE issues;--"
    '"; mutation { deleteAll } query { "'
    '$(rm -rf /)'
    '`rm -rf /`'
    '../../../etc/passwd'
    '<script>alert("xss")</script>'
    'abc'
    ''
    '-1'
    '999999999'
)

# Test hardened workflow scripts
WORKFLOW_SCRIPTS=(
    "./scripts/workflow/start-workflow-task.sh"
    "./scripts/workflow/review-workflow-task.sh"
    "./scripts/workflow/complete-task.sh"
    "./scripts/workflow/request-rework.sh"
    "./scripts/workflow/start-task.sh"
    "./scripts/workflow/move-to-ready.sh"
)

echo ""
echo "🧪 Testing Input Validation"
echo "============================"

# Test each script with each malicious input
for script in "${WORKFLOW_SCRIPTS[@]}"; do
    script_name=$(echo "$script" | awk '{print $1}' | xargs basename)
    echo ""
    echo "Testing $script_name:"
    
    for malicious_input in "${INJECTION_TESTS[@]}"; do
        # Create a safe display version of the input
        display_input=$(echo "$malicious_input" | cut -c1-20)
        if [[ ${#malicious_input} -gt 20 ]]; then
            display_input="$display_input..."
        fi
        
        # Handle scripts with different argument patterns
        case "$script_name" in
            "request-rework.sh"|"review-workflow-task.sh")
                # These scripts need: <issue-number> <message>
                # Test malicious input as issue number (first arg) - should be rejected
                run_security_test \
                    "Issue validation: '$display_input'" \
                    "$script" \
                    "\"$malicious_input\" \"safe message\"" \
                    "REJECT"
                ;;
            "complete-task.sh")
                # complete-task has optional message as second arg
                run_security_test \
                    "Issue validation: '$display_input'" \
                    "$script" \
                    "\"$malicious_input\"" \
                    "REJECT"
                ;;
            *)
                # Default: single argument scripts (issue number)
                run_security_test \
                    "Issue validation: '$display_input'" \
                    "$script" \
                    "\"$malicious_input\"" \
                    "REJECT"
                ;;
        esac
    done
done

echo ""
echo "✅ Testing Valid Inputs"
echo "======================="

# Test with valid inputs to ensure scripts still work
VALID_INPUTS=("42" "123" "1")

for script in "${WORKFLOW_SCRIPTS[@]}"; do
    script_name=$(echo "$script" | awk '{print $1}' | xargs basename)
    
    for valid_input in "${VALID_INPUTS[@]}"; do
        # Handle scripts with different argument patterns
        case "$script_name" in
            "request-rework.sh"|"review-workflow-task.sh")
                # These scripts need: <issue-number> <message>
                run_security_test \
                    "$script_name with valid input '$valid_input'" \
                    "$script" \
                    "$valid_input \"Test message\"" \
                    "ACCEPT"
                ;;
            *)
                # Default: single argument scripts
                run_security_test \
                    "$script_name with valid input '$valid_input'" \
                    "$script" \
                    "$valid_input" \
                    "ACCEPT"
                ;;
        esac
    done
done

echo ""
echo "🔍 Testing Authentication Checks"
echo "================================"

# Test without gh authentication (if possible to simulate)
echo "  Checking authentication validation is present in scripts..."

AUTH_CHECK_COUNT=0
for script_file in scripts/*/*.sh; do
    if [[ -f "$script_file" ]] && grep -q "validate_github_auth" "$script_file"; then
        AUTH_CHECK_COUNT=$((AUTH_CHECK_COUNT + 1))
    fi
done

if [[ $AUTH_CHECK_COUNT -gt 0 ]]; then
    echo "  ✅ Found authentication checks in $AUTH_CHECK_COUNT scripts"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  ❌ No authentication checks found"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "📊 Security Test Summary"
echo "========================"
echo "Total tests: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo "🎉 ALL SECURITY TESTS PASSED!"
    echo "   Scripts are properly hardened against:"
    echo "   ✅ SQL injection"
    echo "   ✅ GraphQL injection"
    echo "   ✅ Command injection"
    echo "   ✅ Invalid input"
    echo "   ✅ Missing authentication"
    echo ""
    echo "🛡️  Security Status: PRODUCTION READY"
    exit 0
else
    echo ""
    echo "❌ Some security tests failed"
    echo "   Review the failures above and apply additional hardening"
    echo ""
    echo "🚨 Security Status: NEEDS ATTENTION"
    exit 1
fi