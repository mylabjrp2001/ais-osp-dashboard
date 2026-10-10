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

## prod ยังรันโค้ดจาก repo เพื่อน และมีไฟล์พังค้างบนดิสก์ (พบ 2026-10-10 · เจ้าของสั่งยังไม่แก้ prod)
timer บนเครื่อง prod ดึง `parinyko/osp-dashboard2` ทุก 5 นาที เพื่อน push `app.py` ที่ย่อหน้าหาย
(ก๊อปวางผิด) 2 ครั้งเมื่อ 9 ต.ค.: `1c4c35b` 15:54 → container restart วน 18 รอบ **เว็บล่ม ~15:57–16:06**
· `2ea8a00` 16:02 ใช้ได้ → กลับมา · `2765348` 16:08 พังอีก → ถูกดึงลงดิสก์แต่ container ไม่ restart
จึงยังรัน `2ea8a00` ในหน่วยความจำ **restart ครั้งหน้า (รีบูต/crash) = ล่มทันที** จนกว่าจะถอยไฟล์บนดิสก์
หรือสลับมาดึง repo นี้ · timer มี bug ของเราเองด้วย: แก้แค่ `app.py` ไม่ restart container (โค้ดใหม่ไม่ขึ้น)
และไม่เช็คว่า parse ได้ก่อน deploy — ตอนสลับมาใช้ repo นี้ต้องแก้ทั้งสองข้อ (ดูรายละเอียดใน private ops docs)

## home summary cache 60 วินาที — อย่า cache จนถึง upload ครั้งหน้า
`index()` เคยเรียก `build_home_summary()` สดทุก request (มี `iterrows()` + parse วันที่ทุก job) และ
dev server รับทีละ request → คนเปิดพร้อมกันโดนคิว CPU บน Lightsail พุ่ง · แก้: `cached_home_summary()`
เก็บผล `HOME_SUMMARY_TTL` = 60 วิ + `invalidate_home_summary()` ตอน upload / save remark / save contact
และ `threaded=True` · **ห้ามขยายเป็น cache ถาวรจนถึง upload ครั้งหน้า** (รุ่นแรกที่เราทำ 2026-10-07 เป็นแบบนั้น
และผิด) เพราะสรุปขึ้นกับ remark ("ลา" → ทีมขาด) และเวลาปัจจุบัน ("Available on HH:MM" → ทีมเลิกดึก,
aging Today/<3 วัน)

## production ย้ายออกจาก Lightsail แล้ว (2026-10-07) — รายละเอียดอยู่ใน private ops docs
CPU บน Lightsail พุ่งค้างบ่อย (burst credit หมด) + เสียค่าเครื่องรายเดือนโดยไม่จำเป็น เลยย้ายไปรันบน
เครื่อง internal แทน ที่นั่น isolate เป็น container แยก จำกัด cpus/memory ไม่ให้กระทบระบบอื่นที่แชร์
เครื่อง และตั้ง auto-deploy timer แบบเดียวกับที่ทำไว้ที่นี่ — **รายละเอียด/credential ของเครื่องนั้นไม่
เก็บใน repo นี้เพราะ public** ดูได้จาก private ops docs เท่านั้น (ถามเจ้าของ repo นี้โดยตรง)
`deploy/` + `runbooks/deploy.md` ที่เหลือในนี้คือของ Lightsail เดิม เก็บไว้เป็น reference/rollback

## repo เพื่อน (prod ยังดึงอยู่) ไม่มี .gitignore — ประวัติสมัย Lightsail
ตั้งแต่ 2026-10-10 repo นี้เป็น source หลัก (ดึง `2ea8a00` ของเพื่อนมา + perf fix + เมนู Monthly Report)
แต่ prod ยังดึง **[parinyko/osp-dashboard2](https://github.com/parinyko/osp-dashboard2)** จนกว่าจะสลับ
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
