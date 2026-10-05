# Deploy — AWS Lightsail (no Docker)

Deploy ของจริงมาจาก **[github.com/parinyko/osp-dashboard2](https://github.com/parinyko/osp-dashboard2)**
— repo ของเพื่อน ไม่ใช่ repo นี้ (`mylabjrp2001/ais-osp-dashboard`) เรามีไว้แค่เก็บ `deploy/` +
เอกสาร setup ช่วยเพื่อน โค้ดแอปตัวจริง (`app.py`) สองฝั่งเหมือนกันไบต์ต่อไบต์ (เช็คแล้ว 2026-10-05)
ดังนั้น gotcha เรื่อง gunicorn/global state/no-auth ที่สรุปไว้ใน [../gotchas.md](../gotchas.md)
ใช้กับ deploy นี้เหมือนกันทุกข้อ

ตัดสินใจแล้ว: **Lightsail Instance (VPS) ธรรมดา ไม่ใช้ Docker** เพราะโปรเจกต์นี้ใช้แค่ 1 instance
ต่อ 1 โปรเจกต์ — รันตรงด้วย `python3 app.py` ผ่าน systemd ง่ายกว่าและถูกกว่า gunicorn/Docker

โดเมน/HTTPS จัดการแยกด้วย Cloudflare Tunnel (เจ้าของทำเอง) — ไม่อยู่ใน scope ไฟล์นี้

## 1. สร้าง instance (ทำครั้งเดียว ผ่าน AWS Console)

- Lightsail → Create instance → **Linux/Unix → OS Only → Ubuntu 24.04 LTS**
- Plan: อย่างน้อย **$5/mo (1GB RAM)** — ถ้าอัปโหลด Excel ไฟล์ใหญ่/บ่อยให้ขึ้น $10 (2GB)
- ตั้ง static IP (ฟรีตราบใดที่ attach กับ instance ที่รันอยู่)
- Networking: ปล่อย default (เปิดแค่ SSH 22) — **ไม่ต้องเปิดพอร์ต 5000** เพราะ cloudflared
  ที่จะต่อทีหลังวิ่งบนเครื่องเดียวกัน ต่อ `localhost:5000` ได้โดยไม่ต้องเปิด firewall ขาเข้า

## 2. ติดตั้งครั้งแรก (SSH เข้า instance ด้วย user `ubuntu`)

```bash
sudo apt update && sudo apt install -y python3-venv python3-pip git

sudo mkdir -p /srv/osp-dashboard2
sudo chown ubuntu:ubuntu /srv/osp-dashboard2

git clone https://github.com/parinyko/osp-dashboard2.git /srv/osp-dashboard2
cd /srv/osp-dashboard2

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# SECRET_KEY ต้องสร้างต่อ instance เอง — repo ของเพื่อนไม่มี .gitignore เลย
# ห้ามสร้างไฟล์ secret ไว้ในโฟลเดอร์นี้แบบ track เข้า git โดยไม่ตั้งใจ
echo "SECRET_KEY=$(openssl rand -hex 32)" > .env

# clone มาแล้วมี contacts.json/remarks.json/daily_osp_remain.json/uploads/*
# ของเพื่อนติดมาด้วยเลย (เขา commit ไว้ตรงๆ ไม่ต้อง scp ย้ายข้อมูลเหมือน repo เรา)
```

**ไฟล์ deploy tooling ทั้ง 2 อยู่ใน repo นี้** (`ais-osp-dashboard/deploy/`) **ไม่ใช่ repo เพื่อน** — ต้อง
`scp` ขึ้น instance เอง และ **ห้ามวางไว้ใน `/srv/osp-dashboard2`** (จะโดน `git stash -u` ใน
update.sh ดึงเข้าไปด้วยทุกรอบ) วางแยกไว้คนละที่:

```bash
# รันจากเครื่อง dev (เครื่องนี้)
scp deploy/osp-dashboard2.service ubuntu@13.229.43.61:/tmp/
scp deploy/update.sh ubuntu@13.229.43.61:~/deploy-osp-dashboard2.sh

# กลับไป SSH session บน instance
sudo mv /tmp/osp-dashboard2.service /etc/systemd/system/
chmod +x ~/deploy-osp-dashboard2.sh

sudo systemctl daemon-reload
sudo systemctl enable --now osp-dashboard2

# เช็คว่าขึ้นจริง
curl -s http://127.0.0.1:5000/ | head -5
sudo systemctl status osp-dashboard2 --no-pager
```

repo เพื่อนเป็น public → `git clone` ไม่ต้องใช้ username/token เลย

## 3. Deploy อัปเดต (ทุกครั้งที่เพื่อน push โค้ดใหม่)

```bash
ssh ubuntu@13.229.43.61
bash ~/deploy-osp-dashboard2.sh
```

`update.sh` (scp ไว้ที่ `~/deploy-osp-dashboard2.sh` ตอน setup รอบแรก) ทำ: stash ไฟล์ data ที่ live
อยู่ → `git pull` → pop ไฟล์ data กลับมา → `pip install -r requirements.txt` → restart service —
ต้อง stash/pop เพราะ repo เพื่อน **ไม่มี `.gitignore`** ไฟล์ runtime (`contacts.json` ฯลฯ) เลย ถ้า
`git pull` ตรงๆ ตอน working tree dirty จะ fail (รายละเอียดใน gotchas.md)

## 4. Rollback

```bash
ssh ubuntu@13.229.43.61
cd /srv/osp-dashboard2
git log --oneline -5        # หา commit ก่อนหน้า
git checkout <commit-hash>
sudo systemctl restart osp-dashboard2
```
