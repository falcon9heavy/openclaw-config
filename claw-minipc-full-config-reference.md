# Claw Mini-PC — Full Configuration Reference & Backup Plan

> **Purpose:** Everything we changed on this box, every config file location, and how to back it all up before a reinstall so we can restore quickly.
> **Last updated:** April 2026

---

## 1. SYSTEM IDENTITY

| Item | Value |
|------|-------|
| OS | Ubuntu 24.04.4 LTS |
| Hostname | Ubuntu |
| User account | `user` (primary), `openclaw` (system user created by OpenClaw) |
| Static IP | `192.168.86.38` |
| Network interface | `enp2s0` (wired ethernet), MAC `0c:47:a9:60:49:2c` |
| WiFi interface | `wlp1s0` (disabled), MAC `a4:6b:40:d5:29:29` |
| Gateway/Router | `192.168.86.1` |
| DNS | `192.168.86.1`, `8.8.8.8`, `8.8.4.4` |

---

## 2. EVERY CONFIGURATION CHANGE WE MADE

### 2.1 SSH Hardening

**File:** `/etc/ssh/sshd_config`
```
PasswordAuthentication no
PermitRootLogin no
```

**SSH key:**
- Type: ed25519
- Public key installed at: `/home/user/.ssh/authorized_keys`
- Private key on Windows PC: `C:\Users\chris\.ssh\id_ed25519`
- Backup: password manager

**Service name:** `ssh` (not `sshd` on Ubuntu 24)

### 2.2 Firewall (UFW)

```
Status: active
Default: deny incoming, allow outgoing
Rules: port 22/tcp ALLOW
```

### 2.3 Fail2ban

- Installed via `sudo apt install fail2ban`
- Default config (protects SSH)

### 2.4 Unattended Upgrades (Auto Security Updates)

- Enabled via `sudo apt install unattended-upgrades`
- Default config for security patches

### 2.5 Static IP (Netplan — Ethernet)

**File:** `/etc/netplan/01-ethernet-static.yaml`
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp2s0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.86.38/24
      routes:
        - to: default
          via: 192.168.86.1
      nameservers:
        addresses:
          - 192.168.86.1
          - 8.8.8.8
          - 8.8.4.4
```

**Old WiFi netplan files were deleted** — the box is ethernet-only now.

### 2.6 WiFi Disabled

- `sudo nmcli radio wifi off`
- NetworkManager disabled: `sudo systemctl disable NetworkManager`
- systemd-networkd enabled: `sudo systemctl enable systemd-networkd`

**WiFi power save config (historical, no longer relevant with ethernet):**
- File: `/etc/NetworkManager/conf.d/wifi-powersave-off.conf`
- Content: `[connection]` / `wifi.powersave = 2`

### 2.7 Sleep/Suspend Disabled

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```
All four targets masked.

### 2.8 Credentials Directory Permissions

```bash
chmod 700 /home/user/.openclaw/credentials
```

---

## 3. OPENCLAW CONFIGURATION

### 3.1 Installation

- OpenClaw version at time of corruption: `2026.3.13`
- Gateway runs as user-level systemd service: `openclaw-gateway.service`
- Service file: `/home/user/.config/systemd/user/openclaw-gateway.service`
- Linked in `default.target.wants` (auto-starts on boot)
- Lingering enabled for `openclaw` user: `/var/lib/systemd/linger/openclaw`

### 3.2 Config File

**File:** `~/.openclaw/openclaw.json`

Last known working config:
```json
{
  "meta": {
    "lastTouchedVersion": "2026.3.13"
  },
  "auth": {
    "profiles": {
      "anthropic:default": {
        "provider": "anthropic",
        "mode": "api_key"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-haiku-4-5-20251001",
        "fallbacks": []
      },
      "models": {
        "anthropic/claude-haiku-4-5-20251001": {}
      },
      "workspace": "/home/user/.openclaw/workspace",
      "compaction": {
        "mode": "safeguard"
      },
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      },
      "heartbeat": {
        "every": "0m"
      }
    }
  },
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "botToken": "<RESTORE FROM PASSWORD MANAGER>",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "<RESTORE FROM PASSWORD MANAGER>"
    },
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    },
    "nodes": {
      "denyCommands": [
        "camera.snap",
        "camera.clip",
        "screen.record",
        "calendar.add",
        "contacts.add",
        "reminders.add"
      ]
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
```

**Key config lessons learned:**
- Heartbeat key is `agents.defaults.heartbeat.every` with value `"0m"` to disable
- `interval`, `enabled: false`, `heartbeat: false` are NOT valid keys
- Bedrock fallback models removed (no AWS credentials)
- Primary model set to Haiku for dev/testing (Opus for production)
- `openclaw doctor --fix` removes unrecognized keys

### 3.3 Workspace Files

**Location:** `~/.openclaw/workspace/`

Contents:
- `SOUL.md` — Higgens identity/persona
- `USER.md` — What Higgens knows about Chris
- `AGENTS.md` — Agent definitions
- `HEARTBEAT.md` — Empty (heartbeat disabled)
- `MEMORY.md` + `memory/` — File-based persistent memory
- `skills/portfolio-engine/` — Custom skill (see below)

### 3.4 Custom Skill: Portfolio Engine

**Location:** `~/.openclaw/workspace/skills/portfolio-engine/`

Files:
- `SKILL.md` — Skill definition and instructions
- `portfolio_engine.py` — Fetches live data via yfinance, generates report
- `holdings.json` — Position config (IRA + Roth, 24 positions)
- `latest_snapshot.json` — Auto-generated after each run

### 3.5 Credentials

**Location:** `~/.openclaw/credentials/`

Contains Anthropic API key. Stored in password manager — never committed to git.

### 3.6 Telegram Bot

- Bot name: Higgens
- Bot handle: `@MaresiasWaveBot`
- Bot token: stored in password manager (note: original had typo — letter `O` vs digit `0` in `AAG5E0QGf`)
- DM Policy: `pairing`

---

## 4. WHAT'S ON THE USB PEN DRIVE

Already backed up during initramfs recovery:
- `/home/user/.openclaw/` → `PENDRIVE/openclaw-backup/`
- `/home/user/.ssh/` → `PENDRIVE/ssh-backup/`

---

## 5. WHAT ELSE TO BACK UP BEFORE REINSTALL

If you can still mount the drive (from initramfs or a live USB), grab these additional files. If the filesystem is too corrupted, skip — we have enough to rebuild.

### 5.1 Commands to run (if accessible)

```bash
# Mount the root filesystem (if in initramfs)
mount /dev/sda2 /root    # adjust device as needed

# Copy additional config files to USB
mount /dev/sdb1 /usb     # USB pen drive

# SSH server config
cp /root/etc/ssh/sshd_config /usb/sshd_config.bak

# Netplan (if not already corrupted)
cp -r /root/etc/netplan/ /usb/netplan-backup/

# UFW rules
cp -r /root/etc/ufw/ /usb/ufw-backup/

# Fail2ban config
cp -r /root/etc/fail2ban/ /usb/fail2ban-backup/

# WiFi power save config (historical)
cp /root/etc/NetworkManager/conf.d/wifi-powersave-off.conf /usb/ 2>/dev/null

# Systemd user services
cp -r /root/home/user/.config/systemd/ /usb/systemd-user-backup/

# Unmount
umount /usb
```

### 5.2 What's safe to skip

- The OS itself (we're reinstalling fresh)
- `/home/user/.openclaw/` and `/home/user/.ssh/` (already on the pen drive)
- Any system packages (we'll reinstall)

---

## 6. REBUILD CHECKLIST (After Fresh Ubuntu 24.04 Install)

### Phase 1: OS & SSH (do this with monitor/keyboard attached)

```bash
# 1. Create user account during install (username: user)

# 2. Install SSH server
sudo apt update && sudo apt install -y openssh-server

# 3. Enable and start SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# 4. Restore SSH keys from pen drive
mkdir -p ~/.ssh
cp /media/user/PENDRIVE/ssh-backup/authorized_keys ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 5. Test SSH from Windows PC BEFORE hardening
# From PowerShell: ssh user@<NEW_IP>
# If that works, continue. If not, fix before proceeding.

# 6. Harden SSH
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 7. Test SSH again from a NEW window before closing the old one
```

### Phase 2: Network (still with monitor/keyboard)

```bash
# 1. Delete any default netplan configs
sudo rm /etc/netplan/*.yaml

# 2. Create static ethernet config
sudo tee /etc/netplan/01-ethernet-static.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp2s0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.86.38/24
      routes:
        - to: default
          via: 192.168.86.1
      nameservers:
        addresses:
          - 192.168.86.1
          - 8.8.8.8
          - 8.8.4.4
EOF

# 3. Disable WiFi
sudo nmcli radio wifi off
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd

# 4. Apply netplan
sudo netplan apply

# 5. Verify from Windows PC: ping 192.168.86.38
# 6. Verify SSH: ssh user@192.168.86.38
# If both work, continue. If not, fix before removing monitor.
```

### Phase 3: Security & Stability (can do via SSH now)

```bash
# Firewall
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable

# Fail2ban
sudo apt install -y fail2ban

# Auto updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Disable sleep/suspend
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### Phase 4: OpenClaw (via SSH)

```bash
# 1. Install OpenClaw (check docs.openclaw.ai for current install command)
# 2. Run openclaw config wizard — enter API key, select Haiku as primary model
# 3. Restore workspace from pen drive:
cp -r /media/user/PENDRIVE/openclaw-backup/workspace ~/.openclaw/workspace
# 4. Restore config (or reconfigure via wizard):
# Review the backed-up openclaw.json and re-enter tokens from password manager
# 5. Set heartbeat to disabled:
openclaw config set agents.defaults.heartbeat.every "0m"
# 6. Fix credentials permissions:
chmod 700 ~/.openclaw/credentials
# 7. Restart gateway:
openclaw gateway restart
# 8. Test Higgens on Telegram
```

### Phase 5: Remaining hardening

- [ ] BIOS: auto power-on after AC loss (requires reboot into BIOS)
- [ ] Router: DHCP reservation for 192.168.86.38
- [ ] Consider sshd watchdog service
- [ ] Consider network watchdog with auto-reboot failsafe

---

## 7. WINDOWS PC REFERENCE

| Item | Value |
|------|-------|
| IP | `192.168.86.33` |
| SSH key | `C:\Users\chris\.ssh\id_ed25519` |
| SSH key backup | Password manager |
| MobaXterm | `C:\Tools\MobaXterm` (portable) |
| MobaXterm key path | `/drives/c/Users/chris/.ssh/id_ed25519` |
| Git repo | `C:\Tools\openclaw-config` → `github.com/falcon9heavy/openclaw-config` |
| Dashboard tunnel | `ssh -L 18789:localhost:18789 user@192.168.86.38` |
| Dashboard URL | `http://localhost:18789` |
| Dashboard auth | Gateway token from password manager |

**MobaXterm gotcha:** MoTTY.exe can hold port 18789. Either close MobaXterm sessions or use alternate local port (e.g., 18790) for new tunnels.

**SSH key permissions fix (if needed):**
```powershell
takeown /f C:\Users\chris\.ssh\id_ed25519
icacls C:\Users\chris\.ssh\id_ed25519 /reset
icacls C:\Users\chris\.ssh\id_ed25519 /inheritance:r /grant:r "chris:F"
```

---

## 8. CREDENTIALS INVENTORY (All in Password Manager)

- [ ] SSH private key (`id_ed25519`)
- [ ] Anthropic API key
- [ ] Telegram bot token (`@MaresiasWaveBot`)
- [ ] OpenClaw gateway auth token
- [ ] WiFi password for "router-dev" (if ever needed again)
