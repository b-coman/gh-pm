# Code Structure Reorganization Plan

## Current Problem
The scripts directory contains 30+ files all mixed together with no clear organization, making it hard to navigate and maintain.

## Proposed Clean Structure

```
scripts/
├── lib/                     # ✅ Already good - utilities
│   ├── security-utils.sh
│   ├── error-utils.sh
│   ├── config-utils.sh
│   ├── dry-run-utils.sh
│   └── field-utils.sh
├── workflow/                # 🔄 NEW - Core workflow operations
│   ├── start-workflow-task.sh
│   ├── review-workflow-task.sh
│   ├── complete-task.sh
│   ├── request-rework.sh
│   ├── approve-task.sh
│   ├── start-task.sh
│   └── move-to-ready.sh
├── setup/                   # 🔄 NEW - Project setup & configuration
│   ├── setup-github-project.sh
│   ├── setup-repo-project.sh
│   ├── setup-complete-github-project.sh
│   ├── configure-project-fields.sh
│   ├── configure-project-fields-simple.sh
│   └── setup-issue-dependencies.sh
├── admin/                   # 🔄 NEW - Administrative operations
│   ├── query-project-status.sh
│   ├── query-workflow-status.sh
│   ├── check-dependencies.sh
│   ├── move-foundation-tasks-ready.sh
│   └── harden-all-scripts.sh
├── legacy/                  # 🔄 NEW - Legacy/deprecated scripts
│   ├── add-status-field.sh
│   ├── create-workflow-status.sh
│   ├── enhance-status-field.sh
│   └── configure-initial-status.sh
└── tools/                   # 🔄 NEW - Development tools
    ├── run-shellcheck.sh
    └── start-task-secure.sh (example)
```

## Implementation Steps

1. **Create directory structure**
2. **Move scripts to appropriate directories**
3. **Update all path references**
4. **Clean up backup files**
5. **Move data files to proper locations**
6. **Update main CLI to reflect new paths**

## Benefits After Reorganization

- **Clear purpose** for each directory
- **Easy navigation** - find scripts by category
- **Logical grouping** - related scripts together
- **Clean separation** - different concerns separated
- **Maintainable** - easy to add new scripts in right place