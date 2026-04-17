#!/bin/bash

REPO_DIR=/opt/n8n-backup
EXPORT_DIR=$REPO_DIR/workflows
TEMP_DIR=$(mktemp -d)

mkdir -p $EXPORT_DIR

docker exec n8n-n8n-1 mkdir -p /tmp/n8n-export
docker exec n8n-n8n-1 n8n export:workflow --all --backup --output=/tmp/n8n-export/ 2>/dev/null || true
docker cp n8n-n8n-1:/tmp/n8n-export/. $TEMP_DIR/ 2>/dev/null || true
docker exec n8n-n8n-1 rm -rf /tmp/n8n-export 2>/dev/null || true

for f in $TEMP_DIR/*.json; do
    [ -f "$f" ] || continue
    name=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('name','unknown'))" 2>/dev/null)
    safe=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
    cp "$f" "$EXPORT_DIR/${safe}.json"
done
rm -rf $TEMP_DIR

cd $REPO_DIR

UPDATED=$(git diff --name-only workflows/ | sed 's|workflows/||;s|\.json||' | paste -sd ', ')
ADDED=$(git ls-files --others --exclude-standard workflows/ | sed 's|workflows/||;s|\.json||' | paste -sd ', ')
DELETED=$(git diff --name-only --diff-filter=D workflows/ | sed 's|workflows/||;s|\.json||' | paste -sd ', ')

PARTS=()
[ -n "$ADDED" ]   && PARTS+=("Added: $ADDED")
[ -n "$UPDATED" ] && PARTS+=("Updated: $UPDATED")
[ -n "$DELETED" ] && PARTS+=("Removed: $DELETED")

if [ -n "$CUSTOM_COMMIT_MSG" ]; then
    MSG="$CUSTOM_COMMIT_MSG"
elif [ ${#PARTS[@]} -gt 0 ]; then
    MSG=$(IFS='; '; echo "${PARTS[*]}")
else
    echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M') IST] No changes"
    exit 0
fi

git add .
git commit -m "$MSG"
git push origin main
echo "[$(TZ='Asia/Kolkata' date '+%Y-%m-%d %H:%M') IST] $MSG"
