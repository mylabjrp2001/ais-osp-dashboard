# AIS Job Monitor

## Run

```bash
python -m pip install -r requirements.txt
python app.py
```

Then open `http://127.0.0.1:5000/`.

## Theme
- AIS-inspired light green theme using the supplied logo.
- Dashboard and Job Monitor share the same visual language.
- Job Monitor includes Sub System filters:
  - MBB = Transmission-OSP
  - EDS = EDS-OSP, ETS-OSP, EDS SW NODE-OSP, EDS IPLC-OSP
  - FBB = FTTB-OSP, FTTH-OSP, FTTX-OSP, Splitter-OSP

## Deploy
Production = AWS Lightsail instance เดียว (ไม่ใช้ Docker) — ดู [.claude/runbooks/deploy.md](.claude/runbooks/deploy.md)

## Push Log
- 2026-10-05 — เพิ่ม `.gitignore` (กัน runtime JSON state/uploads ไม่ให้ชน git pull บน server) +
  `deploy/` (systemd unit + update script) + `.claude/` docs เตรียม deploy ขึ้น AWS Lightsail
