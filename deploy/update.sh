#!/bin/bash
# Run this ON the Lightsail instance to deploy the latest pushed commit.
set -e
cd /srv/ais-osp-dashboard
git pull
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart ais-osp-dashboard
sudo systemctl status ais-osp-dashboard --no-pager
