#!/bin/bash

# Test script for dynamic field lookup

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/config-utils.sh"
source "$SCRIPT_DIR/scripts/lib/field-utils.sh"

echo "🧪 Testing Dynamic Field Lookup"
echo "==============================="

# Validate configuration
if ! validate_config; then
    echo "❌ Configuration validation failed."
    exit 1
fi

PROJECT_ID=$(get_project_id)
echo "📊 Project ID: $PROJECT_ID"
echo ""

echo "🔍 Testing field lookup..."

# Test field ID lookup
echo "Looking up Task Type field:"
TASK_TYPE_ID=$(get_field_id_dynamic "task_type")
echo "  ID: $TASK_TYPE_ID"

echo "Looking up Status field:"
STATUS_ID=$(get_field_id_dynamic "status")
echo "  ID: $STATUS_ID"

echo ""
echo "🔍 Testing option lookup..."

# Test option ID lookup
echo "Looking up 'Done' option in Status field:"
DONE_OPTION_ID=$(get_field_option_id_dynamic "status" "Done")
echo "  ID: $DONE_OPTION_ID"

echo "Looking up 'In Progress' option in Status field:"
IN_PROGRESS_OPTION_ID=$(get_field_option_id_dynamic "status" "In Progress")
echo "  ID: $IN_PROGRESS_OPTION_ID"

echo ""
echo "✅ Field lookup test complete!"