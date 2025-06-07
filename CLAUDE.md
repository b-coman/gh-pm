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

The project follows a clean, modular shell script architecture with proper separation of concerns:

### **Directory Structure**
```
scripts/
├── lib/          # Shared utilities (security, error handling, config)
├── workflow/     # Core task operations (start, review, complete, approve)
├── setup/        # Project initialization and configuration
├── admin/        # Monitoring and administrative operations  
├── legacy/       # Deprecated scripts (contained, not for new development)
└── tools/        # Development and debugging utilities
```

### **Core Components**
1. **`gh-pm`** - Unified CLI that delegates to organized scripts
2. **`scripts/lib/`** - Shared utilities for security, error handling, dry-run mode
3. **`data/project-info.json`** - Stores GitHub Project IDs and field configurations
4. **`internal/`** - Internal development documentation and planning

### **Key Design Patterns**
- **Enterprise Security**: Input validation, sanitization, and injection prevention
- **Dry-Run Safety**: Every write operation supports `--dry-run` for safe testing
- **GraphQL-Centric**: All GitHub operations use secure GraphQL API patterns
- **AI-First Design**: Self-documenting interface optimized for AI assistant collaboration
- **Production-Ready**: Comprehensive error handling, retry logic, and testing

### **Script Organization**
- **`workflow/`**: Core task state transitions (start, review, complete, approve, rework)
- **`setup/`**: Project initialization, field configuration, dependency setup
- **`admin/`**: Status queries, dependency checking, monitoring operations
- **`lib/`**: Security utilities, error handling, configuration management
- **`tools/`**: Development helpers, linting, debugging utilities

### **Security & Quality**
- **Input Validation**: All user inputs validated via `scripts/lib/security-utils.sh`
- **Injection Prevention**: GraphQL queries use parameterized patterns with jq
- **Error Handling**: Centralized error management via `scripts/lib/error-utils.sh`
- **Testing**: Comprehensive test suite including security validation

## Documentation Guidelines

### **Documentation Structure**
```
/docs/              # External user-facing documentation (GitHub Pages)
├── index.md        # Main documentation hub
├── getting-started.md
├── api-reference.md
└── [other public docs]

/internal/          # Internal development documentation  
├── docs/           # Development insights and lessons learned
├── planning/       # Future enhancements and strategic planning
├── status/         # Project completion and implementation tracking
└── README.md       # Internal documentation guide
```

### **When to Add Documentation**

#### **External Documentation (`/docs/`)**
- **User Guides**: New features requiring user interaction
- **API Changes**: New commands, options, or behavioral changes  
- **Methodology Updates**: Changes to workflow or collaboration patterns
- **Examples**: New use cases or integration patterns

#### **Internal Documentation (`/internal/`)**
- **Development Insights**: `/internal/docs/` - Lessons learned, technical decisions
- **Planning Materials**: `/internal/planning/` - Future enhancements, architectural plans
- **Status Tracking**: `/internal/status/` - Implementation completion, milestone reports

### **Documentation Quality Standards**
- **User-Focused**: External docs written for end users (developers, AI assistants)
- **Technical Depth**: Internal docs capture implementation details and rationale
- **Cross-References**: Link related concepts between internal and external docs
- **Examples**: Include practical, tested examples in all user documentation
- **Maintenance**: Update docs immediately when implementing changes

## Important Notes

- **Always use `--dry-run`** when testing modifications to scripts
- **Security First**: All scripts use parameterized GraphQL queries via `scripts/lib/security-utils.sh`
- **Follow Patterns**: New scripts must include dry-run support and use shared utilities from `scripts/lib/`
- **JSON Consistency**: Maintain consistent output structure for AI assistant integration
- **Documentation**: Add external docs for user-facing changes, internal docs for development insights
- **Testing**: Run comprehensive tests including security validation before committing changes
- **Architecture**: Place scripts in appropriate directories based on function (workflow/setup/admin/tools)