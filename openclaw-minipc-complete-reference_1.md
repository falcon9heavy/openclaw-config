# OpenClaw Mini-PC ("Orion") — Complete Project Reference

> Last updated: April 8, 2026
> This document captures every significant action, config change, lesson learned, and design decision across all sessions.

---

## 1. HARDWARE

| Item | Detail |
|------|--------|
| Device | SOAYAN MN-N1 mini-PC |
| CPU | Intel N150 (x86_64 / AMD64) |
| Storage | 475 GB SSD |
| Hostname | `Orion` |
| Nickname | "The mini-PC" / "Claw" |
| Network | Wired ethernet via 5-port unmanaged switch → wall ethernet port |
| Ethernet interface | `enp2s0` |
| WiFi interface | `wlp1s0` (permanently disabled) |
| BIOS | Supports Auto Power On after AC loss (not yet configured) |

---

## 2. TIMELINE & SESSION HISTORY

### Era 1: Initial Setup (Feb 16–Mar 6, 2026)

**Feb 16, 2026 — First boot & SSH**
- Installed Ubuntu 24.04 Desktop (original install, username: `user`)
- Installed openssh-server, confirmed SSH from Windows PC via MobaXterm
- Enabled UFW (port 22 only)
- Generated ed25519 SSH key pair on Windows PC
- Copied public key to mini-PC `~/.ssh/authorized_keys`
- Set permissions: `chmod 700 ~/.ssh`, `chmod 600 ~/.ssh/authorized_keys`

**Mar 4–5, 2026 — MobaXterm & Dashboard**
- Mini-PC IP had shifted to `192.168.86.38` (DHCP drift)
- Reinstalled openssh-server (had been removed somehow)
- Set up MobaXterm saved session with SSH key
- Configured SSH tunnel for OpenClaw dashboard (local port 18789 → remote 18789)
- Dashboard confirmed accessible at `http://localhost:18789`
- Created GitHub tracking repo: `github.com/falcon9heavy/openclaw-config`
- Learned: SSH tunnel = your Windows PC intercepts port 18789 traffic and pipes it through the encrypted SSH connection to the mini-PC

**Mar 6, 2026 — Static IP, sleep disable, SSH hardening, Telegram bot**
- Set static IP `192.168.86.38` via netplan (WiFi interface `wlp1s0`)
- Masked sleep/suspend/hibernate targets
- Disabled password authentication in sshd_config
- Disabled root login in sshd_config
- SSH key backed up to password manager
- OpenClaw gateway confirmed auto-starting on boot (user-level systemd service)
- Entered Anthropic API key via `openclaw config` wizard
- Model set to `anthropic/claude-opus-4-6`
- Fixed Telegram bot token typo (letter `O` vs digit `0` in `AAG5E0QGf`)
- Higgens (`@MaresiasWaveBot`) came online and responding

### Era 2: WiFi Reliability Crisis (Mar–Apr 2026)

- WiFi kept dropping after reboots despite all fixes
- Multiple cycles of: reboot → unreachable → physical access → fix → repeat
- WiFi power save disabled via NetworkManager config
- Still unreliable — WiFi permanently retired as a connection method
- Ordered 5-port unmanaged switch from Amazon
- Switch installed: both Windows PC and mini-PC hardwired to wall ethernet
- Switched netplan from WiFi (`wlp1s0`) to ethernet (`enp2s0`)

### Era 3: OpenClaw Configuration & Agent Design (Mar 16–20, 2026)

**Mar 16, 2026 — Heartbeat cost disaster**
- Discovered heartbeat feature fires every 30 min using primary model by default
- Primary model was Opus → 48+ expensive API calls/day silently
- Drained Anthropic credits, triggered 9-hour billing cooldown
- Multiple failed attempts at disabling: `enabled: false`, `interval: 0`, `heartbeat: false` — all invalid
- Correct fix: `openclaw config set agents.defaults.heartbeat.every "0m"`
- Switched primary model to Haiku for dev/testing (~30x cheaper than Opus)
- Removed useless Bedrock fallback models (no AWS credentials)
- Fixed credentials directory permissions: `chmod 700 ~/.openclaw/credentials`
- Lesson: check docs before guessing at config keys

**Mar 16, 2026 — Investment agent brainstorm**
- Established core principle: define user scenarios first, then extract agent architecture
- Reframed agents around jobs (not build phases): Portfolio, Watchdog, Analyst, Strategist
- Started interview-style requirements gathering (Q1–Q4 completed)
- Created `investment-agent-requirements.md` as living requirements doc in GitHub

**Mar 20, 2026 — OpenClaw orientation, portfolio engine deployed**
- Updated OpenClaw from 2026.2.13 to 2026.3.13
- Deep orientation on OpenClaw's "OS" architecture:
  - Gateway = kernel (always running, routes messages)
  - Channels (Telegram) = I/O devices
  - Skills = installed software
  - Cron jobs = scheduled tasks
  - Sub-agents = child processes
  - Workspace = agent's home directory with file-based memory
- Reviewed workspace files: SOUL.md, IDENTITY.md, AGENTS.md, TOOLS.md, HEARTBEAT.md, MEMORY.md
- Deployed portfolio engine skill to mini-PC:
  - `portfolio_engine.py` — fetches live data via yfinance
  - `holdings.json` — position config (IRA + Roth, 24 positions)
  - `SKILL.md` — skill definition
- Live data confirmed working
- IGV price anomaly flagged ($84.46, -90% loss) — needs brokerage verification
- Windows SSH key permissions fixed for scp

**GTC 2026 / Jensen Huang keynote (March 16)**
- Jensen featured OpenClaw, called it "the operating system for personal AI"
- Nvidia announced NemoClaw: enterprise security layer on top of OpenClaw

### Era 4: Filesystem Corruption & Rebuild (Apr 2026)

**~Apr 2, 2026 — Filesystem corruption discovered**
- Mini-PC booted into initramfs — OS unreadable
- Filesystem corruption confirmed; could not be repaired
- Backed up `.openclaw/` and `.ssh/` to USB pen drive from initramfs:
  ```
  mkdir /usb
  mount /dev/sdb1 /usb
  cp -r /root/home/user/.openclaw /usb/openclaw-backup
  cp -r /root/home/user/.ssh /usb/ssh-backup
  umount /usb
  ```
- Created comprehensive config reference doc and committed to GitHub
- Pen drive backups copied to Windows PC: `C:\Tools\minipc-backup\`

**~Apr 4–5, 2026 — Fresh Ubuntu Server reinstall**
- Downloaded Ubuntu Server 24.04 LTS (AMD64)
- Flashed pen drive with Rufus (accepted GRUB 2.14 update)
- Installed Ubuntu Server 24.04 LTS:
  - Username: `chrisa` (NOT the old `user`)
  - Hostname: `Orion`
  - OpenSSH server installed during setup
  - No snaps selected
  - Full disk guided storage (475 GB SSD)
  - WiFi interface disabled during install
- SSH confirmed working from Windows PC
- SSH hardened: password auth disabled, root login disabled
- SSH key backed up to password manager (same key as before)
- Set static IP to `192.168.86.36` via netplan on `enp2s0`
  - Originally assigned `.38` but that IP is occupied by another device (different MAC)
  - Lesson: always verify IP is free via `arp -a` or ping BEFORE assigning
  - Cost ~20 minutes debugging before discovering `.38` was taken
- Netplan permissions warning received (need `chmod 600`)

---

## 3. CURRENT STATE (as of April 8, 2026)

| Component | Status |
|---|---|
| OS | Ubuntu Server 24.04 LTS (fresh install) |
| Hostname | `Orion` |
| Username | `chrisa` |
| IP | `192.168.86.36` (static, wired ethernet `enp2s0`) |
| SSH | Key-only auth, password disabled, root login disabled |
| Netplan | `/etc/netplan/01-ethernet-static.yaml` (permissions need `chmod 600`) |
| WiFi | Disabled during install |
| UFW | **NOT YET INSTALLED** |
| Fail2ban | **NOT YET INSTALLED** |
| Auto-updates | **NOT YET INSTALLED** |
| Sleep/suspend | **NOT YET MASKED** |
| OpenClaw | **NOT YET INSTALLED** |
| Higgens (Telegram) | **OFFLINE** until OpenClaw is reinstalled |

---

## 4. REBUILD CHECKLIST — REMAINING WORK

### Phase 2: Network Cleanup (next up)
- [ ] Fix netplan permissions: `sudo chmod 600 /etc/netplan/01-ethernet-static.yaml`
- [ ] Disable WiFi entirely (may already be disabled from install):
  ```bash
  sudo nmcli radio wifi off 2>/dev/null
  sudo systemctl disable NetworkManager 2>/dev/null
  sudo systemctl stop NetworkManager 2>/dev/null
  ```
- [ ] Confirm `systemd-networkd` is active:
  ```bash
  sudo systemctl enable systemd-networkd
  sudo systemctl start systemd-networkd
  ```
- [ ] Verify SSH still works after changes

### Phase 3: Security & Stability
- [ ] Install UFW: `sudo apt install -y ufw`
- [ ] Configure UFW: deny incoming, allow outgoing, allow 22/tcp, enable
- [ ] Install fail2ban: `sudo apt install -y fail2ban`
- [ ] Install unattended-upgrades: `sudo apt install -y unattended-upgrades`
- [ ] Configure auto-updates: `sudo dpkg-reconfigure -plow unattended-upgrades`
- [ ] Mask sleep targets:
  ```bash
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
  ```

### Phase 4: OpenClaw
- [ ] Install OpenClaw (check docs.openclaw.ai for current install command)
- [ ] Run `openclaw config` wizard — enter API key, select Haiku as primary model
- [ ] Restore workspace from pen drive backup:
  ```bash
  cp -r /media/chrisa/PENDRIVE/openclaw-backup/workspace ~/.openclaw/workspace
  ```
- [ ] Re-enter credentials from password manager (bot token, gateway token)
- [ ] Disable heartbeat: `openclaw config set agents.defaults.heartbeat.every "0m"`
- [ ] Fix credentials permissions: `chmod 700 ~/.openclaw/credentials`
- [ ] Restart gateway: `openclaw gateway restart`
- [ ] Test Higgens on Telegram

### Phase 5: Final Hardening
- [ ] Router DHCP reservation for `192.168.86.36`
- [ ] BIOS auto power-on after AC loss (requires reboot into BIOS)
- [ ] Verify OpenClaw auto-starts on boot (reboot test)
- [ ] Consider sshd watchdog service
- [ ] Consider network watchdog with auto-reboot failsafe

### Phase 6: Resume Project Work (blocked until above complete)
- [ ] Verify portfolio engine skill works with live data
- [ ] Check IGV price anomaly against brokerage
- [ ] Resume investment agent requirements interview (Q5+)
- [ ] Build next skills: market-news, thesis-tracker, watchdog cron
- [ ] Set up first cron job (daily portfolio snapshot)

---

## 5. OPENCLAW CONFIGURATION REFERENCE

### 5.1 Last Known Working Config (from corrupted install)

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-haiku-4-5-20251001"
      },
      "workspace": "/home/chrisa/.openclaw/workspace",
      "compaction": { "mode": "safeguard" },
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 },
      "heartbeat": { "every": "0m" }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "botToken": "<from password manager>",
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
      "token": "<from password manager>"
    }
  }
}
```

### 5.2 Config Key Reference

| Key | Valid Values | Notes |
|-----|-------------|-------|
| `agents.defaults.model.primary` | `"anthropic/claude-haiku-4-5-20251001"` (dev), `"anthropic/claude-opus-4-6"` (prod) | |
| `agents.defaults.heartbeat.every` | `"0m"` to disable, `"30m"` default | Only `every` with `"0m"` works; `enabled: false`, `interval: 0` are invalid |
| `channels.telegram.botToken` | String | Watch for letter O vs digit 0 typo |
| `channels.telegram.dmPolicy` | `"pairing"` | |
| `gateway.bind` | `"loopback"` | Keep loopback; access via SSH tunnel only |

### 5.3 Useful Commands

```bash
# Check gateway status
openclaw status

# Restart gateway
openclaw gateway restart

# Fix config issues
openclaw doctor --fix

# Validate JSON config
python3 -c "import json; json.load(open('/home/chrisa/.openclaw/openclaw.json')); print('Valid JSON')"

# Overwrite corrupted config
cat > ~/.openclaw/openclaw.json << 'EOF'
{ ... }
EOF
```

### 5.4 Workspace Files

Location: `~/.openclaw/workspace/`

| File | Purpose |
|------|---------|
| `SOUL.md` | Higgens identity/persona (British special agent, dry wit) |
| `USER.md` | What Higgens knows about Chris |
| `IDENTITY.md` | Name, vibe, emoji |
| `AGENTS.md` | Operating manual (memory system, safety rules, heartbeat, group chat) |
| `TOOLS.md` | Environment-specific notes (hardware, SSH, etc.) |
| `HEARTBEAT.md` | Empty (heartbeat disabled) |
| `MEMORY.md` + `memory/` | File-based persistent memory |
| `skills/portfolio-engine/` | Custom skill (see below) |

### 5.5 Portfolio Engine Skill

Location: `~/.openclaw/workspace/skills/portfolio-engine/`

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition and instructions for Higgens |
| `portfolio_engine.py` | Fetches live data via yfinance, generates report |
| `holdings.json` | Position config (IRA + Roth, 24 positions) |
| `latest_snapshot.json` | Auto-generated after each run |

Data source: Yahoo Finance (syncs daily with Schwab brokerage)

---

## 6. WINDOWS PC REFERENCE

| Item | Value |
|------|-------|
| IP | `192.168.86.33` |
| SSH key | `C:\Users\chris\.ssh\id_ed25519` |
| SSH key backup | Password manager |
| MobaXterm | `C:\Tools\MobaXterm` (portable) |
| MobaXterm key path | `/drives/c/Users/chris/.ssh/id_ed25519` |
| Git repo | `C:\Tools\openclaw-config` → `github.com/falcon9heavy/openclaw-config` |
| Backup location | `C:\Tools\minipc-backup\` (pen drive contents) |
| Dashboard tunnel | `ssh -L 18789:localhost:18789 chrisa@192.168.86.36` |
| Dashboard URL | `http://localhost:18789` |

**MobaXterm gotcha:** MoTTY.exe can hold port 18789. Either close sessions or use alternate local port (e.g., 18790).

**SSH key permissions fix (if needed):**
```powershell
takeown /f C:\Users\chris\.ssh\id_ed25519
icacls C:\Users\chris\.ssh\id_ed25519 /reset
icacls C:\Users\chris\.ssh\id_ed25519 /inheritance:r /grant:r "chris:F"
```

---

## 7. CREDENTIALS INVENTORY (All in Password Manager)

- [ ] SSH private key (`id_ed25519`)
- [ ] Anthropic API key
- [ ] Telegram bot token (`@MaresiasWaveBot`) — watch for O vs 0 typo
- [ ] OpenClaw gateway auth token

---

## 8. INVESTMENT AGENT SYSTEM (Blocked Until Rebuild Complete)

### 8.1 Agent Architecture

| Agent | Job | Does | Does Not |
|-------|-----|------|----------|
| Portfolio Agent | Source of truth for holdings, prices, P&L, allocations | Provide data | Make decisions |
| Watchdog Agent | Monitor for events (earnings, price swings, news) | Notice things, raise flags | Analyze |
| Analyst Agent | Deep research on specific tickers (on demand) | Fundamentals, peer comparison, thesis evaluation | Act autonomously |
| Strategist Agent | Portfolio-level thinking (allocation, rebalancing) | Recommend based on current exposure + conviction | Trade |

### 8.2 Requirements Interview Status

- Q1-Q2: Daily routine & frustrations — **DONE**
- Q3-Q4: Thesis tracking & allocation approach — **DONE**
- Q5+: New position discovery, drop reactions, weekly rhythms — **PENDING**

### 8.3 Scenario Backlog (from requirements doc)

- Monday morning summary (what moved, what to watch)
- Significant intraday drop response (why, thesis check, exposure)
- Cash deployment recommendation
- Earnings season calendar + pre-earnings briefs
- Smart money tracking
- New position discovery workflow
- Thesis creation & storage
- Rebalancing nudges (allocation drift)
- Weekend/weekly portfolio health check

### 8.4 Design Principles

- Define user scenarios first, then extract agent architecture
- Track conviction vs. actual sizing; flag mismatches
- Agent provides context around moves: news → thesis → allocation → action
- Infrastructure stability before features — always

---

## 9. KEY LESSONS LEARNED

1. **SSH reliability above all else.** Zero-physical-access deployment. If SSH is lost, the unit is bricked. Every config change must prioritize keeping SSH accessible.
2. **Never suggest physical access.** All troubleshooting must be doable remotely. Every config change needs fallback planning.
3. **Verify before assigning.** Always confirm an IP is free via `arp -a` or ping before assigning static. Skipping this cost 20 minutes.
4. **Check docs before guessing config keys.** OpenClaw's `openclaw config set` requires exact schema paths. No CLI discovery mechanism. Search documentation immediately on any "Unrecognized key" error.
5. **Heartbeat burns credits silently.** Fires every 30 min using primary model by default. Disable with `agents.defaults.heartbeat.every "0m"`.
6. **WiFi is permanently retired.** Wired ethernet only. WiFi was the root cause of most outages.
7. **Infrastructure stability before features.** Rock-solid foundation first.
8. **Work in 30-minute sessions.** Explicit verification steps before proceeding. Don't rush.
