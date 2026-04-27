# Session Log — April 27, 2026

## Summary
Diagnosed and fixed why Higgens stopped replying after April 9. Deployed network watchdog as first piece of self-healing infrastructure.

## Problem
Higgens unresponsive on Telegram. Last successful interaction: end of April 9 session (17 days prior).

## Root Cause
`loginctl show-user chrisa | grep Linger` returned `Linger=no`.

Without linger, the user's systemd instance only runs while a login session is active. When SSH session closed April 9, the gateway (running as systemd user service) died with the session. The "enabled" flag on the gateway service auto-starts it *with a user session*, not at boot.

Confirmed by SSH'ing in April 27 — gateway came up at 02:37:32 UTC, exactly when SSH connected. Box uptime was 17 days continuous; no reboots, no power events. The hardware was fine the whole time.

## Fix 1: Enable Linger

```bash
sudo loginctl enable-linger chrisa
loginctl show-user chrisa | grep Linger
# Linger=yes
```

User systemd instance now runs 24/7 independent of login sessions and starts at boot.

**Verified:** Disconnected SSH, waited 60s, messaged Higgens — replied immediately.

## Fix 2: Network Watchdog Deployed

Self-heal mechanism for network failures. Pings router every 60s; reboots after 5 consecutive failures.

### `/usr/local/bin/network-watchdog.sh`

```bash
#!/bin/bash
GATEWAY="192.168.86.1"
COUNTER_FILE="/var/run/network-watchdog.count"
LOG_FILE="/var/log/network-watchdog.log"
MAX_FAILURES=5

mkdir -p /var/run
[ -f "$COUNTER_FILE" ] || echo 0 > "$COUNTER_FILE"
COUNT=$(cat "$COUNTER_FILE")

if ping -c 1 -W 3 "$GATEWAY" > /dev/null 2>&1; then
    if [ "$COUNT" -gt 0 ]; then
        echo "$(date -Iseconds) recovered after $COUNT failures" >> "$LOG_FILE"
    fi
    echo 0 > "$COUNTER_FILE"
else
    COUNT=$((COUNT + 1))
    echo "$COUNT" > "$COUNTER_FILE"
    echo "$(date -Iseconds) ping failed (count=$COUNT/$MAX_FAILURES)" >> "$LOG_FILE"
    if [ "$COUNT" -ge "$MAX_FAILURES" ]; then
        echo "$(date -Iseconds) REBOOTING — $MAX_FAILURES consecutive failures" >> "$LOG_FILE"
        /sbin/reboot
    fi
fi
```

### `/etc/systemd/system/network-watchdog.service`

```ini
[Unit]
Description=Network watchdog — reboot if router unreachable
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/network-watchdog.sh
```

### `/etc/systemd/system/network-watchdog.timer`

```ini
[Unit]
Description=Run network watchdog every minute

[Timer]
OnBootSec=2min
OnUnitActiveSec=1min
Unit=network-watchdog.service

[Install]
WantedBy=timers.target
```

### Install & enable

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now network-watchdog.timer
```

**Verified:** Timer `active (waiting)`, firing every 60s. Counter `0`. Log empty (only failures logged).

## Lessons Learned

1. **Linger is non-negotiable for systemd user services on headless boxes.** Should have been enabled during Phase 4 — added to standing checklist.
2. **The gateway being "enabled" doesn't mean "starts at boot"** when running as a user service without linger. Easy to misread.
3. **17 days of false belief** — assumed Higgens was running fine; he was dead within hours of every session ending. Worth periodic external health checks once watchdogs are in place.

## State After Session

- Higgens: LIVE, will survive logouts and reboots
- Network watchdog: active, self-healing on connectivity loss
- Box uptime: 17 days, 2:31 (no reboots since rebuild)
- Pending: 34 apt updates including kernel (reboot deferred to BIOS session)

## Phase 5 Remaining

- Router DHCP reservation for `192.168.86.36`
- BIOS auto power-on after AC loss
- Reboot survival test (apply pending updates same session)
- Service-level watchdog for gateway crashes
