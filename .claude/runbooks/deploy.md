# Deploy — AWS Lightsail (no Docker)

ตัดสินใจแล้ว: **Lightsail Instance (VPS) ธรรมดา ไม่ใช้ Docker** เพราะโปรเจกต์นี้ใช้แค่ 1 instance
ต่อ 1 โปรเจกต์ และแอป rely on global in-memory state + background thread เดียว
(ดู [../gotchas.md](../gotchas.md)) — รันตรงด้วย `python3 app.py` ผ่าน systemd ง่ายกว่าและถูกกว่า gunicorn/Docker

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

sudo mkdir -p /srv/ais-osp-dashboard
sudo chown ubuntu:ubuntu /srv/ais-osp-dashboard

git clone https://github.com/mylabjrp2001/ais-osp-dashboard.git /srv/ais-osp-dashboard
cd /srv/ais-osp-dashboard

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# SECRET_KEY ต้องสร้างต่อ instance เอง — ห้ามใส่ใน git (repo นี้เป็น public)
echo "SECRET_KEY=$(openssl rand -hex 32)" > .env

sudo cp deploy/ais-osp-dashboard.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ais-osp-dashboard

# เช็คว่าขึ้นจริง
curl -s http://127.0.0.1:5000/ | head -5
sudo systemctl status ais-osp-dashboard --no-pager
```

repo เป็น **public** → `git clone` ไม่ต้องใช้ username/token เลย

### ย้ายข้อมูลเดิม (ถ้าต้องการ) — ทำครั้งเดียว ไม่ผ่าน git

`contacts.json` / `remarks.json` / `daily_osp_remain.json` ถูก gitignore ไว้ (ดู gotchas.md)
clone ใหม่จะเริ่มจากข้อมูลเปล่า ถ้าอยากยกข้อมูล remark/contact ปัจจุบันขึ้นไปด้วย:

```bash
# รันจากเครื่อง dev (เครื่องนี้)
scp contacts.json remarks.json daily_osp_remain.json ubuntu@<LIGHTSAIL_IP>:/srv/ais-osp-dashboard/
ssh ubuntu@<LIGHTSAIL_IP> "sudo systemctl restart ais-osp-dashboard"
```

## 3. Deploy อัปเดต (ทุกครั้งที่แก้โค้ด)

```bash
# เครื่อง dev
git push

# SSH เข้า Lightsail แล้วรัน
bash /srv/ais-osp-dashboard/deploy/update.sh
```

`update.sh` = `git pull` + `pip install -r requirements.txt` + `systemctl restart`

## 4. Rollback

```bash
ssh ubuntu@<LIGHTSAIL_IP>
cd /srv/ais-osp-dashboard
git log --oneline -5        # หา commit ก่อนหน้า
git checkout <commit-hash>
sudo systemctl restart ais-osp-dashboard
```
