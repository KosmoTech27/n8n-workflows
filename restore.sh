#!/bin/bash
# Usage: restore.sh "workflow-name"
# Example: restore.sh "lead-qualification-flow"

REPO_DIR=/opt/n8n-backup
WORKFLOW=$1

if [ -z "$WORKFLOW" ]; then
    echo "Usage: restore.sh <workflow-name>"
    echo ""
    echo "Available workflows:"
    ls $REPO_DIR/workflows/*.json 2>/dev/null | xargs -I{} basename {} .json | sed 's/^/  /'
    exit 1
fi

FILE="$REPO_DIR/workflows/${WORKFLOW}.json"

if [ ! -f "$FILE" ]; then
    echo "Not found: $WORKFLOW"
    echo ""
    echo "Available workflows:"
    ls $REPO_DIR/workflows/*.json 2>/dev/null | xargs -I{} basename {} .json | sed 's/^/  /'
    exit 1
fi

docker cp "$FILE" n8n-n8n-1:/tmp/restore-workflow.json
docker exec n8n-n8n-1 n8n import:workflow --input=/tmp/restore-workflow.json
docker exec n8n-n8n-1 rm /tmp/restore-workflow.json
echo "Restored: $WORKFLOW"
