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

# Fix permissions
mkdir -p /home/${DEV_USER}/.claude/debug
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/projects 2>/dev/null || true
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.claude 2>/dev/null || true

# Symlink tmux config from mounted volume
TMUX_CONF=/home/${DEV_USER}/.config/tmux/.tmux.conf
TMUX_LINK=/home/${DEV_USER}/.tmux.conf
if [ -f "$TMUX_CONF" ] && [ ! -L "$TMUX_LINK" ]; then
    ln -sf "$TMUX_CONF" "$TMUX_LINK"
    chown -h ${DEV_USER}:${DEV_USER} "$TMUX_LINK"
fi

# Ensure .claude.json persists via symlink into the mounted volume
CLAUDE_CONFIG=/home/${DEV_USER}/.claude/config.json
CLAUDE_JSON=/home/${DEV_USER}/.claude.json

# Migrate standalone file into the volume if present
if [ -f "$CLAUDE_JSON" ] && [ ! -L "$CLAUDE_JSON" ]; then
    mv "$CLAUDE_JSON" "$CLAUDE_CONFIG"
fi

# Create symlink if missing
if [ ! -L "$CLAUDE_JSON" ]; then
    ln -sf "$CLAUDE_CONFIG" "$CLAUDE_JSON"
    chown -h ${DEV_USER}:${DEV_USER} "$CLAUDE_JSON"
fi

# Fix permissions on config
if [ -f "$CLAUDE_CONFIG" ]; then
    chmod 600 "$CLAUDE_CONFIG"
    chown ${DEV_USER}:${DEV_USER} "$CLAUDE_CONFIG"
fi
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.config/gh 2>/dev/null || true
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.local/share/code-server 2>/dev/null || true

# code-server (iPad / browser)
echo "✅ code-server ready — port ${CODE_SERVER_PORT}"
su - ${DEV_USER} -c "PASSWORD='${CODE_SERVER_PASSWORD}' code-server --config /home/${DEV_USER}/.config/code-server/config.yaml" &

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

mkdir -p "$OPENCLAW_SSH_DIR"
chown ${DEV_USER}:${DEV_USER} "$OPENCLAW_SSH_DIR"

if [ ! -f "$OPENCLAW_KEY" ]; then
    su - ${DEV_USER} -c "ssh-keygen -t ed25519 -f $OPENCLAW_KEY -N '' -C 'openclaw-gateway'"
    echo "✅ SSH key generated for openclaw"
fi

# Register public key into authorized_keys
mkdir -p /home/${DEV_USER}/.ssh
chmod 700 /home/${DEV_USER}/.ssh
grep -qF "$(cat ${OPENCLAW_KEY}.pub)" "$AUTH_KEYS" 2>/dev/null || \
    cat "${OPENCLAW_KEY}.pub" >> "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.ssh
echo "✅ openclaw SSH key registered"

# === Claude Code: auto-create claude-code tmux session ===
su - ${DEV_USER} -c "tmux has-session -t claude-code 2>/dev/null || tmux new-session -d -s claude-code -x 220 -y 50"
echo "✅ tmux session 'claude-code' ready"

tail -f /dev/null
