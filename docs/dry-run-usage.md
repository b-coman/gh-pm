# Dry-Run Enhanced Scripts Usage Guide

This document provides usage examples for the three GitHub project management scripts that have been enhanced with dry-run capability.

## Enhanced Scripts

### 1. `move-to-ready.sh` - Move tasks to Ready status
Moves tasks from Blocked to Ready status after verifying all dependencies are complete.

**Usage:**
```bash
# Dry-run mode - see what would happen without making changes
./scripts/move-to-ready.sh 123 --dry-run

# Execute for real
./scripts/move-to-ready.sh 123

# Environment variable mode
DRY_RUN_MODE=true ./scripts/move-to-ready.sh 123
```

### 2. `request-rework.sh` - Request rework on tasks in Review
Moves tasks from Review back to In Progress with feedback comments.

**Usage:**
```bash
# Dry-run mode
./scripts/request-rework.sh 123 "Please add error handling" --dry-run

# Execute for real
./scripts/request-rework.sh 123 "Please add error handling"

# Environment variable mode
DRY_RUN_MODE=true ./scripts/request-rework.sh 123 "Fix validation logic"
```

### 3. `review-workflow-task.sh` - Move tasks to Review status
Moves tasks from In Progress to Review status for human approval.

**Usage:**
```bash
# Dry-run mode
./scripts/review-workflow-task.sh 123 "Implementation complete" --dry-run

# Execute for real (message is optional)
./scripts/review-workflow-task.sh 123

# With custom message
./scripts/review-workflow-task.sh 123 "Ready for architectural review"

# Environment variable mode
DRY_RUN_MODE=true ./scripts/review-workflow-task.sh 123
```

## Dry-Run Capabilities

When run in dry-run mode, these scripts will:

1. **Show what would be changed** without making actual modifications
2. **Use mock data** for demonstration purposes
3. **Skip all write operations** (GraphQL mutations, GitHub issue comments)
4. **Display comprehensive summaries** of planned changes
5. **Validate arguments and permissions** safely

## Dry-Run Activation Methods

### Method 1: Command Line Flag
```bash
./scripts/script-name.sh [args] --dry-run
```

### Method 2: Environment Variable
```bash
DRY_RUN_MODE=true ./scripts/script-name.sh [args]
```

### Method 3: Export Environment Variable
```bash
export DRY_RUN_MODE=true
./scripts/script-name.sh [args]
```

## Safety Features

- **Read operations work normally** - Scripts fetch real project data when possible
- **Write operations are mocked** - No actual changes to GitHub issues or project boards
- **Error handling preserved** - Scripts still validate arguments and show helpful errors
- **Clear visual indicators** - Cyan-colored output clearly shows dry-run operations
- **Comprehensive summaries** - Each script shows exactly what would be changed

## Example Output

In dry-run mode, you'll see output like:
```
🔍 DRY-RUN MODE ENABLED - No actual changes will be made
================================
🔍 DRY-RUN: Moving Task #123 to Ready
================================

🔍 DRY-RUN: Would fetch issue data for #123
🔍 DRY-RUN: Would execute Update Workflow Status to Review
🔍 DRY-RUN: Would execute: gh issue comment 123 --body [comment text]

✅ DRY-RUN COMPLETE: Review Request for Issue #123
🔍 Changes that would be made:
   Status: 🟡 In Progress → 🟣 Review, Message: Implementation complete
🔍 To execute for real, run without --dry-run flag
```

## Shared Utilities

All dry-run functionality is powered by shared utilities in `lib/dry-run-utils.sh` that provide:

- `init_dry_run()` - Initialize dry-run mode from arguments or environment
- `is_dry_run()` - Check if currently in dry-run mode
- `execute_mutation()` - Safe GraphQL mutation wrapper
- `gh_issue_safe()` - Safe GitHub issue command wrapper
- `verify_issue_safe()` - Safe issue verification with mocking
- `print_dry_run_summary()` - Standardized completion summaries

This ensures consistent behavior and easy maintenance across all enhanced scripts.