# gh-pm Foundation Improvements Plan

## Overview
This document outlines critical improvements needed to ensure gh-pm has a solid, secure, and maintainable foundation before adding new features.

## Priority 1: Critical Security Fixes (Must do immediately)

### 1.1 Input Validation & Sanitization
**Problem**: Scripts directly interpolate user input into GraphQL queries, creating injection vulnerabilities.

**Solution**:
- [ ] Add `security-utils.sh` to all scripts
- [ ] Validate all issue numbers with `validate_issue_number()`
- [ ] Sanitize all text inputs with `sanitize_text_input()`
- [ ] Use `safe_graphql_string()` for GraphQL queries

**Example Fix**:
```bash
# Before (VULNERABLE):
ISSUE_DATA=$(gh api graphql -f query='
  query {
    repository(owner: "'$GITHUB_OWNER'", name: "'$GITHUB_REPO'") {
      issue(number: '$ISSUE_NUMBER') {

# After (SECURE):
source "$SCRIPT_DIR/lib/security-utils.sh"

validate_issue_number "$ISSUE_NUMBER" || exit $ERR_INVALID_INPUT
OWNER_SAFE=$(safe_graphql_string "$GITHUB_OWNER")
REPO_SAFE=$(safe_graphql_string "$GITHUB_REPO")

ISSUE_DATA=$(gh api graphql -f query="
  query {
    repository(owner: \"$OWNER_SAFE\", name: \"$REPO_SAFE\") {
      issue(number: $ISSUE_NUMBER) {
```

### 1.2 Authentication Verification
**Problem**: Scripts don't verify GitHub CLI authentication before running.

**Solution**:
- [ ] Add `validate_github_auth()` check at start of each script
- [ ] Verify required scopes are present

### 1.3 Configuration Security
**Problem**: Sensitive data stored in plain text config.json

**Solution**:
- [ ] Add `.gitignore` entry for `config.json`
- [ ] Support environment variables for sensitive values
- [ ] Document secure configuration practices

## Priority 2: Error Handling & Reliability

### 2.1 Implement Proper Error Handling
**Problem**: Scripts exit immediately on error without cleanup or context.

**Solution**:
- [ ] Add `error-utils.sh` to all scripts
- [ ] Use `setup_error_handling()` at script start
- [ ] Register cleanup functions with `cleanup_on_exit()`
- [ ] Use specific error codes

**Template**:
```bash
#!/bin/bash
source "$SCRIPT_DIR/lib/error-utils.sh"
source "$SCRIPT_DIR/lib/security-utils.sh"

setup_error_handling

# Register cleanup
cleanup_temp_files() {
    rm -f "$TEMP_FILE" 2>/dev/null || true
}
cleanup_on_exit cleanup_temp_files
```

### 2.2 API Call Reliability
**Problem**: No retry logic for transient GitHub API failures.

**Solution**:
- [ ] Wrap API calls with `retry_with_backoff()`
- [ ] Add proper error messages for API failures
- [ ] Log errors to file for debugging

## Priority 3: Testing Infrastructure

### 3.1 Create Comprehensive Test Suite
**Problem**: Almost no tests exist, making changes risky.

**Structure**:
```
tests/
├── test-framework.sh      # Testing utilities (created)
├── unit/                  # Unit tests
│   ├── test-config-utils.sh
│   ├── test-security-utils.sh
│   └── test-field-utils.sh
├── integration/           # Integration tests
│   ├── test-github-api.sh
│   └── test-workflows.sh
└── run-all-tests.sh      # Main test runner
```

**Example Unit Test**:
```bash
#!/bin/bash
source tests/test-framework.sh
source scripts/lib/security-utils.sh

test_validate_issue_number() {
    # Valid cases
    validate_issue_number "123" || assert_equals 0 1 "Valid issue should pass"
    
    # Invalid cases
    ! validate_issue_number "abc" || assert_equals 0 1 "Non-numeric should fail"
    ! validate_issue_number "" || assert_equals 0 1 "Empty should fail"
}

run_test "validate_issue_number with valid input" test_validate_issue_number
```

### 3.2 Continuous Integration
**Problem**: No automated testing on commits.

**Solution**: Create `.github/workflows/test.yml`:
```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
      - name: Run shellcheck
        run: shellcheck scripts/*.sh scripts/lib/*.sh
      - name: Run tests
        run: ./tests/run-all-tests.sh
```

## Priority 4: Code Consistency

### 4.1 Standardize Script Structure
Create script template:
```bash
#!/bin/bash
# @fileoverview [Description]
# @module [module/name]
#
# [Full header per file-header-template.md]

set -euo pipefail

# Source order (always same)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/error-utils.sh"
source "$SCRIPT_DIR/lib/security-utils.sh"
source "$SCRIPT_DIR/lib/config-utils.sh"
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Setup
setup_error_handling
validate_github_auth || exit $ERR_AUTH

# Constants
readonly SCRIPT_NAME="$(basename "$0")"

# [Rest of script]
```

### 4.2 Linting & Standards
- [ ] Add `shellcheck` to all scripts
- [ ] Fix all shellcheck warnings
- [ ] Create `.shellcheckrc` for project standards
- [ ] Document coding standards

## Priority 5: Documentation & Headers

### 5.1 Add Headers to All Files
Using the template from `file-header-template.md`:
- [ ] Add headers to all scripts
- [ ] Add headers to all library files
- [ ] Create header validation script

### 5.2 API Documentation
Create comprehensive API docs for library functions:
- [ ] Document all public functions
- [ ] Include parameter descriptions
- [ ] Add return value documentation
- [ ] Provide usage examples

## Implementation Plan

### Phase 1: Security (Week 1)
1. Add security-utils.sh to all scripts
2. Fix all injection vulnerabilities
3. Add authentication checks
4. Secure configuration

### Phase 2: Error Handling (Week 1-2)
1. Add error-utils.sh to all scripts
2. Implement proper error handling
3. Add retry logic for API calls
4. Set up logging

### Phase 3: Testing (Week 2-3)
1. Create test framework
2. Write unit tests for utilities
3. Add integration tests
4. Set up CI/CD

### Phase 4: Standardization (Week 3-4)
1. Standardize all scripts
2. Add file headers
3. Run shellcheck and fix issues
4. Document standards

## Success Criteria

- [ ] Zero security vulnerabilities
- [ ] All scripts handle errors gracefully
- [ ] Test coverage > 80%
- [ ] All scripts pass shellcheck
- [ ] Consistent code structure
- [ ] Complete documentation

## Long-term Benefits

1. **Security**: Protected against injection attacks
2. **Reliability**: Graceful error handling and retries
3. **Maintainability**: Consistent, well-documented code
4. **Confidence**: Comprehensive test coverage
5. **Quality**: Automated checks prevent regressions

---

This foundation work is essential before adding new features. It will make gh-pm production-ready and maintainable for the long term.