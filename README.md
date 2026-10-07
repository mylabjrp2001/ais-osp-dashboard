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
Production จริงรันโค้ดจาก [github.com/parinyko/osp-dashboard2](https://github.com/parinyko/osp-dashboard2)
(repo เพื่อน) — **ย้ายออกจาก AWS Lightsail แล้ว (2026-10-07)** ไปรันบนเครื่อง internal แทน
รายละเอียด/credential ของเครื่องนั้นอยู่ใน private ops docs เท่านั้น (repo นี้ public) — เอกสาร
Lightsail เดิมเก็บไว้เป็น reference/rollback ที่ [.claude/runbooks/deploy.md](.claude/runbooks/deploy.md)

## Push Log
- 2026-10-05 — เพิ่ม `.gitignore` (กัน runtime JSON state/uploads ไม่ให้ชน git pull บน server) +
  `deploy/` (systemd unit + update script) + `.claude/` docs เตรียม deploy ขึ้น AWS Lightsail
- 2026-10-05 — เปลี่ยนเป้า deploy จริงไปที่ repo เพื่อน (`parinyko/osp-dashboard2`) แทน, ปรับ
  `deploy/update.sh` ให้ stash/pop ไฟล์ runtime data ก่อน-หลัง `git pull` เพราะ repo เพื่อนไม่มี
  `.gitignore`
- 2026-10-07 — แก้ CPU spike: cache home summary แทนคำนวณใหม่ทุก request + เปิด `threaded=True`
  (ยังไม่ขึ้น repo เพื่อน ต้องส่ง diff ให้เขา apply เอง) — ย้าย production ออกจาก Lightsail ไปเครื่อง
  internal (รายละเอียดอยู่ private ops docs)
