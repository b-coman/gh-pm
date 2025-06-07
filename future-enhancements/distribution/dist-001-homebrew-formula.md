# [Distribution] Homebrew Formula

## Overview
Create a Homebrew formula to enable easy installation of the GitHub Project AI Manager on macOS and Linux systems. This will make the tool accessible through the standard package manager used by most developers.

## Task Classification
- **Type**: Enhancement
- **Risk Level**: Medium
- **Effort**: Medium
- **Dependencies**: foundation-002 (installation script), dev-002 (quality tools for release process)

## Acceptance Criteria
- [ ] Homebrew formula created and tested
- [ ] Installation via `brew install github-pm` works
- [ ] Formula includes all necessary dependencies
- [ ] Automatic dependency installation (GitHub CLI, jq)
- [ ] Version management and updates supported
- [ ] Formula submitted to homebrew-core or custom tap
- [ ] Installation instructions updated
- [ ] Uninstall process works correctly
- [ ] Cross-platform testing (macOS Intel/ARM, Linux)
- [ ] CI integration for formula validation
- [ ] Documentation for maintainers

## Technical Specification

### Homebrew Formula Structure
```ruby
# Formula/github-pm.rb
class GithubPm < Formula
  desc "AI-friendly GitHub Project Management CLI"
  homepage "https://github.com/username/github-pm"
  url "https://github.com/username/github-pm/archive/v1.0.0.tar.gz"
  sha256 "abcd1234..."
  license "MIT"

  depends_on "gh"
  depends_on "jq"

  def install
    bin.install "github-pm"
    (bin/"github-pm").chmod 0755
    
    # Install supporting files
    libexec.install Dir["scripts/*"]
    (etc/"github-pm").install "project-info.json.example"
    
    # Create wrapper script that sets up paths
    (bin/"github-pm").write <<~EOS
      #!/bin/bash
      export GITHUB_PM_LIBEXEC="#{libexec}"
      exec "#{libexec}/github-pm" "$@"
    EOS
  end

  test do
    system "#{bin}/github-pm", "--version"
    system "#{bin}/github-pm", "doctor", "--dry-run"
  end
end
```

### Installation Process
```bash
# Add tap (if using custom tap)
brew tap username/github-pm

# Install the tool
brew install github-pm

# Verify installation
github-pm doctor

# Update to latest version
brew upgrade github-pm

# Uninstall
brew uninstall github-pm
```

### Release Process Integration
```bash
# scripts/dev/prepare-homebrew-release.sh
#!/bin/bash

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

# Update formula with new version and SHA
sed -i '' "s/v[0-9.]*/v$VERSION/g" Formula/github-pm.rb

# Calculate SHA256 of release archive
SHA256=$(curl -sL "https://github.com/username/github-pm/archive/v$VERSION.tar.gz" | shasum -a 256 | cut -d' ' -f1)
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/g" Formula/github-pm.rb

echo "✅ Formula updated for version $VERSION"
echo "📦 SHA256: $SHA256"
echo "🍺 Submit to Homebrew with: brew audit --new-formula Formula/github-pm.rb"
```

### Custom Tap Structure (if needed)
```
homebrew-github-pm/
├── Formula/
│   └── github-pm.rb
├── README.md
├── .github/
│   └── workflows/
│       └── test-formula.yml
└── LICENSE
```

### CI Integration for Formula Testing
```yaml
# .github/workflows/homebrew.yml
name: Test Homebrew Formula
on:
  push:
    tags: ['v*']
    
jobs:
  test-formula:
    strategy:
      matrix:
        os: [macos-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Homebrew
        uses: Homebrew/actions/setup-homebrew@master
        
      - name: Test formula
        run: |
          brew install --build-from-source Formula/github-pm.rb
          github-pm --version
          github-pm doctor --dry-run
```

## Testing Strategy

### Formula Validation
- Test installation on clean systems
- Verify all dependencies are installed
- Test formula audit process
- Validate installation paths and permissions

### Platform Testing
- macOS Intel and ARM (M1/M2)
- Linux (Ubuntu, CentOS)
- Different Homebrew versions
- Clean and existing Homebrew environments

### Integration Testing
- Test with existing GitHub CLI installations
- Verify PATH and environment setup
- Test update and uninstall processes
- Validate formula metadata

## Documentation Impact
- Add Homebrew installation to README.md
- Update getting-started.md with brew install instructions
- Create Homebrew troubleshooting section
- Document formula maintenance process

## Submission Strategy

### Option 1: Homebrew Core (Recommended for popular tools)
- Submit to main Homebrew repository
- Requires meeting Homebrew standards
- Broader distribution and trust
- Automatic updates and maintenance

### Option 2: Custom Tap (Easier for new projects)
- Create custom tap repository
- Full control over formula
- Easier to iterate and update
- Good stepping stone to core

## Implementation Notes
- Start with custom tap for initial releases
- Ensure formula follows Homebrew conventions
- Test thoroughly before submission
- Provide clear installation documentation
- Plan for version management and updates