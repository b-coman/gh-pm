# [Foundation] Health Check Command

## Overview
Add a comprehensive system health check command that validates GitHub authentication, permissions, project configuration, and system dependencies. This provides users and AI assistants with immediate feedback on system readiness.

## Task Classification
- **Type**: Foundation
- **Risk Level**: Low
- **Effort**: Small
- **Dependencies**: None (can start immediately)

## Acceptance Criteria
- [ ] `./github-pm doctor` command implemented
- [ ] Validates GitHub CLI installation and version
- [ ] Checks GitHub authentication status and required scopes
- [ ] Verifies project permissions (read/write access)
- [ ] Validates project-info.json configuration
- [ ] Tests GraphQL API connectivity
- [ ] Checks for required system dependencies (jq, etc.)
- [ ] Provides actionable error messages for each failure
- [ ] Supports both human and JSON output formats
- [ ] Includes dry-run mode for safe testing
- [ ] Documentation updated with troubleshooting guide

## Technical Specification

### Command Interface
```bash
./github-pm doctor [--format=json] [--verbose]
```

### Validation Checks
1. **System Dependencies**
   - GitHub CLI presence and version
   - jq installation and functionality
   - Shell environment compatibility

2. **Authentication**
   - GitHub CLI authentication status
   - Required API scopes (project, read:project)
   - Token validity and expiration

3. **Project Configuration**
   - project-info.json exists and is valid JSON
   - Required fields present (project_id, field_ids, etc.)
   - GraphQL API accessibility with current config

4. **Permissions**
   - Read access to configured project
   - Write access for project modifications
   - Issue creation/modification permissions

### Output Format
```json
{
  "status": "healthy|issues|critical",
  "checks": {
    "github_cli": {"status": "pass", "version": "2.74.0"},
    "authentication": {"status": "pass", "scopes": ["project", "read:project"]},
    "project_config": {"status": "fail", "error": "project-info.json missing"},
    "permissions": {"status": "pass", "project_access": "read-write"}
  },
  "recommendations": [
    "Run 'gh auth refresh -s project,read:project' to fix authentication"
  ]
}
```

## Testing Strategy
- Unit tests for each validation check
- Integration tests with various auth states
- Error condition testing (missing files, bad auth, etc.)
- Cross-platform testing (macOS, Linux, Windows)

## Documentation Impact
- Add doctor command to main help
- Create troubleshooting section in docs/getting-started.md
- Update CLI reference documentation
- Add health check to CI/CD workflows

## Implementation Notes
- Use existing CLI patterns for consistency
- Leverage dry-run utilities for safe operation
- Provide progressive validation (don't stop on first failure)
- Include repair suggestions where possible