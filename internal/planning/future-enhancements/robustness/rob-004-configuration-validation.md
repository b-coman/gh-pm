# [Robustness] Configuration Validation

## Overview
Implement comprehensive configuration validation system that ensures all project configurations, field mappings, and system settings are valid, consistent, and optimal. This prevents configuration errors, provides helpful validation feedback, and maintains system reliability across different project setups.

## Task Classification
- **Type**: Enhancement
- **Risk Level**: Medium
- **Effort**: Medium
- **Dependencies**: foundation-003 (test suite for validation scenarios), dev-002 (quality tools for schema validation)

## Acceptance Criteria
- [ ] Comprehensive configuration schema validation
- [ ] Real-time validation feedback during configuration
- [ ] Configuration migration and upgrade validation
- [ ] Cross-reference validation for dependent settings
- [ ] Performance impact validation for large projects
- [ ] Security validation for sensitive configurations
- [ ] Configuration template validation and suggestions
- [ ] Automated configuration repair where possible
- [ ] Configuration compliance checking
- [ ] Integration with configuration management tools

## Technical Specification

### Configuration Validation Commands
```bash
# Validate current configuration
./github-pm config validate [--fix-warnings] [--strict]
./github-pm config doctor [--comprehensive] [--output=report.json]

# Schema validation
./github-pm config schema validate [--file=config.yml]
./github-pm config schema generate [--template=basic|advanced]

# Migration validation
./github-pm config migrate --from=1.0 --to=2.0 --dry-run
./github-pm config upgrade --validate-only

# Configuration analysis
./github-pm config analyze [--performance] [--security] [--compliance]
./github-pm config suggest [--optimize-for=speed|reliability|compliance]
```

### Configuration Schema

#### 1. Main Configuration Schema
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "GitHub PM Configuration",
  "type": "object",
  "required": ["project", "authentication"],
  "properties": {
    "project": {
      "type": "object",
      "required": ["id", "url"],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^PVT_[a-zA-Z0-9]+$",
          "description": "GitHub Project ID"
        },
        "url": {
          "type": "string",
          "format": "uri",
          "pattern": "^https://github\\.com/(users|orgs)/[^/]+/projects/\\d+$"
        },
        "field_mappings": {
          "$ref": "#/$defs/field_mappings"
        }
      }
    },
    "authentication": {
      "$ref": "#/$defs/authentication"
    },
    "performance": {
      "$ref": "#/$defs/performance_settings"
    },
    "logging": {
      "$ref": "#/$defs/logging_settings"
    }
  },
  "$defs": {
    "field_mappings": {
      "type": "object",
      "patternProperties": {
        "^[a-zA-Z_][a-zA-Z0-9_]*$": {
          "type": "object",
          "required": ["id", "type"],
          "properties": {
            "id": {
              "type": "string",
              "pattern": "^PVTSSF_[a-zA-Z0-9]+$"
            },
            "type": {
              "enum": ["single_select", "text", "number", "date"]
            },
            "required": {"type": "boolean"},
            "options": {
              "type": "array",
              "items": {"type": "string"}
            }
          }
        }
      }
    }
  }
}
```

#### 2. Validation Rules Engine
```yaml
# .github-pm/validation-rules.yml
validation_rules:
  project_configuration:
    - rule: "project_id_format"
      check: "project.id matches PVT_* pattern"
      severity: "error"
      auto_fix: false
      
    - rule: "field_mapping_consistency"
      check: "all referenced field IDs exist in GitHub project"
      severity: "error"
      auto_fix: false
      
    - rule: "required_fields_present"
      check: "status and type fields are configured"
      severity: "warning"
      auto_fix: true
      
  performance:
    - rule: "cache_size_reasonable"
      check: "cache_size_mb <= system_memory * 0.1"
      severity: "warning"
      auto_fix: true
      
    - rule: "api_rate_limit_buffer"
      check: "api_requests_per_minute <= rate_limit * 0.8"
      severity: "warning"
      auto_fix: false
      
  security:
    - rule: "token_permissions_minimal"
      check: "github_token has only required scopes"
      severity: "warning"
      auto_fix: false
      
    - rule: "log_level_production"
      check: "log_level != DEBUG in production"
      severity: "info"
      auto_fix: true
```

### Validation Implementation

#### 1. Configuration Validator
```javascript
// config-validator.js
class ConfigurationValidator {
  constructor(schema, rules) {
    this.schema = schema;
    this.rules = rules;
    this.ajv = new Ajv({ allErrors: true });
    this.validate = this.ajv.compile(schema);
  }

  async validateConfiguration(config) {
    const results = {
      valid: true,
      errors: [],
      warnings: [],
      suggestions: [],
      auto_fixes: []
    };

    // Schema validation
    const schemaValid = this.validate(config);
    if (!schemaValid) {
      results.valid = false;
      results.errors.push(...this.formatSchemaErrors(this.validate.errors));
    }

    // Custom rule validation
    const ruleResults = await this.validateRules(config);
    results.errors.push(...ruleResults.errors);
    results.warnings.push(...ruleResults.warnings);
    results.suggestions.push(...ruleResults.suggestions);
    results.auto_fixes.push(...ruleResults.auto_fixes);

    // Cross-reference validation
    const crossRefResults = await this.validateCrossReferences(config);
    results.errors.push(...crossRefResults.errors);
    results.warnings.push(...crossRefResults.warnings);

    return results;
  }

  async validateCrossReferences(config) {
    const results = { errors: [], warnings: [] };
    
    // Validate field mappings against actual GitHub project
    try {
      const projectFields = await this.fetchProjectFields(config.project.id);
      const mappedFields = Object.values(config.project.field_mappings || {});
      
      for (const field of mappedFields) {
        if (!projectFields.find(pf => pf.id === field.id)) {
          results.errors.push({
            type: "missing_field_reference",
            message: `Field ID ${field.id} does not exist in project`,
            field: field.id,
            fix_suggestion: "Update field mapping or create field in project"
          });
        }
      }
    } catch (error) {
      results.warnings.push({
        type: "validation_incomplete",
        message: "Could not validate field references against GitHub project",
        reason: error.message
      });
    }

    return results;
  }
}
```

### Validation Output Examples

#### 1. Successful Validation
```bash
./github-pm config validate

✅ Configuration Validation Results

📋 Schema Validation: PASSED
🔗 Cross-references: PASSED  
⚡ Performance Analysis: GOOD
🔒 Security Check: GOOD

💡 Suggestions (2):
  • Consider enabling caching for better performance
  • Log level could be reduced to INFO in production

✨ Configuration is valid and ready to use!
```

#### 2. Validation with Issues
```bash
./github-pm config validate

❌ Configuration Validation Results

📋 Schema Validation: FAILED (2 errors)
🔗 Cross-references: FAILED (1 error)
⚡ Performance Analysis: WARNINGS (3 warnings)
🔒 Security Check: WARNINGS (1 warning)

🚨 ERRORS:
  1. project.field_mappings.status.id: Field ID 'PVTSSF_invalid123' does not exist
     → Run 'github-pm configure' to update field mappings
     
  2. authentication.github_token: Required property missing
     → Set GITHUB_TOKEN environment variable or use 'gh auth login'

⚠️  WARNINGS:
  1. performance.cache_size_mb: 512MB cache size may be too large for system
     → Recommended: 128MB (auto-fix available)
     
  2. logging.level: DEBUG level not recommended for production
     → Recommended: INFO (auto-fix available)
     
  3. security.token_scopes: Token has broader permissions than needed
     → Consider using token with minimal required scopes

🔧 Auto-fixes available: Run with --fix-warnings to apply
```

### Configuration Analysis Features

#### 1. Performance Analysis
```json
{
  "performance_analysis": {
    "cache_efficiency": {
      "current_size_mb": 256,
      "recommended_size_mb": 128,
      "efficiency_score": 0.85,
      "suggestions": ["Reduce cache size for memory efficiency"]
    },
    "api_usage": {
      "requests_per_minute": 45,
      "rate_limit": 5000,
      "buffer_percentage": 0.91,
      "status": "excellent"
    },
    "project_size_impact": {
      "task_count": 150,
      "complexity": "medium",
      "expected_performance": "good",
      "recommendations": ["Consider enabling parallel processing"]
    }
  }
}
```

#### 2. Security Analysis
```json
{
  "security_analysis": {
    "token_permissions": {
      "current_scopes": ["repo", "project", "user"],
      "required_scopes": ["repo", "project"],
      "excess_permissions": ["user"],
      "recommendation": "Use token with minimal required scopes"
    },
    "configuration_exposure": {
      "sensitive_data_in_config": false,
      "secure_storage": true,
      "encryption_status": "enabled"
    },
    "access_patterns": {
      "unusual_access": false,
      "multiple_users": true,
      "recommendation": "Consider user-specific configurations"
    }
  }
}
```

### Auto-Fix Capabilities
```bash
# Automatic configuration fixes
./github-pm config validate --fix-warnings

🔧 Applying automatic fixes...

✅ Fixed: Reduced cache size from 512MB to 128MB
✅ Fixed: Changed log level from DEBUG to INFO
✅ Fixed: Added missing required field mappings
⚠️  Skipped: Token permissions (requires manual action)

💾 Configuration updated and saved
🔄 Restart recommended for changes to take effect
```

### Configuration Templates
```yaml
# .github-pm/templates/basic-project.yml
name: "Basic Project Template"
description: "Standard configuration for small to medium projects"
configuration:
  project:
    field_mappings:
      status:
        type: "single_select"
        options: ["todo", "ready", "in_progress", "review", "done"]
        required: true
      type:
        type: "single_select"
        options: ["foundation", "enhancement", "bug", "documentation"]
        required: true
  performance:
    cache_size_mb: 64
    api_requests_per_minute: 30
  logging:
    level: "INFO"
    retention_days: 30
```

## Testing Strategy
- Test validation with various configuration scenarios
- Test auto-fix capabilities and safety
- Validate cross-reference checking accuracy
- Test performance impact of validation processes
- Test integration with configuration migration

## Documentation Impact
- Add configuration validation section to main documentation
- Create configuration best practices guide
- Document validation rules and their purposes
- Add troubleshooting guide for common configuration issues

## Implementation Notes
- Design validation to be fast and non-intrusive
- Provide clear, actionable error messages
- Implement safe auto-fix mechanisms
- Support validation in CI/CD environments
- Include comprehensive test coverage for validation rules