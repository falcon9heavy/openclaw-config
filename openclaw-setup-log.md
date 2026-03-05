# OpenClaw Mini-PC Setup Log

## System Info
- **Device:** Ubuntu 24.04.4 LTS mini-PC (headless)
- **Current IP:** 192.168.86.38 (DHCP — needs static IP)
- **User:** user
- **SSH Key:** ed25519 (on Windows PC at C:\Users\chris\.ssh\id_ed25519)
- **OpenClaw Gateway Port:** 18789
- **OpenClaw Token:** (stored in ~/.openclaw/openclaw.json on mini-PC — do not commit)
- **Windows PC IP:** 192.168.86.33
- **Router:** 192.168.86.1 (Google Wifi/Nest)

---

## Session 1 — Feb 16, 2026

### Completed
- [x] Installed openssh-server, confirmed SSH access from Windows PC via MobaXterm
- [x] Enabled UFW firewall — default deny incoming, allow outgoing, port 22 open
- [x] Generated ed25519 SSH key pair on Windows PC
- [x] Copied public key to mini-PC ~/.ssh/authorized_keys
- [x] Set permissions: chmod 700 ~/.ssh, chmod 600 ~/.ssh/authorized_keys
- [x] Verified key-based SSH login
- [x] Installed fail2ban
- [x] Enabled unattended-upgrades (auto security updates)
- [x] OpenClaw gateway running, dashboard accessible via SSH tunnel

### Not confirmed / Unknown status
- [ ] Disable password authentication in sshd_config
- [ ] Disable root login in sshd_config
- [ ] Create dedicated openclaw user (still running as 'user')

---

## Session 2 — Mar 4, 2026

### Problem
- Mini-PC was found powered off (likely power outage + no auto-restart in BIOS)
- Powered it back on, but SSH connection timed out
- IP had changed from 192.168.86.23 → 192.168.86.38
- openssh-server was missing (possibly removed by auto-updates or some other event)

### Completed
- [x] Ran network ping sweep to find all devices on subnet
- [x] Tried SSH against all responding IPs — confirmed SSH was not running on any
- [x] Physically accessed mini-PC with keyboard + monitor
- [x] Confirmed new IP: 192.168.86.38
- [x] Reinstalled openssh-server: `sudo apt install openssh-server -y`
- [x] Enabled sshd: `sudo systemctl enable sshd`
- [x] Started sshd: `sudo systemctl start sshd`
- [x] Confirmed SSH connection from Windows PC

- [x] Set up MobaXterm saved session ("Claw Mini-PC") with SSH key auth
- [x] Set up local port forwarding tunnel (18789 → localhost:18789) in MobaXterm
- [x] Confirmed OpenClaw gateway is running — dashboard accessible at http://localhost:18789
- [x] Created openclaw-config git repo at C:\Tools\openclaw-config
- [x] Pushed initial setup log to GitHub (falcon9heavy/openclaw-config)

### Still TODO
- [ ] Set static IP (192.168.86.38) via netplan
- [ ] Set BIOS to auto power-on after AC power loss
- [ ] Disable sleep/suspend on Ubuntu
- [ ] Disable password authentication in sshd_config
- [ ] Disable root login in sshd_config
- [ ] Create dedicated openclaw user
- [ ] Verify OpenClaw gateway auto-starts on boot
- [ ] Connect Telegram bot
- [ ] Test chat through OpenClaw
- [ ] Consider UPS for power outage protection