#!/bin/bash
# @fileoverview Unit tests for security-utils.sh
# @module tests/unit/security-utils
#
# @description
# Tests input validation and sanitization functions to ensure
# they properly protect against injection attacks.
#
# @usage
# ./test-security-utils.sh

# Get the test framework
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TEST_DIR/test-framework.sh"

# Source the library being tested
SCRIPT_DIR="$(cd "$TEST_DIR/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/security-utils.sh"

# Test validate_issue_number function
test_validate_issue_number_valid() {
    # Valid numbers should pass
    validate_issue_number "1" || fail "Should accept 1"
    validate_issue_number "42" || fail "Should accept 42"  
    validate_issue_number "9999" || fail "Should accept 9999"
}

test_validate_issue_number_invalid() {
    # Invalid inputs should fail
    ! validate_issue_number "" || fail "Should reject empty string"
    ! validate_issue_number "abc" || fail "Should reject letters"
    ! validate_issue_number "12.3" || fail "Should reject decimals"
    ! validate_issue_number "12a" || fail "Should reject mixed"
    ! validate_issue_number "-5" || fail "Should reject negative"
    ! validate_issue_number "0" || fail "Should reject zero"
    ! validate_issue_number "1000000" || fail "Should reject too large"
    ! validate_issue_number "'; DROP TABLE issues;--" || fail "Should reject SQL injection"
}

# Test sanitize_text_input function
test_sanitize_text_input() {
    local result
    
    # Basic text should pass through
    result=$(sanitize_text_input "Hello World")
    assert_equals "Hello World" "$result" "Basic text unchanged"
    
    # Control characters should be removed
    result=$(sanitize_text_input $'Hello\x00World')
    assert_equals "HelloWorld" "$result" "Null bytes removed"
    
    # Length limiting
    result=$(sanitize_text_input "12345678901" 10)
    assert_equals "1234567890" "$result" "Text truncated to max length"
}

# Test safe_graphql_string function  
test_safe_graphql_string() {
    local result
    
    # Basic escaping
    result=$(safe_graphql_string 'Hello "World"')
    assert_equals 'Hello \"World\"' "$result" "Quotes escaped"
    
    # Backslash escaping
    result=$(safe_graphql_string 'Path\to\file')
    assert_equals 'Path\\to\\file' "$result" "Backslashes escaped"
    
    # Complex escaping
    result=$(safe_graphql_string '"; mutation{deleteAll} "')
    assert_equals '\"; mutation{deleteAll} \"' "$result" "Injection attempt escaped"
}

# Test validate_project_id function
test_validate_project_id() {
    # Valid formats
    validate_project_id "PVT_kwHOCOLa384A62Y9" || fail "Should accept valid ID"
    
    # Invalid formats
    ! validate_project_id "" || fail "Should reject empty"
    ! validate_project_id "not-a-project-id" || fail "Should reject wrong format"
    ! validate_project_id "PVT_" || fail "Should reject incomplete"
    ! validate_project_id "ABC_kwHOCOLa384A62Y9" || fail "Should reject wrong prefix"
}

# Test validate_github_username function
test_validate_github_username() {
    # Valid usernames
    validate_github_username "octocat" || fail "Should accept simple username"
    validate_github_username "test-user-123" || fail "Should accept with hyphens"
    validate_github_username "a" || fail "Should accept single char"
    
    # Invalid usernames  
    ! validate_github_username "" || fail "Should reject empty"
    ! validate_github_username "-invalid" || fail "Should reject starting hyphen"
    ! validate_github_username "invalid-" || fail "Should reject ending hyphen"
    ! validate_github_username "in--valid" || fail "Should reject double hyphen"
    ! validate_github_username "in_valid" || fail "Should reject underscore"
    ! validate_github_username "in.valid" || fail "Should reject dot"
    ! validate_github_username "abcdefghijklmnopqrstuvwxyz0123456789abcd" || fail "Should reject too long"
}

# Mock gh auth status for testing
test_validate_github_auth() {
    # Create mock gh command
    create_mock_command "gh" '
if [[ "$1" == "auth" ]] && [[ "$2" == "status" ]]; then
    echo "✓ Logged in to github.com as test-user"
    echo "✓ Token scopes: project, read:project, repo"
    exit 0
fi
exit 1
'
    
    # Should pass with mock
    validate_github_auth || fail "Should pass with valid auth"
}

# Run all tests
echo "Testing security-utils.sh"
echo "========================"

run_test "validate_issue_number with valid input" test_validate_issue_number_valid
run_test "validate_issue_number with invalid input" test_validate_issue_number_invalid
run_test "sanitize_text_input" test_sanitize_text_input
run_test "safe_graphql_string" test_safe_graphql_string
run_test "validate_project_id" test_validate_project_id
run_test "validate_github_username" test_validate_github_username
run_test "validate_github_auth" test_validate_github_auth