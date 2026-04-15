#!/bin/bash

REPO_DIR=/opt/n8n-backup
EXPORT_DIR=$REPO_DIR/workflows

mkdir -p $EXPORT_DIR

# Export workflows from n8n container
docker exec n8n-n8n-1 mkdir -p /tmp/n8n-export
docker exec n8n-n8n-1 n8n export:workflow --all --backup --output=/tmp/n8n-export/ 2>/dev/null || true
docker cp n8n-n8n-1:/tmp/n8n-export/. $EXPORT_DIR/ 2>/dev/null || true
docker exec n8n-n8n-1 rm -rf /tmp/n8n-export 2>/dev/null || true

cd $REPO_DIR

if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "Auto-export: $(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M') IST"
    git push origin main
    echo "[$(date)] Pushed changes to GitHub"
else
    echo "[$(date)] No changes"
fi
