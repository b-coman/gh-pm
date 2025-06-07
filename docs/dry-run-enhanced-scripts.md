# Enhanced GitHub Project Management Scripts with Dry-Run Support

This document describes the enhanced GitHub project management scripts that now include comprehensive dry-run capability for safe testing and demonstration.

## Enhanced Scripts Overview

The following critical scripts have been enhanced with dry-run support:

### 1. Workflow Management Scripts
- **`start-workflow-task.sh`** - Starts workflow tasks by moving them to "In Progress" status
- **`move-foundation-tasks-ready.sh`** - Batch moves foundation tasks (#39, #40, #41) to ready status

### 2. Project Configuration Scripts  
- **`configure-project-fields.sh`** - Configures custom field values and dependencies for all issues
- **`create-workflow-status.sh`** - Creates workflow status fields with options (Backlog, Ready, Blocked, In Progress, Review, Done)

### 3. Setup and Dependencies Scripts
- **`setup-complete-github-project.sh`** - Master orchestrator script for complete project setup
- **`setup-issue-dependencies.sh`** - Sets up issue dependencies and blocking relationships

## Dry-Run Features

### Activation Methods
All enhanced scripts support multiple ways to enable dry-run mode:

1. **Command-line flag**: `--dry-run`
   ```bash
   ./start-workflow-task.sh 39 --dry-run
   ```

2. **Environment variable**: `DRY_RUN_MODE=true`
   ```bash
   DRY_RUN_MODE=true ./start-workflow-task.sh 39
   ```

### Safety Features

#### Mock Data Generation
- **Project Item IDs**: Mock project item IDs for GraphQL operations
- **Issue Titles**: Generated mock titles based on issue numbers
- **Status Data**: Realistic mock status information
- **Dependencies**: Sample dependency structures

#### Safe Operations
- **GitHub API Calls**: All GraphQL mutations are intercepted and logged instead of executed
- **Issue Commands**: GitHub CLI issue operations show what would be executed
- **File Operations**: JSON file updates are simulated with descriptive output
- **Validation**: All pre-checks and validations still run to verify setup

#### Clear Visual Feedback
- **Distinct Headers**: Dry-run mode is clearly indicated with 🔍 DRY-RUN prefixes
- **Operation Logging**: Each action shows exactly what would be executed
- **Completion Summary**: Comprehensive summary of what would have been done
- **Next Steps**: Clear instructions on how to execute for real

## Usage Examples

### Testing Workflow Task Startup
```bash
# Test starting a workflow task
./start-workflow-task.sh 39 --dry-run

# Output includes:
# 🔍 DRY-RUN MODE ENABLED - No actual changes will be made
# 🔍 DRY-RUN: Would fetch issue data for #39
# 🔍 DRY-RUN: Would check project item for task #39
# 🔍 DRY-RUN: Would check for other tasks in progress
# 🔍 DRY-RUN: Would execute Update Workflow Status to In Progress
# ✅ DRY-RUN COMPLETE: Start Workflow Task for Issue #39
```

### Testing Foundation Tasks Movement
```bash
# Test moving foundation tasks to ready
./move-foundation-tasks-ready.sh --dry-run

# Shows simulation of:
# - Fetching project field information
# - Getting project item IDs for issues #39, #40, #41
# - Moving each task to Ready status
# - Complete summary of changes that would be made
```

### Testing Complete Project Setup
```bash
# Test the entire project setup process
./setup-complete-github-project.sh --dry-run

# Simulates:
# - GitHub authentication and permission checks
# - Project creation with custom fields
# - Adding all 12 issues to the project
# - Configuring field values and dependencies
# - Setting initial workflow statuses
```

### Testing Field Configuration
```bash
# Test configuring all project fields
./configure-project-fields.sh --dry-run

# Shows what would happen for:
# - Setting Task Type, Risk Level, Effort fields
# - Configuring Dependencies text field for all 12 issues
# - Foundation → Enhancement → Migration → QA → Documentation workflow
```

### Testing Dependency Setup
```bash
# Test issue dependency configuration
./setup-issue-dependencies.sh --dry-run

# Demonstrates:
# - Adding "blocked" labels to dependent issues
# - Updating issue descriptions with dependency information
# - Complete dependency structure documentation
```

## Error Handling in Dry-Run Mode

### Validation Still Occurs
- **Project Info**: Checks for project-info.json file
- **Authentication**: Validates GitHub CLI authentication (when not mocking)
- **Prerequisites**: Verifies required tools (jq, gh CLI)
- **Arguments**: Validates command-line arguments

### Mock Error Scenarios
Some scripts may simulate error conditions to demonstrate error handling:
- Issue not found scenarios
- Permission failures (when applicable)
- Invalid project states

## Integration with Real Operations

### Seamless Transition
After dry-run validation, simply remove the `--dry-run` flag:
```bash
# Test first
./start-workflow-task.sh 39 --dry-run

# Execute for real
./start-workflow-task.sh 39
```

### Orchestrator Script Support
The master setup script (`setup-complete-github-project.sh`) passes dry-run mode to all sub-scripts automatically:
```bash
# Tests the entire setup pipeline
./setup-complete-github-project.sh --dry-run

# Executes the complete setup
./setup-complete-github-project.sh
```

## Best Practices

### 1. Always Test First
```bash
# RECOMMENDED: Test before executing
./script-name.sh args --dry-run
./script-name.sh args
```

### 2. Use Environment Variables for Batch Testing
```bash
# Test multiple scripts in sequence
export DRY_RUN_MODE=true
./setup-complete-github-project.sh
./move-foundation-tasks-ready.sh
./start-workflow-task.sh 39
unset DRY_RUN_MODE
```

### 3. Review Dry-Run Output
- **Check Dependencies**: Verify dependency relationships are correct
- **Validate Field Values**: Ensure custom field values make sense
- **Confirm Workflow**: Validate workflow status transitions
- **Review Descriptions**: Check issue description updates

### 4. Progressive Execution
For complex setups, execute in stages:
```bash
# Stage 1: Core project setup
./setup-complete-github-project.sh --dry-run
./setup-complete-github-project.sh

# Stage 2: Workflow configuration  
./create-workflow-status.sh --dry-run
./create-workflow-status.sh

# Stage 3: Task management
./move-foundation-tasks-ready.sh --dry-run
./move-foundation-tasks-ready.sh
```

## Technical Implementation

### Shared Utilities
All enhanced scripts use `/scripts/lib/dry-run-utils.sh` which provides:
- **`init_dry_run()`**: Initialize dry-run mode from arguments/environment
- **`is_dry_run()`**: Check if currently in dry-run mode
- **`execute_mutation()`**: Safe GraphQL mutation wrapper
- **`gh_api_safe()`**: Safe GitHub API wrapper
- **`gh_issue_safe()`**: Safe GitHub issue command wrapper
- **Mock data generators**: Consistent mock data across scripts

### Error Safety
- **No Side Effects**: Dry-run mode guarantees no actual changes
- **Reversible**: All operations can be safely tested
- **Isolated**: Mock data doesn't interfere with real project data
- **Consistent**: Same behavior across all enhanced scripts

## Troubleshooting

### Common Issues

#### Script Not Finding Dry-Run Utils
```bash
# Error: source: dry-run-utils.sh: No such file or directory
# Solution: Ensure you're running from the scripts directory
cd scripts
./script-name.sh --dry-run
```

#### Missing Project Info in Dry-Run
```bash
# Some scripts require project-info.json even in dry-run mode
# Create a minimal mock file if needed for testing:
echo '{"project_id":"MOCK","project_url":"https://mock.url"}' > project-info.json
```

#### Permission Errors in Mock Mode  
Dry-run mode bypasses most permission checks, but some validation still occurs. Ensure GitHub CLI is authenticated for complete testing.

## Benefits of Enhanced Dry-Run Support

### 1. Risk Mitigation
- **Zero Risk Testing**: Test complex operations without any side effects
- **Validation**: Verify setup correctness before execution
- **Learning**: Understand what each script does before running

### 2. Development and Debugging
- **Script Development**: Test script modifications safely
- **Integration Testing**: Verify script interactions
- **Documentation**: Generate accurate documentation from dry-run output

### 3. Training and Demonstration
- **Team Training**: Show team members how scripts work
- **Client Demos**: Demonstrate project management capabilities
- **Process Documentation**: Create step-by-step guides

### 4. Operational Safety
- **Production Safety**: Test operations in production-like environments
- **Rollback Planning**: Understand all changes before making them
- **Audit Trail**: Document all planned changes

The enhanced dry-run capability makes these GitHub project management scripts safe, predictable, and suitable for both development and production use cases.