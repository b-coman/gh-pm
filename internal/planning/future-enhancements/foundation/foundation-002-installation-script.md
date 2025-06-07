# [Foundation] One-Line Installation Script

## Overview
Create a simple, reliable installation script that users can run with a single command to set up the GitHub Project AI Manager on their system. This reduces friction for new users and enables easy CI/CD integration.

## Task Classification
- **Type**: Foundation
- **Risk Level**: Medium
- **Effort**: Small
- **Dependencies**: foundation-001 (health check for validation)

## Acceptance Criteria
- [ ] `install.sh` script created in project root
- [ ] One-line installation: `curl -sSL url | bash`
- [ ] Detects and installs system dependencies (GitHub CLI, jq)
- [ ] Downloads latest release or clones repository
- [ ] Sets up executable permissions correctly
- [ ] Optionally adds to system PATH
- [ ] Validates installation with health check
- [ ] Supports different installation modes (user vs system-wide)
- [ ] Provides clear success/failure feedback
- [ ] Includes uninstall option
- [ ] Works on macOS, Linux, and Windows (via Git Bash)

## Technical Specification

### Installation Methods
```bash
# Method 1: Direct from GitHub (future)
curl -sSL https://raw.githubusercontent.com/user/repo/main/install.sh | bash

# Method 2: Local installation
./install.sh [--user|--system] [--path=/custom/path]

# Method 3: Development installation
./install.sh --dev  # Links to current directory
```

### Installation Steps
1. **System Detection**
   - OS identification (macOS, Linux, Windows)
   - Shell environment detection
   - Permission level assessment

2. **Dependency Installation**
   - Check for GitHub CLI, install if missing
   - Check for jq, install if missing
   - Verify installation success

3. **Project Installation**
   - Download/clone project files
   - Set executable permissions on github-pm
   - Create symlink or PATH entry
   - Validate installation with doctor command

4. **Configuration**
   - Guide user through GitHub authentication
   - Optionally run initial project setup
   - Provide getting started instructions

### Output
```bash
🚀 Installing GitHub Project AI Manager...
✅ System detected: macOS (arm64)
✅ GitHub CLI found: v2.74.0
✅ Installing jq...
✅ Downloading latest release...
✅ Setting up executable permissions...
✅ Adding to PATH...
✅ Running health check...

🎉 Installation complete!

Next steps:
1. Authenticate with GitHub: gh auth refresh -s project,read:project
2. Set up your first project: github-pm setup-complete
3. Get help anytime: github-pm help

Installation path: /usr/local/bin/github-pm
```

## Testing Strategy
- Test on clean systems (Docker containers)
- Test with various permission levels
- Test with existing/missing dependencies
- Test PATH integration and shell reloading
- Test uninstall process
- Automated installation testing in CI

## Documentation Impact
- Update README.md with installation instructions
- Add installation section to getting-started.md
- Create installation troubleshooting guide
- Document system requirements

## Security Considerations
- Validate download checksums
- Use HTTPS for all downloads
- Minimal required permissions
- Clear indication of system modifications
- Safe uninstall process