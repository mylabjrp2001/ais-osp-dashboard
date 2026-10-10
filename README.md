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

## Monthly Report
การ์ด "Monthly Report" ในหน้าแรก (และแถบเมนูหน้า Resource Monitor) ลิงก์ไปอีกแอป ตั้ง URL ด้วย env
`MONTHLY_REPORT_URL` — ไม่ตั้ง = ซ่อนการ์ด (prod ตอนนี้) · dev ตั้งเป็น `http://localhost:5190`

## Deploy
ตั้งแต่ 2026-10-10 **repo นี้คือ source หลัก** (เรารับช่วงต่อจากเพื่อน) แต่ prod ยังดึงโค้ดจาก
[github.com/parinyko/osp-dashboard2](https://github.com/parinyko/osp-dashboard2) อยู่ จนกว่าจะสลับ —
**ย้ายออกจาก AWS Lightsail แล้ว (2026-10-07)** ไปรันบนเครื่อง internal แทน
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
- 2026-10-10 — **รับช่วงต่อจากเพื่อน: repo นี้เป็น source หลัก** · ดึงโค้ดล่าสุดที่รันได้ของเพื่อน
  (`2ea8a00` — Resource Monitor, Indue/Outdue) · commit ล่าสุดของเขา `2765348` parse ไม่ผ่าน (ย่อหน้าหาย)
  ไม่ได้เอามา · perf fix ทำใหม่ให้ถูก: cache home summary 60 วิ + ล้างเมื่อ upload/remark/contact
  (รุ่นเดิม cache จน upload ครั้งหน้า ทำให้สถานะทีมขาด/เลิกดึกค้าง) · เพิ่มการ์ด + เมนู Monthly Report
  (`MONTHLY_REPORT_URL`) · `.gitignore` กัน `*.xlsx` (repo public) · prod ยังไม่เปลี่ยน
- 2026-10-10 — ไม่ตั้ง `MONTHLY_REPORT_URL` = ซ่อนการ์ด/เมนู Monthly Report (เตรียมขึ้น prod ก่อนที่ Monthly Report จะมีโดเมน)
- 2026-10-10 — ปิดเครื่อง AWS Lightsail แล้ว (prod อยู่เครื่อง internal) · `runbooks/deploy.md` เก็บไว้อ้างอิงเท่านั้น
- 2026-10-10 — Daily OSP Remain สรุปตอน 20:00 แทน 18:00: app.py ของเพื่อน (`8ae15d1`) เปลี่ยนเวลาเป็น 08/12/16/20 → แก้กลับเป็น 06:00/18:00 ใน repo เพื่อน (`7efb3b4`) ขึ้น prod แล้ว · repo นี้ยังเป็น 06/18 อยู่แล้ว
- 2026-10-10 — Daily OSP Remain: ปุ่ม ⏰ ตั้งรอบสรุปในหน้าเว็บ (เวลา HH:MM หลายรอบ · ว่าง = ปิดอัตโนมัติ · เก็บใน `daily_osp_schedule.json` · ค่าเริ่ม 06:00/18:00) — ทำใน repo เพื่อน (`c5d8893`) ขึ้น prod แล้ว · repo นี้ยังไม่มี
