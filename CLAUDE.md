# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

gh-pm is a command-line tool for AI-assisted project management using GitHub Projects. It provides enterprise-level project management capabilities with full AI assistant compatibility through a self-documenting CLI interface.

## Commands

### Running the CLI
```bash
# Main entry point - always use this for consistency
./gh-pm <command> [options]

# Always available options
--dry-run    # Test commands without making changes
--format json # Get JSON output for parsing
```

### Development Commands
Since this is a shell script project, there are no build/compile steps required. However:

```bash
# Make scripts executable after changes
chmod +x scripts/*.sh
chmod +x gh-pm

# Test individual scripts directly
./scripts/<script-name>.sh --dry-run [args]

# Check script syntax
bash -n scripts/<script-name>.sh
```

## Architecture

The project follows a modular shell script architecture:

1. **`gh-pm`** - Unified CLI that delegates to individual scripts
2. **`scripts/`** - All operational scripts organized by function
3. **`scripts/lib/dry-run-utils.sh`** - Shared utilities for dry-run mode
4. **`project-info.json`** - Stores GitHub Project IDs and field configurations

### Key Design Patterns

- **Dry-Run Safety**: Every write operation supports `--dry-run` for safe testing
- **GraphQL-Centric**: All GitHub operations use the GraphQL API
- **AI-First Design**: Includes discover, recommend, and batch operations specifically for AI assistants
- **Self-Contained**: No external dependencies beyond `gh` CLI and `jq`

### Script Categories

- **Setup**: `setup-*.sh` - Project initialization and configuration
- **Task Management**: `start-task.sh`, `complete-task.sh`, `review-*.sh`
- **Query**: `query-*.sh` - Status and dependency checking
- **Utilities**: `move-*.sh`, `check-dependencies.sh`

### Working with project-info.json

This file contains all GitHub Project field IDs. When modifying scripts that interact with GitHub Projects, always reference these IDs rather than hardcoding values.

## Important Notes

- Always use `--dry-run` when testing modifications to scripts
- The project uses GitHub's GraphQL API exclusively - refer to `docs/api-reference.md` for query templates
- When adding new scripts, follow the existing pattern: include dry-run support and use the shared utilities
- JSON output format is critical for AI assistant integration - maintain consistency in output structure