#!/bin/bash
# Run this ON the Lightsail instance to deploy the latest pushed commit
# from https://github.com/parinyko/osp-dashboard2 (his repo, not ours).
set -e
cd /srv/osp-dashboard2

# His repo tracks contacts.json/remarks.json/daily_osp_remain.json/uploads/*
# directly (no .gitignore) — the running app rewrites those constantly, so
# the working tree is always "dirty". Stash them around the pull so a local
# data write never blocks picking up his new commits.
git stash push -u -m "live runtime data" || true
git pull
git stash pop || true

source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart osp-dashboard2
sudo systemctl status osp-dashboard2 --no-pager
