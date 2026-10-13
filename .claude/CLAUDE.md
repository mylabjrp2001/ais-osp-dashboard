# ais-osp-dashboard — Dashboard OSP BKK

Flask dashboard ติดตาม OSP job (upload Excel → แสดงสรุป/จัดทีม) ไม่มี database, state เก็บเป็น
JSON file ข้าง `app.py` + global in-memory variables

**งานพัฒนาจริงทำใน repo เพื่อน [parinyko/osp-dashboard2](https://github.com/parinyko/osp-dashboard2)**
(clone ที่ `~/Desktop/developer/osp-dashboard2`) — prod auto-deploy จาก repo นั้นทุก 5 นาที · push = ขึ้น prod
· commit ที่นั่นห้ามมีชื่อ Claude · repo นี้ (public) เก็บแค่ Push Log + gotchas + เอกสาร
โค้ดใน repo นี้ค้างอยู่ที่ `2ea8a00` (10 ต.ค.) — ยังไม่มี Job Map / ล็อกอิน / งานหลังจากนั้น

- Monthly Report เป็นอีกแอป (repo `osp-monthly-report`) — หน้าแรกมีการ์ดลิงก์ไป ตั้ง URL ด้วย env `MONTHLY_REPORT_URL`
- รายละเอียดเครื่อง prod อยู่ใน private ops docs เท่านั้น (repo นี้ public)

## กฎ UI (เจ้าของสั่ง 11 ต.ค. 2026)
- **ห้ามใช้อิโมจิใน UI** — ปุ่ม การ์ด หัวข้อ ป้าย ใช้ไอคอน SVG เท่านั้น · หน้าที่ยังมีอิโมจิ แก้เมื่อแตะหน้านั้น
- ดีไซน์ต้องดูมืออาชีพและไม่เลียนแบบแอปอื่น · งาน UI ใหญ่เสนอ 2–3 แบบให้เลือกก่อน

## เอกสาร
- กับดักที่ต้องรู้ก่อนแก้โค้ด: [gotchas.md](gotchas.md)
- Deploy Lightsail เดิม (**ปิดเครื่องแล้ว 2026-10-10** · เก็บไว้อ้างอิงเท่านั้น): [runbooks/deploy.md](runbooks/deploy.md)

## รัน dev
```bash
MONTHLY_REPORT_URL=http://localhost:5190 PORT=5195 python3 app.py   # http://127.0.0.1:5195
```
ข้อมูล dev = สำเนา `*.json` + Excel ล่าสุดจาก prod (gitignore ทั้งหมด)

## โครงสร้าง
- `app.py` — ทั้งแอปอยู่ไฟล์เดียว, `templates/` — HTML (Flask render จากที่นี่เท่านั้น)
- `uploads/` — ไฟล์ Excel ที่อัปโหลด, `*.json` ที่ root — state runtime (ไม่ track ใน git)
- ก่อน commit: `python3 -c "import ast; ast.parse(open('app.py').read())"` — ไฟล์ที่ parse ไม่ผ่านเคยทำ prod ล่มมาแล้ว
