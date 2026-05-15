# Ubuntu Server Kiosk Setup Guide (Rise Vision Player)

---

## Purpose

This document describes the full installation and configuration process for a Linux-based kiosk system using Ubuntu Server and Rise Vision Player.

The guide covers:

- Ubuntu Server installation
- BIOS/UEFI configuration
- SSH access
- Rise Player installation
- X server setup
- Kiosk auto-start configuration
- Monitor scheduling
- SSH hardening
- Windows SSH client configuration

---

## 0. Requirements

- Ubuntu Server USB (24.04 LTS recommended)
- Internet connection
- Monitor + keyboard (for initial setup)

---

## 1. Install Ubuntu Server

### Step 1 — Boot from USB

- Boot from USB (`F12`)
- Select: **Try or Install Ubuntu Server**

### Step 2 — Installation Configuration

During installation:

| Setting | Value |
|---|---|
| Language | English |
| Update | Perform update |
| Keyboard | English (US) – Done |
| Type of installation | Ubuntu Server (minimized) – Done |
| Network configuration | leave as is |
| Proxy configuration | empty |
| Ubuntu archive mirror | Done |
| Storage | Use entire disk, uncheck "Setup this disk as an LVM group" |

#### User Configuration

| Field | Value |
|---|---|
| Your name | Info Screen L1 (L0, L2, L3) |
| Server's name | `cn3XXX` |
| Username | `infoscreen` |
| Password | `1234` |

#### Additional Configuration

- **Upgrade to Ubuntu Pro:** Skip for now
- **SSH configuration:** Install OpenSSH server
- **Import key:** add later
- **Featured server snaps:** skip

---

## 2. BIOS / UEFI Configuration

### 2.1 Fix Boot Mode (if needed)

If you see **PXE / No Boot Device** errors:

**In BIOS:**
```
Boot Mode → UEFI
```

### 2.2 Fix Disk Invisibility Issue (if needed)

**In BIOS:**
```
Storage Configuration → SATA mode → change RAID to AHCI
```

---

## 3. SSH Configuration

### 3.1 Check SSH Status

```bash
sudo systemctl status ssh
```

### 3.2 Install SSH Server

```bash
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh
```

### 3.3 Connect from Windows

```bash
ssh infoscreen@<IP_ADDRESS>
```

---

## 4. Time Configuration

### Check Time Status

```bash
timedatectl status
```

### Configure Timezone

```bash
sudo timedatectl set-timezone Europe/Brussels
```

### Enable NTP Synchronization

```bash
sudo timedatectl set-ntp true
```

---

## 5. Install Rise Player

### Step 1 — Download Installer

```bash
wget https://storage.googleapis.com/install-versions.risevision.com/installer-lnx-64.sh
```

### Step 2 — Make Installer Executable

```bash
chmod +x installer-lnx-64.sh
```

### Step 3 — Run Installer

```bash
./installer-lnx-64.sh
```

---

## 6. Install Required Dependencies

If you encounter missing libraries, install:

```bash
sudo apt install -y \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libgtk-3-0 \
  libgbm1 \
  libasound2t64 \
  libx11-xcb1 \
  libnss3 \
  libxcomposite1 \
  libxdamage1 \
  libxrandr2 \
  libxkbcommon0 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libcairo2
```

---

## 7. Install Minimal X Server

```bash
sudo apt install --no-install-recommends xorg openbox xterm -y
```

---

## 8. Test X Server (Local Test)

### On the Physical Machine

```bash
startx
```

### Expected Result

- Black screen
- Mouse cursor
- Right click → Terminal

---

## 9. Test Rise Player

### Inside X Session Terminal

```bash
cd ~/rvplayer/scripts
./start.sh
```

### Expected Result

Activation window appears.

---

## 10. Install Nano Editor

```bash
sudo apt install nano
```

---

## 11. Enable Auto Login

### Step 1 — Create systemd Override Directory

```bash
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
```

### Step 2 — Create Override Configuration

```bash
sudo nano /etc/systemd/system/getty@tty1.service.d/override.conf
```

Paste:

```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin infoscreen #must_be_username# --noclear %I $TERM
```

Save: `Ctrl+O` → `Enter` → `Ctrl+X`

### Step 3 — Apply Changes

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
```

---

## 12. Auto-start X

### Edit bash_profile

```bash
nano ~/.bash_profile
```

Add:

```bash
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
```

Save: `Ctrl+O` → `Enter` → `Ctrl+X`

---

## 13. Kiosk Configuration (.xinitrc)

### Create Configuration File

```bash
nano ~/.xinitrc
```

Paste:

```sh
#!/bin/sh

unclutter -idle 2 -root &

openbox &

sleep 2

while true; do
  cd /home/infoscreen/rvplayer/scripts
  ./start.sh

  sleep 5
done
```

### Make File Executable

```bash
chmod +x ~/.xinitrc
```

---

## 14. Hide Cursor

```bash
sudo apt install unclutter -y
```

---

## 15. Reboot System

```bash
sudo reboot
```

### Final Result

After boot, the system automatically:

- logs in
- starts X
- launches openbox
- runs Rise Player

> Screen displays content immediately.

---

## 16. Enable Auto Power-On After Power Loss (BIOS/UEFI)

### Step 1 — Enter BIOS/UEFI

During boot, press: `F2` / `DEL` / `F12` *(depends on manufacturer)*

### Step 2 — Navigate to Power Settings

Look for a section such as:

- Power Management
- Advanced
- System Configuration

### Step 3 — Find the Setting

Locate one of the following options:

- Restore on AC Power Loss
- AC Power Recovery
- After Power Loss

### Step 4 — Set Value

```
Power On
```

### Step 5 — Save and Exit

`F10` → Yes

### Verification

1. Shut down the system completely
2. Disconnect power cable
3. Wait 5–10 seconds
4. Reconnect power

---

## 17. Schedule Monitor On/Off

### Time Synchronization

```bash
timedatectl status
timedatectl set-timezone Europe/Brussels
```

### Step 1 — Create Monitor OFF Service

```bash
sudo nano /etc/systemd/system/monitor-off.service
```

Paste:

```ini
[Unit]
Description=Turn monitor OFF

[Service]
Type=oneshot
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/infoscreen/.Xauthority
ExecStart=/usr/bin/xset dpms force off
```

### Step 2 — Create Monitor ON Service

```bash
sudo nano /etc/systemd/system/monitor-on.service
```

Paste:

```ini
[Unit]
Description=Turn monitor ON

[Service]
Type=oneshot
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/infoscreen/.Xauthority
ExecStart=/usr/bin/xset dpms force on
```

### Step 3 — Create OFF Timer

```bash
sudo nano /etc/systemd/system/monitor-off.timer
```

Paste:

```ini
[Unit]
Description=Turn monitor OFF at 20:00

[Timer]
OnCalendar=*-*-* 20:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### Step 4 — Create ON Timer

```bash
sudo nano /etc/systemd/system/monitor-on.timer
```

Paste:

```ini
[Unit]
Description=Turn monitor ON at 08:00

[Timer]
OnCalendar=*-*-* 08:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### Step 5 — Reload systemd

```bash
sudo systemctl daemon-reload
```

### Step 6 — Enable and Start Timers

```bash
sudo systemctl enable monitor-off.timer
sudo systemctl enable monitor-on.timer

sudo systemctl start monitor-off.timer
sudo systemctl start monitor-on.timer
```

### Verification

List active timers:

```bash
systemctl list-timers
```

---

## 18. Secure SSH Access

### Main Files

- `/etc/ssh/sshd_config`
- `/home/infoscreen/.ssh/authorized_keys`

### Recommended SSH Configuration

Edit SSH config:

```bash
sudo nano /etc/ssh/sshd_config
```

Ensure the following settings:

```
Include /etc/ssh/sshd_config.d/*.conf
PermitRootLogin no
PubkeyAuthentication yes
AuthenticationMethods publickey
PasswordAuthentication yes
AllowUsers infoscreen
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
# Allow client to pass locale environment variables
AcceptEnv LANG LC_*
# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server
```

### Enable SSH

```bash
systemctl status ssh
systemctl enable ssh
systemctl restart ssh
```

---

## Authorized Keys Configuration

### Create authorized_keys File

```bash
sudo nano /home/infoscreen/.ssh/authorized_keys
```

Paste (**entire text must be in 1 line!**):

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILd4nml7St8b1tY01NvrCO28jg/jZpl0KuEgySHwHLcA gforgas@iddqd
```

### Assign Permissions

```bash
sudo chown -R infoscreen:infoscreen /home/infoscreen/.ssh
sudo chmod 700 /home/infoscreen/.ssh
sudo chmod 600 /home/infoscreen/.ssh/authorized_keys
```

> **SSH permissions** refer to the access rights set on the SSH configuration files and directories:
> - The `~/.ssh` directory should have permissions set to `700` (read, write, and execute for the user only)
> - The private key files should have permissions set to `600` (read and write for the user only)

### Apply Changes

```bash
sudo systemctl restart ssh
```

---

## 19. Prepare Windows Client Machine for SSH connection

### Step 1 — Create SSH Folder

```powershell
mkdir $env:USERPROFILE\.ssh
```

### Step 2 — Save PRIVATE Key

```powershell
notepad $env:USERPROFILE\.ssh\id_ed25519_cmbinfoscreen
```

Paste:

```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

### Step 3 — Secure Permissions

```powershell
icacls $env:USERPROFILE\.ssh\id_ed25519_cmbinfoscreen /inheritance:r
icacls $env:USERPROFILE\.ssh\id_ed25519_cmbinfoscreen /grant:r "%USERNAME%:R"
```

---

## 20. SSH Config for Multiple Devices

### Create SSH Config File

```powershell
notepad $env:USERPROFILE\.ssh\config
```

### Example Configuration

```
Host infoscreen-l1 (according to the floor number)
    HostName 10.33.28.24
    User infoscreen
    IdentityFile ~/.ssh/id_ed25519_cmbinfoscreen
```

---

## 21. UPDATE YOUR PASSWORD

```bash
passwd
```
