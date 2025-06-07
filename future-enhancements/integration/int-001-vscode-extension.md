# [Integration] VS Code Extension

## Overview
Create a Visual Studio Code extension that integrates the GitHub Project AI Manager directly into the development environment, providing seamless project management capabilities without leaving the IDE.

## Task Classification
- **Type**: Integration
- **Risk Level**: High
- **Effort**: Large
- **Dependencies**: foundation-003 (test suite), ai-001 (recommendations for IDE integration)

## Acceptance Criteria
- [ ] VS Code extension published to marketplace
- [ ] Project status view in sidebar
- [ ] Task management commands in command palette
- [ ] Inline task suggestions and notifications
- [ ] GitHub authentication integration
- [ ] Real-time project updates
- [ ] Drag-and-drop task management
- [ ] Integration with VS Code's task system
- [ ] Support for multiple projects/workspaces
- [ ] Settings panel for configuration
- [ ] Telemetry and error reporting

## Technical Specification

### Extension Structure
```
vscode-github-pm/
├── package.json              # Extension manifest
├── src/
│   ├── extension.ts          # Main extension entry point
│   ├── providers/
│   │   ├── ProjectProvider.ts    # Project tree view
│   │   ├── TaskProvider.ts       # Task management
│   │   └── StatusProvider.ts     # Status bar integration
│   ├── commands/
│   │   ├── ProjectCommands.ts    # Project operations
│   │   ├── TaskCommands.ts       # Task operations
│   │   └── AICommands.ts         # AI features
│   ├── webview/
│   │   ├── ProjectDashboard.ts   # Rich dashboard view
│   │   └── TaskDetails.ts        # Task detail panel
│   └── utils/
│       ├── GitHubPMClient.ts     # CLI integration
│       ├── AuthManager.ts        # GitHub auth
│       └── ConfigManager.ts      # Settings management
├── media/                    # Icons and assets
├── webview-ui/              # React components for webviews
└── test/                    # Extension tests
```

### Core Features

#### 1. Project Tree View
```typescript
// Sidebar tree view showing project structure
interface ProjectItem {
  id: string;
  title: string;
  status: 'todo' | 'ready' | 'in_progress' | 'review' | 'done';
  type: 'foundation' | 'enhancement' | 'migration' | 'qa' | 'documentation';
  effort: 'small' | 'medium' | 'large';
  dependencies: string[];
  assignee?: string;
}

class ProjectProvider implements vscode.TreeDataProvider<ProjectItem> {
  // Implementation for project tree view
}
```

#### 2. Command Palette Integration
```typescript
// Commands available in VS Code command palette
const commands = [
  'githubPM.refreshProject',      // Refresh project data
  'githubPM.startTask',           // Start working on task
  'githubPM.completeTask',        // Complete current task
  'githubPM.getRecommendations',  // Get AI recommendations
  'githubPM.showDashboard',       // Open project dashboard
  'githubPM.createTask',          // Create new task
  'githubPM.setupProject',        // Initial project setup
];
```

#### 3. Status Bar Integration
```typescript
// Show current task and project status in status bar
class StatusBarManager {
  private statusBarItem: vscode.StatusBarItem;
  
  updateCurrentTask(task: ProjectItem) {
    this.statusBarItem.text = `$(github) ${task.title}`;
    this.statusBarItem.tooltip = `In Progress: ${task.title}`;
    this.statusBarItem.command = 'githubPM.showTaskDetails';
  }
}
```

#### 4. Rich Dashboard Webview
```typescript
// React-based dashboard for comprehensive project view
interface DashboardProps {
  project: ProjectData;
  tasks: ProjectItem[];
  recommendations: Recommendation[];
}

const ProjectDashboard: React.FC<DashboardProps> = ({ project, tasks, recommendations }) => {
  return (
    <div className="dashboard">
      <ProjectOverview project={project} />
      <TaskBoard tasks={tasks} />
      <RecommendationsPanel recommendations={recommendations} />
    </div>
  );
};
```

### GitHub PM CLI Integration
```typescript
class GitHubPMClient {
  private cliPath: string;

  async executeCommand(command: string, args: string[]): Promise<any> {
    const result = await exec(`${this.cliPath} ${command} ${args.join(' ')} --format=json`);
    return JSON.parse(result.stdout);
  }

  async getProjectStatus(): Promise<ProjectData> {
    return this.executeCommand('status', []);
  }

  async startTask(taskId: string): Promise<void> {
    await this.executeCommand('start', [taskId]);
  }

  async getRecommendations(): Promise<Recommendation[]> {
    const result = await this.executeCommand('recommend', []);
    return result.recommendations;
  }
}
```

### Configuration and Settings
```json
{
  "contributes": {
    "configuration": {
      "title": "GitHub Project AI Manager",
      "properties": {
        "githubPM.cliPath": {
          "type": "string",
          "default": "github-pm",
          "description": "Path to GitHub PM CLI executable"
        },
        "githubPM.autoRefresh": {
          "type": "boolean",
          "default": true,
          "description": "Automatically refresh project data"
        },
        "githubPM.refreshInterval": {
          "type": "number",
          "default": 300,
          "description": "Auto-refresh interval in seconds"
        },
        "githubPM.showNotifications": {
          "type": "boolean",
          "default": true,
          "description": "Show task completion notifications"
        }
      }
    }
  }
}
```

### User Experience Features

#### 1. Intelligent Notifications
```typescript
class NotificationManager {
  showTaskReady(task: ProjectItem) {
    vscode.window.showInformationMessage(
      `Task ready: ${task.title}`,
      'Start Task',
      'View Details'
    ).then(selection => {
      if (selection === 'Start Task') {
        vscode.commands.executeCommand('githubPM.startTask', task.id);
      }
    });
  }

  showRecommendation(recommendation: Recommendation) {
    vscode.window.showInformationMessage(
      `AI Suggestion: ${recommendation.action}`,
      'Apply',
      'Dismiss'
    );
  }
}
```

#### 2. Contextual Task Suggestions
```typescript
// Show relevant tasks based on current file/context
class ContextManager {
  async suggestRelevantTasks(activeFile: string): Promise<ProjectItem[]> {
    // Analyze current file and suggest related tasks
    const fileContext = this.analyzeFile(activeFile);
    const allTasks = await this.githubPMClient.getTasks();
    
    return allTasks.filter(task => 
      this.isTaskRelevant(task, fileContext)
    );
  }
}
```

#### 3. Task Timer Integration
```typescript
class TaskTimer {
  private startTime: Date;
  private currentTask: ProjectItem;

  startTimer(task: ProjectItem) {
    this.startTime = new Date();
    this.currentTask = task;
    this.updateStatusBar();
  }

  private updateStatusBar() {
    const elapsed = Date.now() - this.startTime.getTime();
    const formatted = this.formatDuration(elapsed);
    this.statusBarItem.text = `$(clock) ${formatted} - ${this.currentTask.title}`;
  }
}
```

## Testing Strategy

### Extension Testing
- Unit tests for core functionality
- Integration tests with VS Code API
- E2E tests with GitHub PM CLI
- User acceptance testing

### Cross-Platform Testing
- Windows, macOS, Linux
- Different VS Code versions
- Various GitHub PM CLI versions
- Different project configurations

### Performance Testing
- Large project handling
- Memory usage optimization
- Extension activation time
- Real-time update performance

## Distribution and Publishing

### VS Code Marketplace
```json
{
  "name": "github-project-ai-manager",
  "displayName": "GitHub Project AI Manager",
  "description": "AI-powered GitHub project management in VS Code",
  "version": "1.0.0",
  "publisher": "username",
  "repository": "https://github.com/username/vscode-github-pm",
  "categories": ["Other", "Project Management"],
  "keywords": ["github", "project", "management", "ai", "productivity"]
}
```

### CI/CD Pipeline
```yaml
# .github/workflows/extension.yml
name: Build and Publish Extension

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm test
        
      - name: Package extension
        run: npx vsce package
        
      - name: Publish to marketplace
        if: startsWith(github.ref, 'refs/tags/')
        run: npx vsce publish -p ${{ secrets.VSCE_TOKEN }}
```

## Documentation Impact
- Add VS Code extension section to main docs
- Create extension-specific documentation
- Add setup and configuration guides
- Document integration workflows

## Implementation Phases

### Phase 1: Core Integration (6-8 weeks)
- Basic tree view and commands
- CLI integration
- Project status display

### Phase 2: Rich Features (4-6 weeks)
- Dashboard webview
- Real-time updates
- Task timer and notifications

### Phase 3: AI Integration (4-6 weeks)
- Contextual suggestions
- AI-powered recommendations
- Intelligent notifications

## Success Metrics
- Extension downloads and adoption
- User engagement with features
- Developer productivity improvements
- Integration with AI assistant workflows