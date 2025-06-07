# API Reference - GitHub Project AI Manager
## GraphQL Operations and Endpoints

This document provides a comprehensive reference for all GraphQL operations used by the GitHub Project AI Manager.

---

## 🔐 Authentication

### Required Scopes
```bash
# Authenticate with GitHub CLI
gh auth refresh -s project,read:project --hostname github.com
```

### Required Permissions
- **`project`**: Create and manage GitHub Projects
- **`read:project`**: Read project data and structure
- **`repo`**: Access repository issues and pull requests

---

## 🏗️ Core Operations

### Project Management

#### Create Project
```graphql
mutation CreateProject($ownerId: ID!, $title: String!) {
  createProjectV2(input: {
    ownerId: $ownerId,
    title: $title
  }) {
    projectV2 {
      id
      url
      number
    }
  }
}
```

**Usage:**
```bash
gh api graphql -f query='
  mutation {
    createProjectV2(input: {
      ownerId: "USER_NODE_ID",
      title: "Property Renderer Consolidation"
    }) {
      projectV2 {
        id
        url
        number
      }
    }
  }'
```

#### Query Project Details
```graphql
query GetProject($projectNumber: Int!, $login: String!) {
  user(login: $login) {
    projectV2(number: $projectNumber) {
      id
      title
      url
      fields(first: 20) {
        nodes {
          ... on ProjectV2Field {
            id
            name
            dataType
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
              color
            }
          }
        }
      }
      items(first: 50) {
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              state
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldTextValue {
                text
                field {
                  ... on ProjectV2Field {
                    name
                  }
                }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field {
                  ... on ProjectV2Field {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Custom Fields

#### Create Single Select Field
```graphql
mutation CreateSingleSelectField(
  $projectId: ID!,
  $name: String!,
  $options: [ProjectV2SingleSelectFieldOptionInput!]!
) {
  createProjectV2Field(input: {
    projectId: $projectId,
    dataType: SINGLE_SELECT,
    name: $name,
    singleSelectOptions: $options
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options {
          id
          name
          color
        }
      }
    }
  }
}
```

**Example - Task Type Field:**
```bash
gh api graphql -f query='
  mutation {
    createProjectV2Field(input: {
      projectId: "PROJECT_ID",
      dataType: SINGLE_SELECT,
      name: "Task Type",
      singleSelectOptions: [
        {name: "Foundation", color: BLUE, description: "Foundation tasks"},
        {name: "Enhancement", color: GREEN, description: "Enhancement tasks"},
        {name: "Migration", color: YELLOW, description: "Migration tasks"},
        {name: "QA", color: PURPLE, description: "Quality assurance"},
        {name: "Documentation", color: GRAY, description: "Documentation tasks"}
      ]
    }) {
      projectV2Field {
        id
        name
      }
    }
  }'
```

#### Create Text Field
```graphql
mutation CreateTextField($projectId: ID!, $name: String!) {
  createProjectV2Field(input: {
    projectId: $projectId,
    dataType: TEXT,
    name: $name
  }) {
    projectV2Field {
      ... on ProjectV2Field {
        id
        name
      }
    }
  }
}
```

### Issue Management

#### Add Issue to Project
```graphql
mutation AddIssueToProject($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {
    projectId: $projectId,
    contentId: $contentId
  }) {
    item {
      id
    }
  }
}
```

#### Create Issue
```graphql
mutation CreateIssue(
  $repositoryId: ID!,
  $title: String!,
  $body: String!,
  $milestoneId: ID
) {
  createIssue(input: {
    repositoryId: $repositoryId,
    title: $title,
    body: $body,
    milestoneId: $milestoneId
  }) {
    issue {
      id
      number
      title
    }
  }
}
```

### Field Value Updates

#### Update Single Select Field
```graphql
mutation UpdateSingleSelectField(
  $projectId: ID!,
  $itemId: ID!,
  $fieldId: ID!,
  $optionId: String!
) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId,
    itemId: $itemId,
    fieldId: $fieldId,
    value: {
      singleSelectOptionId: $optionId
    }
  }) {
    projectV2Item {
      id
    }
  }
}
```

**Example - Update Status:**
```bash
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "PROJECT_ID",
      itemId: "ITEM_ID",
      fieldId: "STATUS_FIELD_ID",
      value: {
        singleSelectOptionId: "IN_PROGRESS_OPTION_ID"
      }
    }) {
      projectV2Item {
        id
      }
    }
  }'
```

#### Update Text Field
```graphql
mutation UpdateTextField(
  $projectId: ID!,
  $itemId: ID!,
  $fieldId: ID!,
  $text: String!
) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId,
    itemId: $itemId,
    fieldId: $fieldId,
    value: {
      text: $text
    }
  }) {
    projectV2Item {
      id
    }
  }
}
```

---

## 📊 Query Operations

### Project Status Queries

#### Get All Project Items with Fields
```graphql
query GetProjectStatus($login: String!, $projectNumber: Int!) {
  user(login: $login) {
    projectV2(number: $projectNumber) {
      id
      title
      items(first: 50) {
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              state
              assignees(first: 5) {
                nodes {
                  login
                }
              }
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldTextValue {
                text
                field {
                  ... on ProjectV2Field {
                    name
                  }
                }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                color
                field {
                  ... on ProjectV2Field {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

#### Get Specific Issue in Project
```graphql
query GetIssueInProject(
  $owner: String!,
  $repo: String!,
  $issueNumber: Int!
) {
  repository(owner: $owner, name: $repo) {
    issue(number: $issueNumber) {
      id
      number
      title
      state
      projectItems(first: 10) {
        nodes {
          id
          project {
            id
            title
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldTextValue {
                text
                field {
                  ... on ProjectV2Field {
                    name
                  }
                }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field {
                  ... on ProjectV2Field {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Repository Queries

#### Get Repository ID
```graphql
query GetRepository($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id
    name
    owner {
      login
    }
  }
}
```

#### Get User/Organization ID
```graphql
query GetUser($login: String!) {
  user(login: $login) {
    id
    login
  }
}
```

---

## 🛠️ Field Management

### Standard Field Types

#### Status Field (Single Select)
```graphql
# Options for project board workflow
{
  name: "Status",
  options: [
    {name: "Backlog", color: GRAY, description: "Not yet started"},
    {name: "Ready", color: YELLOW, description: "Can begin work"},
    {name: "In Progress", color: BLUE, description: "Currently active"},
    {name: "Review", color: PURPLE, description: "Awaits review"},
    {name: "Done", color: GREEN, description: "Complete and tested"}
  ]
}
```

#### Task Type Field (Single Select)
```graphql
{
  name: "Task Type",
  options: [
    {name: "Foundation", color: BLUE, description: "Foundation tasks"},
    {name: "Enhancement", color: GREEN, description: "Enhancement tasks"},
    {name: "Migration", color: YELLOW, description: "Migration tasks"},
    {name: "QA", color: PURPLE, description: "Quality assurance"},
    {name: "Documentation", color: GRAY, description: "Documentation tasks"}
  ]
}
```

#### Risk Level Field (Single Select)
```graphql
{
  name: "Risk Level",
  options: [
    {name: "Critical", color: RED, description: "Critical risk"},
    {name: "High", color: ORANGE, description: "High risk"},
    {name: "Medium", color: YELLOW, description: "Medium risk"},
    {name: "Low", color: GREEN, description: "Low risk"}
  ]
}
```

#### Effort Field (Single Select)
```graphql
{
  name: "Effort",
  options: [
    {name: "Small (1-2 days)", color: GREEN, description: "Quick tasks"},
    {name: "Medium (3-5 days)", color: YELLOW, description: "Standard tasks"},
    {name: "Large (1+ weeks)", color: RED, description: "Complex tasks"}
  ]
}
```

#### Dependencies Field (Text)
```graphql
{
  name: "Dependencies",
  dataType: TEXT,
  description: "Prerequisite issue numbers (e.g., '#39, #40, #41')"
}
```

---

## 🔄 Workflow Automation

### State Transition Patterns

#### Move Task to Ready
```bash
# 1. Get current status option ID
STATUS_FIELD_ID=$(gh api graphql -f query='...' | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .id')

# 2. Get "Ready" option ID  
READY_OPTION_ID=$(gh api graphql -f query='...' | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .options[] | select(.name=="Ready") | .id')

# 3. Update item status
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "'$PROJECT_ID'",
      itemId: "'$ITEM_ID'",
      fieldId: "'$STATUS_FIELD_ID'",
      value: {
        singleSelectOptionId: "'$READY_OPTION_ID'"
      }
    }) {
      projectV2Item { id }
    }
  }'
```

#### Dependency Validation Pattern
```bash
# 1. Get dependencies text
DEPENDENCIES=$(gh api graphql -f query='...' | jq -r '.data.repository.issue.projectItems.nodes[0].fieldValues.nodes[] | select(.field.name=="Dependencies") | .text')

# 2. Parse dependency issue numbers
DEPENDENCY_NUMBERS=$(echo "$DEPENDENCIES" | grep -oE '#[0-9]+' | sed 's/#//')

# 3. Check each dependency status
for dep_number in $DEPENDENCY_NUMBERS; do
  DEP_STATUS=$(gh api graphql -f query='...' | jq -r '.data.repository.issue.projectItems.nodes[0].fieldValues.nodes[] | select(.field.name=="Status") | .name')
  if [ "$DEP_STATUS" != "Done" ]; then
    echo "❌ Dependency #$dep_number not complete (status: $DEP_STATUS)"
    exit 1
  fi
done
```

### Batch Operations

#### Update Multiple Items
```bash
# Example: Set multiple items to same status
ITEM_IDS=("ITEM_ID_1" "ITEM_ID_2" "ITEM_ID_3")

for item_id in "${ITEM_IDS[@]}"; do
  gh api graphql -f query='
    mutation {
      updateProjectV2ItemFieldValue(input: {
        projectId: "'$PROJECT_ID'",
        itemId: "'$item_id'",
        fieldId: "'$STATUS_FIELD_ID'",
        value: {
          singleSelectOptionId: "'$READY_OPTION_ID'"
        }
      }) {
        projectV2Item { id }
      }
    }'
done
```

---

## 🚨 Error Handling

### Common Errors

#### Insufficient Scopes
```json
{
  "errors": [{
    "type": "INSUFFICIENT_SCOPES",
    "message": "Your token has not been granted the required scopes to execute this query. The 'createProjectV2' field requires one of the following scopes: ['project']"
  }]
}
```

**Solution:**
```bash
gh auth refresh -s project,read:project --hostname github.com
```

#### Invalid Field Value
```json
{
  "errors": [{
    "type": "UNPROCESSABLE",
    "message": "Field value is invalid"
  }]
}
```

**Solution:**
- Verify field ID exists
- Check option ID is valid for single select fields
- Ensure text values don't exceed length limits

#### Rate Limiting
```json
{
  "errors": [{
    "type": "RATE_LIMITED",
    "message": "API rate limit exceeded"
  }]
}
```

**Solution:**
- Add delays between requests
- Use batch operations where possible
- Implement exponential backoff

### Error Handling Patterns

#### Robust Query with Error Handling
```bash
execute_graphql_query() {
  local query="$1"
  local max_retries=3
  local retry_count=0
  
  while [ $retry_count -lt $max_retries ]; do
    response=$(gh api graphql -f query="$query" 2>&1)
    
    if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
      echo "❌ GraphQL Error: $(echo "$response" | jq -r '.errors[0].message')"
      retry_count=$((retry_count + 1))
      sleep $((retry_count * 2))  # Exponential backoff
    else
      echo "$response"
      return 0
    fi
  done
  
  echo "❌ Failed after $max_retries retries"
  return 1
}
```

---

## 📚 References

### Official Documentation
- [GitHub GraphQL API](https://docs.github.com/en/graphql)
- [GitHub Projects API](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- [GitHub CLI Manual](https://cli.github.com/manual/)

### Field Types Reference
- **TEXT**: Plain text field
- **NUMBER**: Numeric values
- **DATE**: Date values
- **SINGLE_SELECT**: Single choice from predefined options
- **MULTI_SELECT**: Multiple choices from predefined options

### Color Options
- **RED**: Critical/urgent items
- **ORANGE**: High priority items  
- **YELLOW**: Medium priority items
- **GREEN**: Low priority/completed items
- **BLUE**: In progress items
- **PURPLE**: Review/QA items
- **GRAY**: Backlog/inactive items

---

**This API reference provides the complete technical foundation for building and extending the GitHub Project AI Manager system.**