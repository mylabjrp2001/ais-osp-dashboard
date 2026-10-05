#!/bin/bash
# Auto-deploy check for parinyko/osp-dashboard2 — triggered by the
# osp-dashboard2-autodeploy.timer every 5 minutes. Only pulls + restarts
# when origin/main has actually moved; otherwise exits quietly (no downtime).
set -euo pipefail
cd /srv/osp-dashboard2

git fetch origin main -q

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
  exit 0
fi

echo "$(date -Is) deploying $LOCAL -> $REMOTE"

# his repo has no .gitignore — contacts.json/remarks.json/daily_osp_remain.json/
# uploads/* are tracked and get rewritten live by the app, so stash/pop around pull
git stash push -u -m "live runtime data" || true
git pull -q
git stash pop || true

source venv/bin/activate
pip install -q -r requirements.txt
sudo systemctl restart osp-dashboard2
