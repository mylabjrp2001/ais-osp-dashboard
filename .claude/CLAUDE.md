# ais-osp-dashboard — Dashboard OSP BKK

Flask dashboard ติดตาม OSP job (upload Excel → แสดงสรุป/จัดทีม) ไม่มี database, state เก็บเป็น
JSON file ข้าง `app.py` + global in-memory variables

**ตั้งแต่ 2026-10-10 เรารับช่วงแทนเพื่อน — repo นี้คือ source หลัก** (ดึงโค้ดล่าสุดที่ใช้ได้ของ
[parinyko/osp-dashboard2](https://github.com/parinyko/osp-dashboard2) commit `2ea8a00` มาแล้ว)
**แต่ prod ยังดึง repo เพื่อนอยู่** — ยังไม่ได้สลับ (เจ้าของสั่งทำ dev ก่อน) ดู gotchas เรื่อง prod

- Monthly Report เป็นอีกแอป (repo `osp-monthly-report`) — หน้าแรกมีการ์ดลิงก์ไป ตั้ง URL ด้วย env `MONTHLY_REPORT_URL`
- รายละเอียดเครื่อง prod อยู่ใน private ops docs เท่านั้น (repo นี้ public)

## เอกสาร
- กับดักที่ต้องรู้ก่อนแก้โค้ด: [gotchas.md](gotchas.md)
- Deploy Lightsail เดิม (เก็บไว้อ้างอิง): [runbooks/deploy.md](runbooks/deploy.md)

## รัน dev
```bash
MONTHLY_REPORT_URL=http://localhost:5190 PORT=5195 python3 app.py   # http://127.0.0.1:5195
```
ข้อมูล dev = สำเนา `*.json` + Excel ล่าสุดจาก prod (gitignore ทั้งหมด)

## โครงสร้าง
- `app.py` — ทั้งแอปอยู่ไฟล์เดียว, `templates/` — HTML (Flask render จากที่นี่เท่านั้น)
- `uploads/` — ไฟล์ Excel ที่อัปโหลด, `*.json` ที่ root — state runtime (ไม่ track ใน git)
- ก่อน commit: `python3 -c "import ast; ast.parse(open('app.py').read())"` — ไฟล์ที่ parse ไม่ผ่านเคยทำ prod ล่มมาแล้ว
