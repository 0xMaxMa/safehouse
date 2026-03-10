#!/bin/bash
set -e

# Use environment variables with defaults
DEV_USER=${DEV_USER:-dev}
SSH_PORT=${SSH_PORT:-2222}
CODE_SERVER_PORT=${CODE_SERVER_PORT:-8080}
CODE_SERVER_PASSWORD=${CODE_SERVER_PASSWORD:-changeme}

echo "🚀 Starting dev server container..."

# Propagate container env vars to login shells (SSH sessions)
[ -n "$DOCKER_HOST" ] && echo "DOCKER_HOST=$DOCKER_HOST" >> /etc/environment

# SSH
mkdir -p /var/run/sshd
echo "${DEV_USER}:${CODE_SERVER_PASSWORD}" | chpasswd
service ssh start
echo "✅ SSH ready — port 22 (mapped to ${SSH_PORT} on host)"

# Fix ownership of volume-mounted home dir
chmod 755 /home/${DEV_USER}
chown ${DEV_USER}:${DEV_USER} /home/${DEV_USER}
for dir in .claude .config .local .docker .ssh .openclaw-ssh; do
    chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/${dir} 2>/dev/null || true
done

# Symlink tmux config if present
TMUX_CONF=/home/${DEV_USER}/.config/tmux/.tmux.conf
TMUX_LINK=/home/${DEV_USER}/.tmux.conf
if [ -f "$TMUX_CONF" ] && [ ! -L "$TMUX_LINK" ]; then
    ln -sf "$TMUX_CONF" "$TMUX_LINK"
    chown -h ${DEV_USER}:${DEV_USER} "$TMUX_LINK"
fi

# Seed .bashrc if not present on volume (first run)
BASHRC=/home/${DEV_USER}/.bashrc
[ ! -f "$BASHRC" ] && cp /etc/safehouse-bashrc "$BASHRC" && chown ${DEV_USER}:${DEV_USER} "$BASHRC"

# Ensure .bash_profile sources .bashrc (SSH login shells don't load .bashrc directly)
BASH_PROFILE=/home/${DEV_USER}/.bash_profile
if [ ! -f "$BASH_PROFILE" ]; then
    echo '[ -f ~/.bashrc ] && . ~/.bashrc' > "$BASH_PROFILE"
    chown ${DEV_USER}:${DEV_USER} "$BASH_PROFILE"
fi

# Ensure code-server config exists (volume mount wipes Dockerfile COPY)
CODE_SERVER_CONFIG=/home/${DEV_USER}/.config/code-server/config.yaml
mkdir -p "$(dirname $CODE_SERVER_CONFIG)"
[ ! -f "$CODE_SERVER_CONFIG" ] && cp /etc/code-server-config.yaml "$CODE_SERVER_CONFIG"
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.config/code-server

# Ensure projects dir exists in home
mkdir -p /home/${DEV_USER}/projects
chown ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/projects

# code-server (iPad / browser)
echo "✅ code-server ready — port ${CODE_SERVER_PORT}"
su - ${DEV_USER} -c "PASSWORD='${CODE_SERVER_PASSWORD}' code-server --config ${CODE_SERVER_CONFIG}" &

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VS Code Desktop → Remote-SSH"
echo "  Host: YOUR_SERVER_IP  Port: ${SSH_PORT}  User: ${DEV_USER}"
echo ""
echo "  iPad / Browser → http://YOUR_SERVER_IP:${CODE_SERVER_PORT}"
echo "  Password: ${CODE_SERVER_PASSWORD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# === Claude Code: auto-generate SSH key for openclaw (first run) ===
OPENCLAW_SSH_DIR="/home/${DEV_USER}/.openclaw-ssh"
OPENCLAW_KEY="$OPENCLAW_SSH_DIR/id_ed25519"
AUTH_KEYS="/home/${DEV_USER}/.ssh/authorized_keys"

if [ ! -f "$OPENCLAW_KEY" ]; then
    mkdir -p "$OPENCLAW_SSH_DIR"
    chown -R ${DEV_USER}:${DEV_USER} "$OPENCLAW_SSH_DIR"

    su - ${DEV_USER} -c "ssh-keygen -t ed25519 -f $OPENCLAW_KEY -N '' -C 'openclaw-gateway'"
    echo "✅ SSH key generated for openclaw"

    # Register public key into authorized_keys
    mkdir -p /home/${DEV_USER}/.ssh
    chmod 700 /home/${DEV_USER}/.ssh
    grep -qF "$(cat ${OPENCLAW_KEY}.pub)" "$AUTH_KEYS" 2>/dev/null || \
        cat "${OPENCLAW_KEY}.pub" >> "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.ssh

    # Make sure openclaw-gateway can access the private key
    chown -R 1000:1000 "$OPENCLAW_SSH_DIR"

    echo "✅ openclaw SSH key registered"
fi

tail -f /dev/null
