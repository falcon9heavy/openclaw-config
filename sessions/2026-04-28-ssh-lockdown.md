# 2026-04-28 — SSH password auth lockdown (unplanned Phase 5 prerequisite)

## Discovery
While prepping for Phase 5 (DHCP reservation, BIOS power-on, reboot
test), opened SSH session to Orion and got prompted for password.
Phase 1 was supposed to have disabled password auth — it hadn't stuck.

## Root cause
`/etc/ssh/sshd_config.d/50-cloud-init.conf` contained:

    PasswordAuthentication yes

Drop-in files in `sshd_config.d/` load AFTER the main `sshd_config`
and override it. Phase 1 likely edited the main config only, so
cloud-init's drop-in kept re-enabling password auth on every sshd
reload.

Additional finding: MobaXterm session profile wasn't pointed at the
ed25519 key, so it never offered key auth and fell through to
password. Once a new session was created with the key path
(`C:\Users\chris\.ssh\id_ed25519`), key auth worked first try.

## Fix applied
1. Created new MobaXterm session with explicit key path — verified
   key auth working
2. Overwrote `50-cloud-init.conf` with `PasswordAuthentication no`
   via `tee` (sed substitution silently failed — root cause unclear,
   file looked clean under `cat -A`, did not investigate further)
3. Verified effective config:

        sudo sshd -T | grep -iE "passwordauthentication|pubkeyauthentication"

   → `passwordauthentication no`, `pubkeyauthentication yes`
4. Restarted sshd: `sudo systemctl restart ssh`
5. Verified by opening a fresh session — key auth, no password prompt

## State at end of session
- 41 apt updates still pending (5 security, kernel included)
- Phase 5 still untouched: DHCP reservation, BIOS power-on,
  reboot survival test, gateway watchdog verification
- Higgens still live on Telegram

## Next session
Resume Phase 5. Start with DHCP reservation — need MAC from
`ip link show enp2s0` to match in Google Home (Orion not appearing
by hostname, likely because it's behind a basement switch).
