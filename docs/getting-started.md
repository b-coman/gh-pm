# Getting Started with GitHub Project AI Manager
## Step-by-Step Setup and Usage Guide

This guide will help you set up and start using the GitHub Project AI Manager for your software development projects.

---

## 🎯 Prerequisites

### Required Tools
```bash
# 1. GitHub CLI (required for API access)
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Windows
winget install GitHub.cli
```

### Required Permissions
```bash
# 2. Authenticate with GitHub and project permissions
gh auth login

# 3. Add project management scopes
gh auth refresh -s project,read:project --hostname github.com
```

### Verify Setup
```bash
# 4. Test GitHub CLI access
gh auth status

# 5. Test GraphQL API access
gh api graphql -f query='query { viewer { login } }'
```

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Clone and Prepare
```bash
# Clone your repository (or use existing)
git clone [your-repository-url]
cd [your-repository]

# Copy GitHub Project AI Manager
cp -r /path/to/github-project-ai-manager .
cd github-project-ai-manager
```

### Step 2: Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### Step 3: Run Complete Setup
```bash
# This creates everything: project, issues, dependencies, fields
./scripts/setup-complete-github-project.sh
```

### Step 4: Verify Installation
```bash
# Check project status
./scripts/query-project-status.sh
```

**🎉 You're ready! The system will show you your project dashboard with ready tasks.**

---

## 📋 Understanding Your Project Structure

### What Was Created
After running the setup script, you'll have:

#### GitHub Project
- **Custom Fields**: Task Type, Risk Level, Effort, Dependencies
- **12 Issues**: Professionally structured with acceptance criteria
- **Dependency Mapping**: Clear prerequisite relationships
- **Milestone Integration**: Timeline tracking

#### Project Board Columns
```
Backlog → Ready → In Progress → Review → Done
```

#### Task Categories
- **Foundation Tasks** (#39, #40, #41): Ready to start immediately
- **Enhancement Tasks** (#42, #43, #44): Blocked until foundation complete
- **Migration Tasks** (#45, #46): Blocked until enhancements ready
- **QA Tasks** (#47, #48): Coordinated with enhancements
- **Documentation Tasks** (#49, #50): Final completion phase

---

## 🔄 Daily Workflow

### Morning Routine
```bash
# 1. Check project status
./scripts/query-project-status.sh

# Expected output:
# 🎯 Project Status Dashboard
# ├── Ready: 3 tasks (#39, #40, #41)
# ├── In Progress: 0 tasks
# ├── Blocked: 9 tasks
# └── AI Recommendation: Start with #39 (highest impact)
```

### Starting a Task
```bash
# 2. Check what's ready to work on
./scripts/check-dependencies.sh

# 3. Start the highest priority task
./scripts/start-task.sh 39

# What happens:
# ✅ Validates task is ready
# ✅ Confirms no other tasks in progress
# ✅ Moves task to "In Progress"
# ✅ Logs start time and details
```

### Working on Tasks
```bash
# The AI assistant will help you:
# - Implement the required functionality
# - Run tests and validation
# - Update documentation
# - Verify acceptance criteria
```

### Completing a Task
```bash
# 4. Complete the task when finished
./scripts/complete-task.sh 39

# What happens:
# ✅ Validates acceptance criteria met
# ✅ Runs quality checks
# ✅ Moves task to "Done"
# ✅ Analyzes dependent tasks
# ✅ Auto-unblocks ready tasks
```

### Check Progress
```bash
# 5. See updated project status
./scripts/query-project-status.sh

# You'll see:
# - Task #39 moved to "Done"
# - Dependent tasks potentially unblocked
# - New recommendations for next work
```

---

## 🎯 Understanding Dependencies

### How Dependencies Work
Each task has explicit dependencies listed in the Dependencies field:
- **Format**: "#39, #40, #41" (prerequisite issue numbers)
- **Enforcement**: AI prevents starting tasks until all dependencies are "Done"
- **Automation**: Completing tasks triggers readiness analysis for dependent tasks

### Example Dependency Chain
```
Foundation Phase:
├── #39: Component Analysis (no dependencies) → Ready immediately
├── #40: Shared Components (no dependencies) → Ready immediately
└── #41: Core Architecture (no dependencies) → Ready immediately

Enhancement Phase (blocked until all foundation complete):
├── #42: Property Pages (depends on #39, #40, #41)
├── #43: Theme Integration (depends on #39, #40, #41)
└── #44: Booking Forms (depends on #39, #40, #41)

Migration Phase (blocked until all enhancements complete):
├── #45: System Migration (depends on #42, #43, #44)
└── #46: Legacy Cleanup (depends on #45)
```

### Checking Dependencies
```bash
# See what's blocking specific tasks
./scripts/check-dependencies.sh

# Sample output:
# 📋 Dependency Analysis:
# 
# ✅ Ready to Start:
# ├── #39: Component Analysis (Foundation)
# ├── #40: Shared Components (Foundation)
# └── #41: Core Architecture (Foundation)
#
# 🔒 Blocked Tasks:
# ├── #42: Property Pages → waiting for #39, #40, #41
# ├── #43: Theme Integration → waiting for #39, #40, #41
# └── #44: Booking Forms → waiting for #39, #40, #41
```

---

## 🛠️ Advanced Usage

### Manual Task Management
```bash
# Force a task to "Ready" (override dependencies)
./scripts/move-to-ready.sh 42

# Use this for:
# - Special circumstances
# - Testing workflows
# - Emergency situations
```

### Project Status Monitoring
```bash
# Detailed project dashboard
./scripts/query-project-status.sh

# Shows:
# - Current task states
# - Dependency blocking relationships
# - Critical path analysis
# - AI recommendations
# - Progress metrics
```

### Foundation Task Initialization
```bash
# Move all foundation tasks to Ready (first-time setup)
./scripts/move-foundation-tasks-ready.sh

# Use this to:
# - Initialize new projects
# - Reset project state
# - Begin development cycle
```

---

## 🎨 Customization

### Adapting for Your Project

#### 1. Modify Issue Structure
Edit the setup script to create issues specific to your project:
```bash
# Edit: scripts/setup-github-project.sh
# Customize:
# - Issue titles and descriptions
# - Acceptance criteria
# - Risk levels and effort estimates
# - Dependency relationships
```

#### 2. Adjust Custom Fields
Modify project fields for your workflow:
```bash
# Edit: scripts/setup-github-project.sh
# Customize:
# - Task types (Foundation/Enhancement/Migration...)
# - Risk levels (Critical/High/Medium/Low)
# - Effort estimates (Small/Medium/Large)
# - Additional custom fields
```

#### 3. Configure Dependencies
Map dependencies for your specific project structure:
```bash
# Edit: scripts/configure-project-fields.sh
# Customize:
# - Prerequisite relationships
# - Task sequencing
# - Critical path definition
# - Milestone integration
```

### Example Customizations

#### Different Project Types
```bash
# Web Application Migration
Task Types: Analysis, Backend, Frontend, Integration, Testing, Deployment

# Data Pipeline Project  
Task Types: Schema, ETL, Validation, Monitoring, Documentation

# Infrastructure Migration
Task Types: Planning, Setup, Migration, Validation, Cleanup
```

#### Different Risk Models
```bash
# Business Impact Model
Risk Levels: Revenue-Critical, User-Facing, Internal, Nice-to-Have

# Technical Complexity Model
Risk Levels: Architectural, Integration, Performance, Maintenance
```

---

## 🔧 Troubleshooting

### Common Issues

#### Authentication Problems
```bash
# Problem: "Your token has not been granted the required scopes"
# Solution: Re-authenticate with project permissions
gh auth refresh -s project,read:project --hostname github.com
```

#### Script Permissions
```bash
# Problem: "Permission denied" when running scripts
# Solution: Make scripts executable
chmod +x scripts/*.sh
```

#### Project Not Found
```bash
# Problem: Scripts can't find project
# Solution: Verify project was created successfully
gh api graphql -f query='query { viewer { projectsV2(first: 10) { nodes { title } } } }'
```

#### Missing Dependencies
```bash
# Problem: jq command not found
# Solution: Install jq for JSON processing
brew install jq  # macOS
sudo apt install jq  # Ubuntu
```

### Getting Help

#### Debug Mode
```bash
# Run scripts with debug output
bash -x ./scripts/query-project-status.sh
```

#### Verify Project State
```bash
# Check if project exists and is accessible
./scripts/query-project-status.sh

# If this fails, project setup needs to be repeated
./scripts/setup-complete-github-project.sh
```

#### Reset Project
```bash
# If project gets into invalid state:
# 1. Delete project manually in GitHub web interface
# 2. Re-run setup script
./scripts/setup-complete-github-project.sh
```

---

## 📚 Next Steps

### Learn More
- **[Full Methodology](./ai-assisted-project-management-with-github-projects.md)**: Complete technical details
- **[Script Reference](../scripts/project-management-commands.md)**: All available commands
- **[API Reference](./API_REFERENCE.md)**: GraphQL operations and endpoints

### Advanced Topics
- **Multi-project management**: Coordinating multiple projects
- **Custom workflows**: Adapting for different project types
- **Integration**: Connecting with CI/CD and other tools
- **Reporting**: Creating custom dashboards and metrics

### Contributing
- **Report issues**: Found a bug or have a suggestion?
- **Submit improvements**: Better scripts or documentation
- **Share examples**: How you've adapted the system
- **Join discussions**: Help others and learn from the community

---

**🎉 Congratulations! You're now ready to experience revolutionary AI-assisted project management.**

**Next**: Try completing your first task and watch how the AI automatically unblocks dependent work!

---

*Need help? Check the [troubleshooting section](#-troubleshooting) or create an issue in the repository.*