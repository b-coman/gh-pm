# [Integration] Webhook Endpoints

## Overview
Implement webhook endpoints that allow external systems to integrate with the GitHub Project AI Manager, enabling real-time project updates, automated responses to external events, and bidirectional communication with third-party tools and services.

## Task Classification
- **Type**: Integration
- **Risk Level**: High
- **Effort**: Large
- **Dependencies**: foundation-003 (test suite for endpoint validation), rob-001 (backup system for webhook data)

## Acceptance Criteria
- [ ] RESTful webhook endpoints for project events
- [ ] Configurable webhook subscriptions and filters
- [ ] Secure authentication and authorization
- [ ] Event payload validation and transformation
- [ ] Retry mechanisms for failed webhook deliveries
- [ ] Webhook event logging and monitoring
- [ ] Rate limiting and abuse prevention
- [ ] Support for multiple webhook destinations
- [ ] Real-time event streaming capabilities
- [ ] Integration with popular services (Slack, Discord, email)

## Technical Specification

### Webhook Server Architecture
```bash
# Start webhook server
./github-pm webhook serve [--port=8080] [--config=webhooks.yml]

# Webhook management
./github-pm webhook list
./github-pm webhook add <url> [--events=<events>] [--secret=<secret>]
./github-pm webhook remove <webhook_id>
./github-pm webhook test <webhook_id>
```

### Webhook Configuration
```yaml
# .github-pm/webhooks.yml
webhooks:
  - name: "slack-notifications"
    url: "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    events:
      - "task.completed"
      - "task.blocked"
      - "milestone.achieved"
    filters:
      task_types: ["enhancement", "bug"]
      priorities: ["high", "critical"]
    transform: "slack_message"
    retry_policy:
      max_attempts: 3
      backoff: "exponential"
      
  - name: "ci-cd-integration"
    url: "https://api.example.com/webhooks/github-pm"
    events:
      - "task.assigned"
      - "task.status_changed"
    headers:
      Authorization: "Bearer ${CI_CD_TOKEN}"
      Content-Type: "application/json"
    signature_secret: "${WEBHOOK_SECRET}"
```

### Event Types and Payloads

#### 1. Task Events
```json
{
  "event_type": "task.completed",
  "timestamp": "2024-12-06T10:30:00Z",
  "project": {
    "id": "PVT_kwHOCOLa384A62Y9",
    "url": "https://github.com/users/username/projects/3"
  },
  "task": {
    "id": "42",
    "title": "Implement user authentication",
    "type": "enhancement",
    "status": "done",
    "assignee": "developer@example.com",
    "completed_at": "2024-12-06T10:30:00Z",
    "effort": "large",
    "dependencies": ["#40", "#41"]
  },
  "actor": {
    "type": "user",
    "username": "developer",
    "email": "developer@example.com"
  },
  "changes": {
    "previous_status": "in_progress",
    "new_status": "done"
  }
}
```

#### 2. Project Events
```json
{
  "event_type": "milestone.achieved",
  "timestamp": "2024-12-06T10:30:00Z",
  "project": {
    "id": "PVT_kwHOCOLa384A62Y9",
    "url": "https://github.com/users/username/projects/3"
  },
  "milestone": {
    "name": "Foundation Phase Complete",
    "description": "All foundation tasks completed",
    "achieved_at": "2024-12-06T10:30:00Z",
    "tasks_completed": 8,
    "total_tasks": 8
  },
  "metrics": {
    "completion_time": "14 days",
    "planned_duration": "21 days",
    "efficiency_score": 0.85
  }
}
```

### Webhook Server Implementation
```javascript
// webhook-server.js - Express.js implementation
const express = require('express');
const crypto = require('crypto');
const app = express();

class WebhookServer {
  constructor(config) {
    this.config = config;
    this.webhooks = new Map();
    this.setupRoutes();
  }

  setupRoutes() {
    app.use(express.json());
    
    // Health check
    app.get('/health', (req, res) => {
      res.json({ status: 'healthy', timestamp: new Date().toISOString() });
    });
    
    // Webhook management
    app.post('/webhooks', this.createWebhook.bind(this));
    app.get('/webhooks', this.listWebhooks.bind(this));
    app.delete('/webhooks/:id', this.deleteWebhook.bind(this));
    
    // Event ingestion
    app.post('/events', this.handleEvent.bind(this));
  }

  async handleEvent(req, res) {
    const event = req.body;
    
    try {
      // Validate event structure
      this.validateEvent(event);
      
      // Find matching webhooks
      const matchingWebhooks = this.findMatchingWebhooks(event);
      
      // Deliver to all matching webhooks
      const deliveries = await Promise.allSettled(
        matchingWebhooks.map(webhook => this.deliverWebhook(webhook, event))
      );
      
      res.json({
        status: 'processed',
        event_id: event.id,
        deliveries: deliveries.length,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      res.status(400).json({
        error: 'Event processing failed',
        message: error.message
      });
    }
  }

  async deliverWebhook(webhook, event) {
    const payload = this.transformPayload(webhook, event);
    const signature = this.generateSignature(webhook.secret, payload);
    
    const response = await fetch(webhook.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-GitHub-PM-Signature': signature,
        'X-GitHub-PM-Event': event.event_type,
        ...webhook.headers
      },
      body: JSON.stringify(payload)
    });
    
    if (!response.ok) {
      throw new Error(`Webhook delivery failed: ${response.status}`);
    }
    
    return response;
  }
}
```

### Integration Examples

#### 1. Slack Integration
```yaml
# Slack webhook transformation
slack_notifications:
  task_completed:
    template: |
      {
        "text": "✅ Task completed: ${task.title}",
        "attachments": [
          {
            "color": "good",
            "fields": [
              {
                "title": "Assignee",
                "value": "${task.assignee}",
                "short": true
              },
              {
                "title": "Type",
                "value": "${task.type}",
                "short": true
              }
            ]
          }
        ]
      }
```

#### 2. Email Notifications
```yaml
# Email webhook configuration
email_notifications:
  milestone_achieved:
    template: |
      {
        "to": ["team@example.com"],
        "subject": "🎉 Milestone Achieved: ${milestone.name}",
        "body": "Great news! The milestone '${milestone.name}' has been achieved.\n\nCompleted ${milestone.tasks_completed} tasks in ${metrics.completion_time}.\n\nEfficiency score: ${metrics.efficiency_score}"
      }
```

#### 3. CI/CD Integration
```yaml
# CI/CD webhook for automated deployments
ci_cd_integration:
  task_completed:
    filter:
      task_types: ["deployment"]
      status: ["done"]
    template: |
      {
        "action": "trigger_deployment",
        "task_id": "${task.id}",
        "environment": "${task.metadata.environment}",
        "ref": "${task.metadata.git_ref}"
      }
```

### Security Features

#### 1. Signature Verification
```javascript
function verifySignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
    
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(`sha256=${expectedSignature}`)
  );
}
```

#### 2. Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

const webhookRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many webhook requests from this IP'
});

app.use('/events', webhookRateLimit);
```

### Monitoring and Logging
```json
{
  "webhook_metrics": {
    "total_events_processed": 1250,
    "successful_deliveries": 1198,
    "failed_deliveries": 52,
    "average_response_time": "150ms",
    "top_event_types": [
      "task.completed",
      "task.assigned",
      "milestone.achieved"
    ],
    "webhook_health": [
      {
        "webhook_id": "slack-001",
        "success_rate": 0.98,
        "last_success": "2024-12-06T10:30:00Z"
      }
    ]
  }
}
```

## Testing Strategy
- Test webhook delivery reliability
- Validate security measures (authentication, rate limiting)
- Test event filtering and transformation
- Performance testing with high event volumes
- Integration testing with popular services

## Documentation Impact
- Add webhook integration guide to main documentation
- Create API reference for webhook endpoints
- Document security best practices
- Add integration examples for popular services

## Implementation Notes
- Implement comprehensive error handling and retry logic
- Design for high availability and scalability
- Provide clear webhook debugging tools
- Support both push and pull webhook patterns
- Include webhook payload validation and sanitization