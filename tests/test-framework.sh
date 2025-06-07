#!/bin/bash
# @fileoverview Testing framework for gh-pm scripts
# @module tests/test-framework
#
# @description
# Provides testing utilities and assertions for gh-pm test suite.
# Supports unit tests, mocking, and test result reporting.
#
# @usage
# source tests/test-framework.sh

# Test result tracking
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0
declare -a FAILED_TESTS=()

# Colors for test output
readonly TEST_GREEN='\033[0;32m'
readonly TEST_RED='\033[0;31m'
readonly TEST_YELLOW='\033[1;33m'
readonly TEST_BLUE='\033[0;34m'
readonly TEST_NC='\033[0m'

# Test environment setup
TEST_TEMP_DIR=""
ORIGINAL_PATH="$PATH"

# Initialize test environment
init_test_env() {
    TEST_TEMP_DIR=$(mktemp -d -t gh-pm-test.XXXXXX)
    export GH_PM_TEST_MODE=1
    
    # Create mock directories
    mkdir -p "$TEST_TEMP_DIR/mocks"
    mkdir -p "$TEST_TEMP_DIR/data"
    
    # Add mocks to PATH
    export PATH="$TEST_TEMP_DIR/mocks:$PATH"
    
    # Set test config file
    export CONFIG_FILE="$TEST_TEMP_DIR/data/test-config.json"
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    
    export PATH="$ORIGINAL_PATH"
    unset GH_PM_TEST_MODE
}

# Run a test function
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo -n "  $test_name ... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Create isolated test environment
    local test_dir="$TEST_TEMP_DIR/test-$TESTS_RUN"
    mkdir -p "$test_dir"
    cd "$test_dir" || return 1
    
    # Run test in subshell to isolate failures
    if (
        set -e
        $test_func
    ) > "$test_dir/output.log" 2>&1; then
        echo -e "${TEST_GREEN}✓${TEST_NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${TEST_RED}✗${TEST_NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        
        # Show test output on failure
        echo -e "${TEST_RED}    Output:${TEST_NC}"
        sed 's/^/      /' "$test_dir/output.log"
    fi
    
    cd - > /dev/null
}

# Test assertions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" != "$actual" ]]; then
        echo "Assertion failed: $message" >&2
        echo "  Expected: '$expected'" >&2
        echo "  Actual:   '$actual'" >&2
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Assertion failed: $message" >&2
        echo "  String:    '$haystack'" >&2
        echo "  Should contain: '$needle'" >&2
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    if [[ ! -f "$file" ]]; then
        echo "Assertion failed: $message" >&2
        echo "  File not found: '$file'" >&2
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Exit code should match}"
    
    if [[ "$expected" -ne "$actual" ]]; then
        echo "Assertion failed: $message" >&2
        echo "  Expected exit code: $expected" >&2
        echo "  Actual exit code:   $actual" >&2
        return 1
    fi
}

# Mock creation utilities
create_mock_command() {
    local cmd_name="$1"
    local mock_behavior="$2"
    
    cat > "$TEST_TEMP_DIR/mocks/$cmd_name" << EOF
#!/bin/bash
# Mock for $cmd_name
$mock_behavior
EOF
    
    chmod +x "$TEST_TEMP_DIR/mocks/$cmd_name"
}

# Create mock gh command
mock_gh_cli() {
    create_mock_command "gh" '
case "$1" in
    "auth")
        case "$2" in
            "status")
                echo "Logged in to github.com as test-user"
                exit 0
                ;;
        esac
        ;;
    "api")
        if [[ "$2" == "graphql" ]]; then
            # Return mock GraphQL response
            echo "{\"data\": {\"mock\": \"response\"}}"
            exit 0
        fi
        ;;
    "issue")
        case "$2" in
            "comment")
                echo "Mock comment added to issue $3"
                exit 0
                ;;
        esac
        ;;
esac
echo "Mock gh: Unhandled command: $*" >&2
exit 1
'
}

# Create test configuration
create_test_config() {
    cat > "$CONFIG_FILE" << 'EOF'
{
  "github": {
    "owner": "test-owner",
    "repository": "test-repo",
    "user_id": "U_test123"
  },
  "project": {
    "id": "PVT_test123",
    "url": "https://github.com/users/test-owner/projects/1",
    "number": 1,
    "title": "Test Project"
  },
  "fields": {
    "status": {
      "id": "PVTF_status_test"
    },
    "workflow_status": {
      "id": "PVTF_workflow_test"
    }
  }
}
EOF
}

# Test suite runner
run_test_suite() {
    local suite_name="$1"
    shift
    local test_files=("$@")
    
    echo -e "${TEST_BLUE}Running test suite: $suite_name${TEST_NC}"
    echo "================================"
    
    init_test_env
    
    # Source all test files
    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            echo -e "${TEST_YELLOW}Running tests from: $(basename "$test_file")${TEST_NC}"
            source "$test_file"
        else
            echo -e "${TEST_RED}Test file not found: $test_file${TEST_NC}"
        fi
    done
    
    # Print summary
    echo ""
    echo "================================"
    echo -e "${TEST_BLUE}Test Summary:${TEST_NC}"
    echo "  Total:  $TESTS_RUN"
    echo -e "  ${TEST_GREEN}Passed: $TESTS_PASSED${TEST_NC}"
    echo -e "  ${TEST_RED}Failed: $TESTS_FAILED${TEST_NC}"
    
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${TEST_RED}Failed tests:${TEST_NC}"
        for failed in "${FAILED_TESTS[@]}"; do
            echo "  - $failed"
        done
    fi
    
    cleanup_test_env
    
    # Exit with appropriate code
    [[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
}