# 2026-04-28 — Phase 5 COMPLETE: SSH lockdown, DHCP, UPS, kernel update, reboot survival verified

Goal for the session: complete Phase 5 (DHCP reservation, BIOS power-on,
reboot survival) and move on to OpenClaw feature work.

What actually happened: discovered SSH password auth was still enabled
(unplanned prerequisite fix), then completed Phase 5 in full. Orion is
now production-grade.

## 1. SSH password auth lockdown (unplanned)

When opening the night's first SSH session, MobaXterm prompted for a
password. Phase 1 was supposed to have disabled password auth — it
hadn't stuck.

### Root cause
`/etc/ssh/sshd_config.d/50-cloud-init.conf` contained:

    PasswordAuthentication yes

Drop-in files in `sshd_config.d/` load AFTER the main `sshd_config` and
override it. Phase 1 likely edited only the main config, so cloud-init's
drop-in kept re-enabling password auth on every sshd reload.

Secondary issue: MobaXterm's saved session profile wasn't pointed at the
ed25519 key, so it never offered key auth and fell through to password.

### Fix applied
1. Created new MobaXterm session with explicit private key path
   (`C:\Users\chris\.ssh\id_ed25519`) — verified key auth working
2. Overwrote `50-cloud-init.conf` via `tee`:

        echo "PasswordAuthentication no" | sudo tee \
            /etc/ssh/sshd_config.d/50-cloud-init.conf

   `sed -i` substitution silently failed first — file looked clean
   under `cat -A`, root cause not investigated. `tee` overwrite worked.
3. Verified effective config:

        sudo sshd -T | grep -iE "passwordauthentication|pubkeyauthentication"

   → `passwordauthentication no`, `pubkeyauthentication yes`
4. Restarted sshd: `sudo systemctl restart ssh`
5. Verified by opening a fresh session — key auth, no password prompt
6. Lockdown survived the cloud-init package upgrade later in the night
   (verified post-apt-upgrade)

## 2. DHCP reservation in Google Wifi

Orion didn't appear in the device list by hostname (likely because it's
behind a basement switch). Grabbed MAC from Orion:

    ip link show enp2s0
    → 0c:47:a9:60:49:2c  (Intel OUI prefix, expected for SOAYAN N150)

In Google Home app → Wi-Fi → Devices, found device by MAC, tapped "Pin"
next to its IP. Reservation now active for `192.168.86.36`.

Belt-and-suspenders networking achieved: netplan static IP at OS layer
+ DHCP reservation at router layer.

## 3. BIOS auto power-on — DEFERRED indefinitely (replaced by UPS)

Investigated whether AC-loss recovery could be set remotely. Conclusion:
the setting lives in BIOS firmware itself — ACPI is what the OS uses to
talk to BIOS, but the "what to do when AC comes back" decision is made
by BIOS before the OS boots. No Linux-side knob.

SOAYAN MN-N1 manuals don't document an AC-loss setting at all. Setting
it would require physical access (keyboard + monitor at POST), which is
forbidden by the standing zero-physical-access directive.

### Resolution
Chris purchased a UPS instead. UPS is strictly better than BIOS
auto-restart anyway:

- Keeps Orion *running* through outages (no unclean shutdown, no fsck,
  no recovery anxiety)
- BIOS auto-restart still requires the unit to crash first
- For brief power blips, UPS prevents the outage entirely

Phase 5 now treats power resilience as solved via UPS, with BIOS setting
formally deferred to a future physical visit (if ever needed).

## 4. Kernel update + reboot survival test

### Pre-flight baseline captured
- Kernel: `6.8.0-107-generic`
- Static IP: `192.168.86.36/24` ✓
- Linger: `Linger=yes` ✓
- network-watchdog.timer: active, enabled, running 1d 20h ✓
- openclaw-gateway.service: active, enabled, running 1d 20h ✓
- UFW: active, port 22/tcp only ✓
- Higgens responding on Telegram ✓

### Updates applied

    sudo apt update && sudo apt upgrade -y

41 packages upgraded including kernel `6.8.0-107` → `6.8.0-110`. Clean
install, no interactive prompts, no errors. SSH service restarted
mid-update without dropping the session (key auth lockdown verified
through a live sshd restart).

Verified SSH lockdown survived the cloud-init package upgrade before
rebooting — `50-cloud-init.conf` still contained `PasswordAuthentication
no`. Good.

### Reboot

    sudo reboot

Unit dark for ~90 seconds, came back cleanly on first SSH attempt.

### Recovery verification
- Uptime: 3 min (fresh boot) ✓
- New kernel running: `6.8.0-110-generic` ✓
- Static IP unchanged: `192.168.86.36` ✓
- Linger: `yes` ✓
- network-watchdog.timer: active, started at boot ✓
- openclaw-gateway.service: active, auto-started 6 sec after watchdog ✓
- UFW: active, port 22/tcp only ✓
- SSH lockdown: `passwordauthentication no`, `pubkeyauthentication yes` ✓
- 0 updates pending ✓
- Higgens responding on Telegram ✓

**Full reboot survival verified.**

## State at end of session

Orion is in a hardened, production-grade state:
- Zero-physical-access deployment
- SSH key-only auth (locked down + verified across reboots and config
  package upgrades)
- UFW firewall, fail2ban, unattended security updates
- Network watchdog auto-recovers from connectivity loss
- Static IP + DHCP reservation belt-and-suspenders
- OpenClaw v2026.4.8 gateway running as systemd user service with linger,
  auto-starts on boot, reboot survival verified
- UPS provides power resilience
- Higgens LIVE on Telegram (`@MaresiasWaveBot`)

Phases 1-5 all complete. Infrastructure work done.

## Lessons captured
- Drop-in files in `/etc/ssh/sshd_config.d/` override main `sshd_config`
  — always check both when hardening SSH (notes/ssh-config-gotchas.md)
- `sed -i` can fail silently in ways that aren't obvious from `cat -A`
  output — for short config files, `tee` is more reliable
- Existing SSH sessions survive sshd restarts AND apt upgrades that
  restart sshd — useful safety net during config changes
- Bracketed paste (`^[[200~`) breaks multi-line pastes in MobaXterm
  shells — paste single-line or save to a file and `bash file.sh`
- MobaXterm session profiles must explicitly point at the ed25519 key
  via "Use private key" under Advanced SSH settings
- BIOS AC-loss setting is genuinely BIOS-only on consumer mini-PCs —
  no remote way to set it. UPS solves the same problem better.

## Next session
Repo cleanup first (5 min): `git mv` to fix markdown-link-wrapped
filenames committed earlier tonight in `sessions/` and `notes/`.

Then: resume the investment agent requirements interview at Q5
(new position discovery, drop reactions, weekly rhythms). Portfolio
engine skill confirmed surviving the rebuild at
`~/.openclaw/workspace/skills/portfolio-engine/`.

OpenClaw v2026.4.26 is available (currently on v2026.4.8) — defer
update until requirements interview is complete.
