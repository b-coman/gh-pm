# gh-pm File Header Documentation Standard

## Purpose
Simple, practical file headers that provide immediate context for developers and AI assistants working with gh-pm bash scripts.

## Standard Header Template (Bash Scripts)

```bash
#!/bin/bash
# @fileoverview [Brief one-line description of what this script does]
# @module [Category]/[script-name] (e.g., workflow/start-task)
#
# @description
# [2-3 sentences explaining the purpose and main functionality.
# Focus on the "why" and "what" rather than implementation details.]
#
# @dependencies
# - Scripts: [lib/config-utils.sh, lib/dry-run-utils.sh, etc.]
# - Commands: [gh, jq, git - only non-standard ones]
# - APIs: [GitHub GraphQL v4, specific endpoints if relevant]
#
# @usage
# ./script-name.sh [options] <required-args> [optional-args]
#
# @options
# --dry-run    Preview changes without executing
# --json       Output in JSON format (if applicable)
#
# @example
# ./script-name.sh --dry-run 42
# ./script-name.sh 42 "Completion message"
```

## Simplified Template (For utility scripts)

```bash
#!/bin/bash
# @fileoverview [Brief description]
#
# @description
# [1-2 sentences about purpose]
#
# @usage
# source lib/script-name.sh  # For libraries
# ./script-name.sh [args]    # For executables
```

## Examples by Script Type

### Workflow Management Script
```bash
#!/bin/bash
# @fileoverview Move a task to review status for human approval
# @module workflow/review-task
#
# @description
# Transitions a task from "In Progress" to "Review" status, updating both
# native and workflow status fields. Adds a review request comment with
# guidance for the human reviewer.
#
# @dependencies
# - Scripts: lib/config-utils.sh, lib/dry-run-utils.sh, lib/field-utils.sh
# - Commands: gh, jq
# - APIs: GitHub GraphQL v4 (updateProjectV2ItemFieldValue)
#
# @usage
# ./review-workflow-task.sh [--dry-run] <issue-number> [review-message]
#
# @options
# --dry-run    Preview changes without executing
#
# @example
# ./review-workflow-task.sh 42 "Implementation complete"
# ./review-workflow-task.sh --dry-run 42
```

### Utility Library
```bash
#!/bin/bash
# @fileoverview Dynamic field management utilities for GitHub Projects
# @module lib/field-utils
#
# @description
# Provides functions to create custom fields, query field IDs by name,
# and manage field options dynamically. Eliminates need for hardcoded IDs.
#
# @provides
# - get_field_id_dynamic(): Get field ID by config name
# - get_field_option_id_dynamic(): Get option ID by field and value
# - create_standard_fields(): Create all gh-pm standard fields
#
# @usage
# source lib/field-utils.sh
```

### Configuration Script
```bash
#!/bin/bash
# @fileoverview Configuration management utilities
# @module lib/config-utils
#
# @description
# Loads and validates gh-pm configuration from config.json.
# Provides getter functions for common configuration values.
#
# @provides
# - load_config(): Validate and load configuration
# - get_github_owner(): Get GitHub repository owner
# - get_project_id(): Get GitHub Project ID
#
# @usage
# source lib/config-utils.sh
```

## When to Update Headers

| Change Type | Update Required? | What to Update |
|------------|-----------------|----------------|
| Bug fix | ❌ No | Nothing |
| Add new option | ✅ Yes | `@options`, `@example` |
| Change arguments | ✅ Yes | `@usage`, `@example` |
| Add dependency | ✅ Yes | `@dependencies` |
| Major refactor | ✅ Yes | `@description` |
| Breaking change | ✅ Yes | Add `# BREAKING:` comment |

## Key Principles

1. **Keep it Practical**: Only include information that helps users and developers
2. **Focus on Usage**: Emphasize how to use the script over implementation details
3. **Update Sparingly**: Only update when interface or purpose changes
4. **Real Examples**: Always include working command examples

## Benefits

1. **Quick Understanding**: New developers grasp script purpose immediately
2. **AI-Friendly**: Provides context for AI assistants and automation
3. **Searchable**: Can grep for patterns like "@module workflow"
4. **Self-Documenting**: Usage examples serve as mini-tutorials

## Validation

Simple validation can be done with:
```bash
# Check all scripts have headers
grep -L "@fileoverview" scripts/*.sh

# Find scripts missing usage examples
grep -L "@example" scripts/*.sh

# List all workflow scripts
grep -l "@module workflow" scripts/*.sh
```

## Optional Sections

Add these only when relevant:

```bash
# @breaking [version] [description of breaking change]
# @deprecated Use [alternative] instead
# @todo [planned improvements]
# @see [related script or documentation]
```

---

Remember: The best documentation is the one that gets written and maintained. Keep headers focused on what matters most - helping others understand and use your scripts effectively.