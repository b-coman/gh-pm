# [Integration] GitHub Actions Integration

## Overview
Create comprehensive GitHub Actions workflows that integrate the GitHub Project AI Manager into CI/CD pipelines, enabling automated project management, status updates, and intelligent task orchestration as part of the development workflow.

## Task Classification
- **Type**: Integration
- **Risk Level**: Medium
- **Effort**: Medium
- **Dependencies**: dist-002 (Docker image for containerized actions), foundation-003 (test suite for validation)

## Acceptance Criteria
- [ ] Pre-built GitHub Actions for common project management tasks
- [ ] Workflow templates for different project types
- [ ] Automated project status updates on PR events
- [ ] Task completion automation on merge events
- [ ] Intelligent task assignment based on code changes
- [ ] Project health monitoring and reporting
- [ ] Integration with existing GitHub features (issues, PRs, releases)
- [ ] Custom action for AI-powered recommendations
- [ ] Comprehensive documentation and examples
- [ ] Support for both public and private repositories

## Technical Specification

### Core GitHub Actions

#### 1. Project Status Action
```yaml
# .github/actions/project-status/action.yml
name: 'GitHub PM Status'
description: 'Get project status and update GitHub context'
inputs:
  github-token:
    description: 'GitHub token for API access'
    required: true
  project-url:
    description: 'GitHub project URL'
    required: true
  format:
    description: 'Output format (json, markdown, summary)'
    default: 'summary'
    
outputs:
  status:
    description: 'Project status information'
  recommendations:
    description: 'AI recommendations'
  health-score:
    description: 'Project health score'

runs:
  using: 'docker'
  image: 'docker://username/github-pm:latest'
  args:
    - 'status'
    - '--format=${{ inputs.format }}'
  env:
    GITHUB_TOKEN: ${{ inputs.github-token }}
    PROJECT_URL: ${{ inputs.project-url }}
```

#### 2. Task Management Action
```yaml
# .github/actions/task-management/action.yml
name: 'GitHub PM Task Management'
description: 'Manage tasks based on GitHub events'
inputs:
  action:
    description: 'Action to perform (complete, start, create, assign)'
    required: true
  task-id:
    description: 'Task ID or issue number'
    required: false
  assignee:
    description: 'Task assignee'
    required: false

runs:
  using: 'composite'
  steps:
    - name: Execute task action
      shell: bash
      run: |
        docker run --rm \
          -e GITHUB_TOKEN="${{ env.GITHUB_TOKEN }}" \
          -v ${{ github.workspace }}:/workspace \
          username/github-pm:latest \
          ${{ inputs.action }} ${{ inputs.task-id }} \
          --assignee="${{ inputs.assignee }}" \
          --format=json
```

### Workflow Templates

#### 1. Project Setup Workflow
```yaml
# .github/workflows/project-setup.yml
name: Project Setup

on:
  workflow_dispatch:
    inputs:
      project_type:
        description: 'Project type'
        required: true
        type: choice
        options:
          - 'foundation'
          - 'feature-development'
          - 'integration'
          - 'maintenance'

jobs:
  setup-project:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup GitHub PM Project
        uses: ./.github/actions/project-setup
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          project-type: ${{ github.event.inputs.project_type }}
          
      - name: Create Project Summary
        run: |
          echo "## Project Setup Complete" >> $GITHUB_STEP_SUMMARY
          echo "Project type: ${{ github.event.inputs.project_type }}" >> $GITHUB_STEP_SUMMARY
          echo "Next steps will be automatically recommended." >> $GITHUB_STEP_SUMMARY
```

#### 2. PR Integration Workflow
```yaml
# .github/workflows/pr-integration.yml
name: PR Project Integration

on:
  pull_request:
    types: [opened, closed, synchronize]

jobs:
  update-project:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Analyze PR Impact
        id: analyze
        uses: ./.github/actions/project-status
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          project-url: ${{ vars.PROJECT_URL }}
          
      - name: Update Task Status on Merge
        if: github.event.pull_request.merged == true
        uses: ./.github/actions/task-management
        with:
          action: 'complete'
          task-id: ${{ github.event.pull_request.number }}
          
      - name: Create Follow-up Tasks
        if: github.event.pull_request.merged == true
        run: |
          docker run --rm \
            -e GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}" \
            -v ${{ github.workspace }}:/workspace \
            username/github-pm:latest \
            recommend --context=post-merge --format=json \
            --pr-number=${{ github.event.pull_request.number }}
```

#### 3. Daily Project Health Check
```yaml
# .github/workflows/daily-health-check.yml
name: Daily Project Health Check

on:
  schedule:
    - cron: '0 9 * * 1-5'  # 9 AM on weekdays
  workflow_dispatch:

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Project Health Analysis
        id: health
        uses: ./.github/actions/project-status
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          project-url: ${{ vars.PROJECT_URL }}
          format: 'json'
          
      - name: Generate Health Report
        run: |
          echo "## Daily Project Health Report" >> report.md
          echo "Date: $(date)" >> report.md
          echo "" >> report.md
          
          # Parse health data and create markdown report
          echo '${{ steps.health.outputs.status }}' | jq -r '
            "**Health Score:** " + (.health_score | tostring) + "/100",
            "",
            "**Key Metrics:**",
            "- Tasks completed this week: " + (.metrics.completed_tasks | tostring),
            "- Blocked tasks: " + (.metrics.blocked_tasks | tostring),
            "- On-track milestones: " + (.metrics.on_track_milestones | tostring),
            "",
            "**Recommendations:**"
          ' >> report.md
          
          echo '${{ steps.health.outputs.recommendations }}' | jq -r '.[] | "- " + .action' >> report.md
          
      - name: Create or Update Issue
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('report.md', 'utf8');
            
            // Create or update daily health check issue
            const { data: issues } = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: ['project-health', 'automated'],
              state: 'open'
            });
            
            if (issues.length > 0) {
              await github.rest.issues.update({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issues[0].number,
                body: report
              });
            } else {
              await github.rest.issues.create({
                owner: context.repo.owner,
                repo: context.repo.repo,
                title: 'Daily Project Health Report',
                body: report,
                labels: ['project-health', 'automated']
              });
            }
```

### Advanced Integration Features

#### 1. Intelligent Task Assignment
```yaml
# .github/workflows/smart-assignment.yml
name: Smart Task Assignment

on:
  issues:
    types: [labeled]

jobs:
  assign-task:
    if: contains(github.event.label.name, 'ready')
    runs-on: ubuntu-latest
    steps:
      - name: AI-Powered Assignment
        run: |
          docker run --rm \
            -e GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}" \
            username/github-pm:latest \
            recommend assignment \
            --issue=${{ github.event.issue.number }} \
            --consider-workload \
            --consider-expertise \
            --format=json
```

#### 2. Release Automation
```yaml
# .github/workflows/release-automation.yml
name: Release Automation

on:
  release:
    types: [published]

jobs:
  update-project:
    runs-on: ubuntu-latest
    steps:
      - name: Mark Release Tasks Complete
        run: |
          docker run --rm \
            -e GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}" \
            username/github-pm:latest \
            batch complete \
            --milestone="${{ github.event.release.tag_name }}" \
            --dry-run=false
            
      - name: Create Post-Release Tasks
        run: |
          docker run --rm \
            -e GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}" \
            username/github-pm:latest \
            recommend post-release \
            --version="${{ github.event.release.tag_name }}" \
            --auto-create
```

## Testing Strategy
- Test actions with various GitHub event types
- Validate integration with different project configurations
- Test error handling and failure scenarios
- Performance testing with large repositories
- Security testing for token handling

## Documentation Impact
- Add GitHub Actions section to main documentation
- Create workflow template library
- Document setup and configuration procedures
- Add troubleshooting guide for common issues

## Implementation Notes
- Use official GitHub Actions best practices
- Implement proper error handling and logging
- Support both Docker and composite actions
- Provide clear examples for different use cases
- Ensure backward compatibility with existing workflows