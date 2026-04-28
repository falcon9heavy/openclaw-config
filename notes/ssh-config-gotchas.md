# SSH config gotchas on Ubuntu 24.04

## Drop-in files override main sshd_config
`/etc/ssh/sshd_config.d/*.conf` loads AFTER `/etc/ssh/sshd_config`
and overrides it. Editing the main config is not enough.

Default Ubuntu cloud-init image ships with:

    /etc/ssh/sshd_config.d/50-cloud-init.conf

containing `PasswordAuthentication yes` — this re-enables password
auth even if the main config disables it.

## When hardening SSH, always check

    ls /etc/ssh/sshd_config.d/
    sudo grep -rE "PasswordAuthentication|PubkeyAuthentication" \
        /etc/ssh/sshd_config /etc/ssh/sshd_config.d/

## Effective config (not just file contents)

    sudo sshd -T | grep -iE "passwordauthentication|pubkeyauthentication"

This shows what sshd will actually use, accounting for all drop-ins.

## Editing drop-ins
`sed -i` substitution can fail silently for reasons that aren't
obvious. If the file is short, just overwrite it with `tee`:

    echo "PasswordAuthentication no" | sudo tee \
        /etc/ssh/sshd_config.d/50-cloud-init.conf

## Existing SSH sessions survive sshd restarts
Restarting sshd does NOT kill existing connections — they stay alive
on their original socket. Always keep at least one extra session open
when changing SSH config so you have a backup window if a new
connection fails.

## MobaXterm session profile must explicitly point at the key
If your saved session doesn't have **Use private key** checked under
**Advanced SSH settings** with the path to your ed25519 key, MobaXterm
will fall through to password auth even if key auth would work.

Key path on Apollo (Windows PC):

    C:\Users\chris\.ssh\id_ed25519

In MobaXterm's file browser this shows as:

    /drives/c/Users/chris/.ssh/id_ed25519
