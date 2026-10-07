# Gotchas

## ห้ามรันด้วย gunicorn/multi-worker โดยไม่แก้โค้ดก่อน
`app.py` เก็บ state หลัก (`DATA`, `RAW_DATA`, `REMARKS`, `CONTACTS`, `DAILY_OSP_HISTORY`) เป็น
global variable ใน process เดียว และ background thread (`daily_osp_scheduler`, snapshot เวลา
06:00/18:00) เริ่มจากใน `if __name__ == "__main__":` ท้ายไฟล์ — gunicorn import โมดูลแบบ
`app:app` จะไม่รัน block นี้เลย (ไม่ auto-load Excel ตอน start, scheduler thread ไม่ขึ้น) และถ้า
รันหลาย worker แต่ละ worker จะมี state แยกกันคนละชุด (อัปโหลดผ่าน worker หนึ่งแต่ GET ไป worker อื่น
เห็นข้อมูลคนละอัน) → **deploy ด้วย `python3 app.py` ตรงๆ ผ่าน systemd เท่านั้น** (ดู
[runbooks/deploy.md](runbooks/deploy.md)) ถ้าจะเปลี่ยนไป gunicorn ต้องย้าย init code ออกจาก
`__main__` guard ก่อน และต้องบังคับ 1 worker เสมอ

## remarks.json / contacts.json / daily_osp_remain.json ต้อง gitignore
ไฟล์พวกนี้ถูก `app.py` เขียนทับตลอดเวลา (ทุกครั้งที่กด save remark/contact หรือ snapshot OSP) ถ้า
tracked ใน git, working tree บน server จะ dirty ตลอด แล้ว `git pull` รอบถัดไปจะ conflict/ถูก
บล็อก ต้อง gitignore ไว้แบบนี้ตลอดไป — ถ้าต้องย้ายข้อมูลเดิมขึ้น server ให้ `scp` ตรง ไม่ผ่าน git
(ขั้นตอนอยู่ใน runbooks/deploy.md)

## auto-deploy timer restart service ตอนมี commit ใหม่เท่านั้น แต่ไม่ใช่ zero-downtime
`osp-dashboard2-autodeploy.timer` เช็คทุก 5 นาที — ถ้าไม่มี commit ใหม่จะไม่แตะ service เลย แต่
ถ้ามี จะ `systemctl restart` ตรงๆ (ไม่ใช่ rolling/blue-green) ถ้าดันไปตรงจังหวะที่มีคนกำลังอัปโหลด
Excel พอดี request นั้นจะขาด (ไม่กี่วินาที) ความเสี่ยงต่ำเพราะเกิดเฉพาะตอน deploy จริง ไม่ใช่ทุกรอบ
poll — restart ปลอดภัยเพราะ `REMARKS`/`CONTACTS`/`DAILY_OSP_HISTORY` reload จากไฟล์ตอน start และ
Excel ล่าสุดใน `uploads/` ก็ auto-load ใหม่เหมือนเดิม (ดู `load_latest_excel_into_memory()`)

## /  route เคยคำนวณ home summary ใหม่ทุก request — แก้แล้วในสำเนานี้ (2026-10-07)
Lightsail CPU burst capacity ลดฮวบตอนมีคนเปิด dashboard พร้อมกัน เพราะ `index()` เรียก
`build_home_summary()` สดทุกครั้ง (มี `iterrows()` + regex parse datetime ทุก job + loop ทุกทีม
ใหม่) ซ้ำกับที่ `update_global_data()` คำนวณไปแล้วตอน upload แถม Flask dev server ไม่ได้ตั้ง
`threaded=True` เลยประมวลผลทีละ request เดียว — request หนักค้าง = ทุกคนที่เปิดพร้อมกันโดนคิว
ด้วย แก้แล้วโดย cache ผลลง global `HOME_SUMMARY` ตอน `update_global_data()` รันครั้งเดียว (ไม่ใช่
ทุก GET /) และเปิด `threaded=True` ให้ `app.run()` — **แก้ไว้ใน repo นี้เท่านั้น ยังไม่ได้ขึ้น
`parinyko/osp-dashboard2`** ต้องส่ง diff นี้ให้เพื่อนเอาไป apply เองถึงจะมีผลจริงบน prod

## deploy จริงมาจากคนละ repo — `deploy/` ที่นี่คือ ops เท่านั้น
Lightsail instance รัน **[parinyko/osp-dashboard2](https://github.com/parinyko/osp-dashboard2)**
(repo ของเพื่อน, `app.py` **เคย**เหมือน repo นี้ไบต์ต่อไบต์ ณ 2026-10-05 — ตอนนี้ไม่เหมือนแล้ว
เพราะแก้ perf fix ข้างบนไว้เฉพาะสำเนานี้) ไม่ใช่ `mylabjrp2001/ais-osp-dashboard`
repo เพื่อน **ไม่มี `.gitignore` เลย** — `contacts.json`/`remarks.json`/`daily_osp_remain.json`/
`uploads/*` ถูก commit ตรงๆ และโดนแอปเขียนทับตลอดเวลาเหมือนกัน แก้ด้วยการ `git stash push -u` ก่อน
`git pull` แล้ว `git stash pop` กลับ (อยู่ใน `deploy/update.sh` แล้ว) — **ห้ามวาง
`deploy/update.sh`/`deploy/osp-dashboard2.service` ไว้ใน `/srv/osp-dashboard2`** เพราะ `stash -u`
จะดึงไฟล์ untracked พวกนี้ไปด้วย ต้องวางไว้นอก repo (เช่น home dir) ตามที่ runbooks/deploy.md บอก

## ไม่มี auth ในแอปเลย
ทุก route เปิดให้ใครก็เข้าได้ ไม่มี login/password และ `contacts.json` มีชื่อ-เบอร์ติดต่อทีมจริง —
ห้ามเปิดพอร์ตแอปออกสู่ public โดยตรง (อย่าเปิด 5000 ใน Lightsail firewall) ให้เข้าผ่าน Cloudflare
Tunnel ที่ต่อแยกเท่านั้น ถ้าจะเปิดสาธารณะจริงต้องเพิ่ม basic auth ก่อน

## repo เป็น public — ชื่อพนักงานใน app.py เปิดเผยอยู่ (ยอมรับความเสี่ยงแล้ว 2026-10-05)
`TEAM_DATA` / `ASSIGN_ORDER` / `AREA_DATA` ใน `app.py` มีชื่อ-นามสกุลพนักงานจริงฝังเป็นโค้ด —
เจ้าของ repo ตัดสินใจเปิด public ทั้งที่รู้เรื่องนี้แล้ว **ห้าม commit secret/credential ใดๆ เข้า repo
นี้อีกต่อไป** (ต่างจากกฎ default "repo private → commit secret ได้หมด") — `SECRET_KEY` ต้องอยู่ใน
`.env` ที่ gitignore ไว้ สร้างแยกต่อ instance เท่านั้น (ดู runbooks/deploy.md)

## root-level `index.html` / `job_monitor.html` เป็นไฟล์เก่า ไม่ได้ใช้งาน
Flask `render_template()` อ่านจาก `templates/` เท่านั้น ไฟล์ชื่อซ้ำที่ root (และ
`osp-dashboard2-main.zip`, `latest_data.xlsx`) เป็น backup/legacy เก่า ไม่ได้ถูกอ้างถึงใน
`app.py` เลย — gitignore ไว้แล้ว ไม่ต้องย้ายขึ้น server
