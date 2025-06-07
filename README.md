# GitHub Project AI Manager
## AI-Friendly Project Management for Software Development

[![Claude Code Compatible](https://img.shields.io/badge/Claude%20Code-Compatible-blue.svg)](https://claude.ai/code)
[![Dry Run Safe](https://img.shields.io/badge/Dry%20Run-Safe-green.svg)]()
[![AI Assistant Friendly](https://img.shields.io/badge/AI%20Assistant-Friendly-purple.svg)]()

**Designed specifically for AI assistants like Claude Code** - Professional GitHub project management with complete dry-run safety and intuitive CLI interface.

---

## 🤖 Perfect for AI Assistants

This tool is specifically designed to work seamlessly with AI assistants like Claude Code:

- **🔍 Comprehensive dry-run mode** - Test everything safely before execution
- **📖 Self-documenting interface** - Built-in help and command discovery
- **🎯 Predictable CLI patterns** - Consistent argument structures
- **🛡️ Safe exploration** - Zero risk of accidental changes
- **📊 Rich feedback** - Detailed status and progress information

---

## ⚡ Quick Start

### One-Command Setup
```bash
# Clone and test
git clone <repository-url>
cd github-project-ai-manager

# Test project creation (safe!)
./gh-pm setup --dry-run

# Create actual project
./gh-pm setup
```

### Daily Workflow
```bash
# Check project status
./gh-pm status

# Start working on a task
./gh-pm start 42 --dry-run    # Test first
./gh-pm start 42              # Execute

# Complete a task
./gh-pm complete 42 "All tests passing"

# Get help anytime
./gh-pm help
./gh-pm help complete
```

---

## 🎯 Core Commands

### Project Management
```bash
./gh-pm setup                     # Create GitHub project
./gh-pm status                    # Show project dashboard
./gh-pm dependencies              # Check task dependencies
```

### Task Workflow
```bash
./gh-pm start <issue>             # Move to In Progress
./gh-pm complete <issue> [msg]    # Move to Done
./gh-pm review <issue>            # Move to Review
./gh-pm approve <issue> [msg]     # Approve from Review
./gh-pm rework <issue> <feedback> # Request changes
./gh-pm ready <issue>             # Unblock task
```

### AI Assistant Helpers
```bash
./gh-pm list                      # Discover all commands
./gh-pm help <command>            # Get detailed help
./gh-pm --dry-run                 # Add to any command for safety
```

---

## 🔍 Dry-Run Mode (Perfect for AI)

**Every command supports `--dry-run`** for safe testing:

```bash
# Test project creation
./gh-pm setup --dry-run

# Test task operations
./gh-pm start 42 --dry-run
./gh-pm complete 42 "Done" --dry-run

# Test batch operations
./gh-pm ready-foundation --dry-run
```

**Dry-run shows exactly what would happen without making any changes.**

---

## 🛠️ Installation Options

### Option 1: Direct Usage (Recommended for AI)
```bash
git clone <repository-url>
cd github-project-ai-manager
./gh-pm help    # Start exploring
```

### Option 2: System-wide Installation
```bash
# Add to PATH for global access
ln -s $(pwd)/gh-pm /usr/local/bin/gh-pm
gh-pm help
```

### Option 3: AI Assistant Integration
```bash
# In your project directory
git clone <repository-url> .github-pm
./.github-pm/gh-pm help
```

---

## 🔧 Configuration

### Auto-Configuration
The tool automatically detects your GitHub context:
- Repository owner and name from `git remote`
- GitHub user ID from `gh api user`
- Project permissions from GitHub CLI

### Manual Configuration
If needed, update these files:
- `project-info.json` - Project-specific settings
- `scripts/lib/dry-run-utils.sh` - Default behaviors

---

## 🤖 AI Assistant Usage Patterns

### Discovery Pattern
```bash
# AI can explore safely
./gh-pm help           # Overview
./gh-pm list           # All commands
./gh-pm help start     # Specific help
```

### Safe Testing Pattern
```bash
# Always test first
./gh-pm <command> --dry-run
# Then execute if looks good
./gh-pm <command>
```

### Context Understanding Pattern
```bash
# Check current state
./gh-pm status
# Understand dependencies
./gh-pm dependencies
# Take appropriate action
./gh-pm start <issue> --dry-run
```

---

## 📊 Features

### ✅ Complete Safety
- **100% dry-run coverage** - Every write operation can be tested
- **Zero accidental changes** - Guaranteed safe exploration
- **Validation preserved** - All checks work in dry-run mode
- **Error simulation** - See realistic error handling

### 🎯 AI-Optimized Interface
- **Self-documenting** - Rich help and examples
- **Predictable patterns** - Consistent argument structures
- **Clear feedback** - Detailed status and progress
- **Error guidance** - Helpful error messages

### 🏗️ Professional Project Management
- **Custom project fields** - Task types, risk levels, effort estimates
- **Dependency management** - Systematic prerequisite tracking
- **Workflow automation** - Status transitions and validation
- **Progress monitoring** - Real-time dashboards

---

## 🎯 Perfect For

### AI Assistants (Primary Use Case)
- **Claude Code** - Complete integration support
- **GitHub Copilot** - CLI completion friendly
- **Other AI tools** - Standard interface patterns

### Development Teams
- **Complex projects** - Multi-phase coordination
- **Dependency management** - Systematic tracking
- **Quality assurance** - Built-in validation
- **Remote teams** - Clear communication

### Project Managers
- **Professional tracking** - Enterprise-level visibility
- **Risk management** - Intelligent prioritization
- **Progress monitoring** - Real-time dashboards
- **Stakeholder communication** - Clear status updates

---

## 🤝 Contributing

This tool is designed for maximum AI assistant compatibility. When contributing:

1. **Maintain dry-run coverage** - Every write operation must support `--dry-run`
2. **Keep help current** - Update help text for all changes
3. **Preserve patterns** - Maintain consistent CLI interface
4. **Test with AI** - Verify AI assistant usability

---

## 📄 License

MIT License - Feel free to use, modify, and distribute.

---

## 🆘 Support

### For AI Assistants
- Use `./gh-pm help` for command discovery
- All commands support `--dry-run` for safe testing
- Rich error messages provide guidance

### For Humans
- Check `./gh-pm help <command>` for detailed usage
- Review examples in this README
- Test everything with `--dry-run` first

---

## 📁 Project Structure

```
_github-pm-project/
├── gh-pm                  # Main CLI executable
├── project-info.json         # Project configuration
├── README.md                 # This file
├── CHANGELOG.md              # Version history
├── CONTRIBUTING.md           # Contribution guidelines
├── LICENSE.md               # License information
├── docs/                    # All documentation
│   ├── getting-started.md   # Setup and usage guide
│   ├── api-reference.md     # Complete API documentation
│   ├── ai-cli-comparison.md # CLI design comparison
│   └── ...                  # Additional guides
├── scripts/                 # Shell scripts for project management
│   ├── setup-complete-github-project.sh
│   ├── start-task.sh
│   ├── complete-task.sh
│   └── ...                  # All management scripts
├── examples/               # Usage examples
└── tests/                 # Test files and fixtures
```

**Ready to revolutionize your AI-assisted project management? Start with `./gh-pm help`!**