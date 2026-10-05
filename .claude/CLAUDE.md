# ais-osp-dashboard

Flask dashboard ติดตาม OSP job (upload Excel → แสดงสรุป/จัดทีม) ไม่มี database, state เก็บเป็น
JSON file ข้าง `app.py` + global in-memory variables

## เอกสาร
- Deploy: [runbooks/deploy.md](runbooks/deploy.md) — AWS Lightsail instance เดียว ไม่ใช้ Docker
- กับดักที่ต้องรู้ก่อนแก้โค้ด: [gotchas.md](gotchas.md)

## โครงสร้าง
- `app.py` — ทั้งแอปอยู่ไฟล์เดียว, `templates/` — HTML (Flask render จากที่นี่เท่านั้น)
- `uploads/` — ไฟล์ Excel ที่อัปโหลด, `*.json` ที่ root — state runtime (ไม่ track ใน git)
