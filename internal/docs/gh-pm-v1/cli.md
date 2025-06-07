# Unified CLI Interface
## Single Entry Point for GitHub Project Management

**Version**: 1.0  
**Status**: Production Ready  
**File**: `gh-pm`  
**Design Goal**: AI Assistant Friendly  

---

## Overview

The unified CLI interface provides a single, consistent entry point for all GitHub project management operations. Designed specifically for AI assistant integration with self-documenting features and predictable patterns.

## Core Design Principles

### 1. Self-Documenting
- Built-in help system with `--help` and `help <command>`
- Command discovery via `list` command
- Rich examples and usage patterns
- Context-aware error messages

### 2. Predictable Patterns
- Consistent argument structures across commands
- Standard option handling (`--dry-run`, `--help`)
- Uniform output formatting
- Expected exit codes

### 3. AI-Friendly Features
- Safe exploration with universal dry-run support
- Command categorization for easy discovery
- Detailed help for each operation
- Clear error guidance

## Architecture

### Entry Point
**File**: `gh-pm` (executable script in project root)

### Command Delegation
The CLI acts as a dispatcher, delegating to individual scripts in `scripts/` directory:

```bash
gh-pm start 42     →  scripts/start-task.sh 42
gh-pm setup        →  scripts/setup-github-project.sh
gh-pm complete 42  →  scripts/complete-task.sh 42
```

### Argument Processing
1. **Global options parsed first**: `--dry-run`, `--help`, `--version`
2. **Command identification**: First non-option argument
3. **Argument delegation**: Remaining arguments passed to target script
4. **Option propagation**: `--dry-run` automatically added to delegated calls

## Command Categories

### Setup & Configuration
```bash
gh-pm setup                     # Create new GitHub project
gh-pm configure                 # Configure project fields  
gh-pm status                    # Show project dashboard
```

### Task Management
```bash
gh-pm start <issue>             # Move task to In Progress
gh-pm complete <issue> [msg]    # Move task to Done
gh-pm approve <issue> [msg]     # Approve task from Review
gh-pm review <issue>            # Move task to Review
gh-pm rework <issue> <feedback> # Request changes
gh-pm ready <issue>             # Unblock task
```

### Batch Operations
```bash
gh-pm ready-foundation          # Move foundation tasks to Ready
gh-pm dependencies              # Check dependencies
```

### Information & Help
```bash
gh-pm list                      # List all commands
gh-pm help [command]            # Show help
gh-pm version                   # Show version
```

## Help System

### Global Help
```bash
gh-pm --help
gh-pm help
```

**Output Structure**:
- Tool description and version
- Usage syntax
- Command categories with descriptions
- Global options
- Examples section
- AI assistant guidance

### Command-Specific Help
```bash
gh-pm help start
gh-pm help complete
```

**Template**:
```
gh-pm <command> <args> [--dry-run]
<Description of what command does>

Arguments:
  <arg>       Description of argument

Examples:
  gh-pm <command> <example>     # Description
  gh-pm <command> --dry-run     # Test mode
```

### Command Discovery
```bash
gh-pm list
```

**Output**: Categorized list of all available commands with brief descriptions.

## Implementation Details

### Command Mapping
```bash
case "$COMMAND" in
    "setup")
        exec "$SCRIPT_DIR/scripts/setup-github-project.sh" $DRY_RUN_FLAG
        ;;
    "start")
        exec "$SCRIPT_DIR/scripts/start-task.sh" "${ARGS[0]}" $DRY_RUN_FLAG
        ;;
    "complete")
        exec "$SCRIPT_DIR/scripts/complete-task.sh" "${ARGS[@]}" $DRY_RUN_FLAG
        ;;
    # ... etc
esac
```

### Argument Validation
```bash
# Example: start command requires issue number
if [[ ${#ARGS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ Error: Issue number required${NC}"
    echo "Usage: gh-pm start <issue> [--dry-run]"
    exit 1
fi
```

### Global Option Processing
```bash
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN_FLAG="--dry-run"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            echo "gh-pm version $VERSION"
            exit 0
            ;;
        # ... etc
    esac
done
```

## Usage Patterns

### Basic Operations
```bash
# Check what's available
gh-pm help
gh-pm list

# Check project status
gh-pm status

# Work with tasks
gh-pm start 42
gh-pm complete 42 "Feature implemented"
```

### Safe Testing Pattern (AI-Friendly)
```bash
# Always test first
gh-pm start 42 --dry-run
# Then execute if good
gh-pm start 42
```

### Discovery Pattern (AI Learning)
```bash
# Explore capabilities
gh-pm help           # General overview
gh-pm list           # All commands
gh-pm help start     # Specific command
gh-pm help complete  # Another command
```

### Workflow Pattern
```bash
# Typical development workflow
gh-pm status                    # Check current state
gh-pm ready 42 --dry-run       # Test unblocking
gh-pm ready 42                 # Unblock task
gh-pm start 42                 # Start work
gh-pm complete 42 "Done"       # Complete work
gh-pm status                   # Verify new state
```

## Error Handling

### Invalid Commands
```bash
$ gh-pm unknown-command
❌ Unknown command: unknown-command

Available commands:
  setup, configure, status
  start, complete, approve, review, rework, ready
  ready-foundation, dependencies
  list, help, version
```

### Missing Arguments
```bash
$ gh-pm start
❌ Error: Issue number required
Usage: gh-pm start <issue> [--dry-run]
```

### Help Guidance
```bash
$ gh-pm help unknown-command
❌ Unknown command: unknown-command
Use 'gh-pm help' to see all available commands
```

## AI Assistant Integration

### Discovery Flow
1. **Entry**: `gh-pm help` - Get overview
2. **Exploration**: `gh-pm list` - See all commands
3. **Learning**: `gh-pm help <command>` - Understand specific operations
4. **Testing**: `gh-pm <command> --dry-run` - Safe experimentation
5. **Execution**: `gh-pm <command>` - Real operations

### Predictable Patterns
- **Consistent syntax**: `gh-pm <command> <args> [--dry-run]`
- **Standard options**: `--dry-run` works with all write operations
- **Expected outputs**: Success/error states clearly indicated
- **Help availability**: Every command has detailed help

### Safety Features
- **Universal dry-run**: All write operations support `--dry-run`
- **Validation preserved**: Argument checking works in dry-run mode
- **Clear indicators**: Dry-run mode visually distinct
- **No surprises**: Predictable behavior across all commands

## Benefits

### For AI Assistants
- **Easy exploration** - Self-documenting interface
- **Safe testing** - Universal dry-run support
- **Predictable behavior** - Consistent patterns
- **Rich context** - Detailed help and examples

### For Developers
- **Single interface** - One command to remember
- **Consistent experience** - Same patterns across operations
- **Built-in help** - No need to reference external docs
- **Safety first** - Dry-run available everywhere

### For Teams
- **Lower learning curve** - Intuitive command structure
- **Self-service** - Built-in documentation
- **Mistake prevention** - Easy testing before execution
- **Standardization** - Consistent tool usage

## Future Enhancements

### Planned Improvements
- **Shell completion** - Tab completion for commands and arguments
- **Interactive mode** - Guided command execution
- **Configuration wizard** - Setup assistance
- **Aliases** - Short command names for frequent operations

### Integration Options
- **Package manager** - npm/brew distribution
- **Global installation** - System-wide availability
- **Project templates** - Include in project scaffolding
- **CI/CD integration** - Automated project management

## Version History

### v1.0 (Current)
- Initial unified CLI implementation
- Complete command coverage (17 underlying scripts)
- Self-documenting help system
- Universal dry-run support
- AI assistant optimized interface

### Future Versions
- v1.1: Shell completion and aliases
- v1.2: Interactive mode and wizards
- v2.0: Multi-project support and advanced features

---

The unified CLI interface transforms the collection of individual scripts into a cohesive, professional tool that's perfect for AI assistant integration while remaining intuitive for human users.