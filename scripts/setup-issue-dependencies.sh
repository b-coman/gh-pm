#!/bin/bash
# Set up issue dependencies using GitHub's native blocking relationships

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared dry-run utilities
source "$SCRIPT_DIR/lib/dry-run-utils.sh"

# Initialize dry-run mode
init_dry_run "$@"

print_dry_run_header "Setting up Issue Dependencies"

# Repository info
OWNER="b-coman"
REPO="prop-management"

echo ""
echo "📋 Creating dependency relationships..."

# Enhancement tasks depend on ALL foundation tasks
echo "   Setting up Enhancement dependencies..."

echo "     #42 (PropertyPageRenderer homepage) depends on foundation tasks..."
gh_issue_safe edit 42 --repo $OWNER/$REPO --add-label "blocked"

echo "     #43 (Add legacy components) depends on #40..."
gh_issue_safe edit 43 --repo $OWNER/$REPO --add-label "blocked"

echo "     #44 (Data compatibility layer) depends on #39..."  
gh_issue_safe edit 44 --repo $OWNER/$REPO --add-label "blocked"

# Migration tasks depend on enhancement tasks
echo "   Setting up Migration dependencies..."

echo "     #45 (Replace homepage renderer) depends on enhancements..."
gh_issue_safe edit 45 --repo $OWNER/$REPO --add-label "blocked"

echo "     #46 (Archive legacy system) depends on #45..."
gh_issue_safe edit 46 --repo $OWNER/$REPO --add-label "blocked"

# QA tasks depend on enhancements
echo "   Setting up QA dependencies..."

echo "     #47 (Renderer parity tests) depends on #42..."
gh_issue_safe edit 47 --repo $OWNER/$REPO --add-label "blocked"

echo "     #48 (Performance testing) depends on #42..."
gh_issue_safe edit 48 --repo $OWNER/$REPO --add-label "blocked"

# Documentation tasks are final
echo "   Setting up Documentation dependencies..."

echo "     #49 (Update documentation) depends on #46..."
gh_issue_safe edit 49 --repo $OWNER/$REPO --add-label "blocked"

echo "     #50 (Code standards compliance) depends on #49..."
gh_issue_safe edit 50 --repo $OWNER/$REPO --add-label "blocked"

echo ""
echo "✅ Issue dependencies configured"

# Update issue descriptions with clear dependency information
echo ""
echo "📝 Updating issue descriptions with dependency information..."

# Enhancement tasks
ISSUE_42_BODY="
## Objective
Extend PropertyPageRenderer to support homepage rendering, enabling consolidation of dual renderer systems.

## Dependencies  
🔒 **Blocked by**: #39, #40, #41 (All foundation tasks must be complete)

## Acceptance Criteria
- [ ] PropertyPageRenderer supports homepage layout rendering
- [ ] All homepage-specific components are available
- [ ] Data transformation layer works correctly
- [ ] Visual parity with existing homepage maintained
- [ ] Performance benchmarks met or exceeded

## Implementation Notes
- Based on analysis from foundation tasks
- Uses data transformation utilities from #39
- Leverages component gap analysis from #40
- Integrates with booking form patterns from #41
"

gh_issue_safe edit 42 --repo $OWNER/$REPO --body "$ISSUE_42_BODY"

ISSUE_43_BODY="
## Objective
Add missing legacy components to modern renderer mapping based on gap analysis.

## Dependencies
🔒 **Blocked by**: #40 (Component gap analysis)

## Acceptance Criteria  
- [ ] All missing components identified and implemented
- [ ] Component mapping 100% complete
- [ ] Legacy component parity achieved
- [ ] Integration tests passing
- [ ] Documentation updated

## Implementation Notes
- Based on gap analysis from #40
- Focus on components unique to legacy system
- Maintain API compatibility where possible
"

gh_issue_safe edit 43 --repo $OWNER/$REPO --body "$ISSUE_43_BODY"

ISSUE_44_BODY="
## Objective
Implement data structure compatibility layer for seamless migration between renderers.

## Dependencies
🔒 **Blocked by**: #39 (Data transformation utilities)

## Acceptance Criteria
- [ ] Data transformation layer implemented
- [ ] Legacy data formats supported
- [ ] Modern data formats supported  
- [ ] Automatic conversion between formats
- [ ] Performance impact minimal (<5%)
- [ ] Comprehensive test coverage

## Implementation Notes
- Uses transformation utilities from #39
- Handles both directions: legacy ↔ modern
- Focuses on property data and override structures
"

gh_issue_safe edit 44 --repo $OWNER/$REPO --body "$ISSUE_44_BODY"

# Migration tasks
ISSUE_45_BODY="
## Objective
Replace homepage PropertyPageLayout with PropertyPageRenderer system.

## Dependencies
🔒 **Blocked by**: #42, #43, #44 (All enhancement tasks must be complete)

## Acceptance Criteria
- [ ] Homepage fully migrated to PropertyPageRenderer
- [ ] All functionality preserved
- [ ] Visual parity maintained
- [ ] Performance equal or better
- [ ] No user-facing changes
- [ ] SEO and analytics preserved

## Implementation Notes
- This is the actual migration execution
- Requires all enhancement capabilities ready
- High-risk change requiring careful rollback planning
"

gh_issue_safe edit 45 --repo $OWNER/$REPO --body "$ISSUE_45_BODY"

echo ""

if is_dry_run; then
    print_dry_run_summary "Setup Issue Dependencies" "Issues #42-#50" "Add blocked labels and update issue descriptions with dependency information"
    echo ""
fi

if is_dry_run; then
    echo "🎉 Dependencies and documentation setup would be complete!"
else
    echo "🎉 Dependencies and documentation setup complete!"
fi
echo ""
echo "📊 Dependency Structure:"
echo "   Foundation (Ready): #39, #40, #41"
echo "   └── Enhancement (Blocked): #42←(39,40,41), #43←(40), #44←(39)"
echo "       └── Migration (Blocked): #45←(42,43,44), #46←(45)"
echo "           └── QA (Blocked): #47←(42), #48←(42)"
echo "               └── Documentation (Blocked): #49←(46), #50←(49)"
echo ""
echo "🔗 Visit project to see visual dependency flow: $(jq -r '.project_url' project-info.json)"