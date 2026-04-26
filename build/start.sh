#!/bin/bash
set -e

# Use environment variables with defaults
DEV_USER=${DEV_USER:-dev}
SSH_PORT=${SSH_PORT:-2222}
CODE_SERVER_PORT=${CODE_SERVER_PORT:-8080}
CODE_SERVER_PASSWORD=${CODE_SERVER_PASSWORD:-changeme}
# OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND:-lan}
# OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT:-18789}

echo "🚀 Starting dev server container..."

# Propagate container env vars to login shells (SSH sessions)
[ -n "$DOCKER_HOST" ] && echo "DOCKER_HOST=$DOCKER_HOST" >> /etc/environment
[ -n "$OPENCLAW_GATEWAY_TOKEN" ] && echo "OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN" >> /etc/environment
[ -n "$CLAUDE_AI_SESSION_KEY" ] && echo "CLAUDE_AI_SESSION_KEY=$CLAUDE_AI_SESSION_KEY" >> /etc/environment
[ -n "$CLAUDE_WEB_SESSION_KEY" ] && echo "CLAUDE_WEB_SESSION_KEY=$CLAUDE_WEB_SESSION_KEY" >> /etc/environment
[ -n "$CLAUDE_WEB_COOKIE" ] && echo "CLAUDE_WEB_COOKIE=$CLAUDE_WEB_COOKIE" >> /etc/environment
[ -n "$DEV_SERVER_HOST" ] && echo "DEV_SERVER_HOST=$DEV_SERVER_HOST" >> /etc/environment

# SSH
mkdir -p /var/run/sshd
echo "${DEV_USER}:${CODE_SERVER_PASSWORD}" | chpasswd
service ssh start
echo "✅ SSH ready — port 22 (mapped to ${SSH_PORT} on host)"

# Fix ownership of volume-mounted home dir
chmod 755 /home/${DEV_USER}
chown ${DEV_USER}:${DEV_USER} /home/${DEV_USER}
for dir in .claude .config .local .docker .ssh .openclaw; do
    chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/${dir} 2>/dev/null || true
done

# Symlink tmux config if present
TMUX_CONF=/home/${DEV_USER}/.config/tmux/.tmux.conf
TMUX_LINK=/home/${DEV_USER}/.tmux.conf
if [ -f "$TMUX_CONF" ] && [ ! -L "$TMUX_LINK" ]; then
    ln -sf "$TMUX_CONF" "$TMUX_LINK"
    chown -h ${DEV_USER}:${DEV_USER} "$TMUX_LINK"
fi

# Always update .zshrc from template (picks up changes on rebuild)
ZSHRC=/home/${DEV_USER}/.zshrc
cp /etc/safehouse-zshrc "$ZSHRC" && chown ${DEV_USER}:${DEV_USER} "$ZSHRC"

# Ensure code-server config exists (volume mount wipes Dockerfile COPY)
CODE_SERVER_CONFIG=/home/${DEV_USER}/.config/code-server/config.yaml
mkdir -p "$(dirname $CODE_SERVER_CONFIG)"
[ ! -f "$CODE_SERVER_CONFIG" ] && cp /etc/code-server-config.yaml "$CODE_SERVER_CONFIG"
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.config/code-server

# Ensure code-server settings exist (terminal font fix for iPad)
CODE_SERVER_SETTINGS=/home/${DEV_USER}/.local/share/code-server/User/settings.json
mkdir -p "$(dirname $CODE_SERVER_SETTINGS)"
[ ! -f "$CODE_SERVER_SETTINGS" ] && cp /etc/code-server-settings.json "$CODE_SERVER_SETTINGS"
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.local/share/code-server 2>/dev/null || true

# Ensure projects dir exists in home
mkdir -p /home/${DEV_USER}/projects
chown ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/projects

# Ensure npm global prefix dir exists (user-local, no sudo needed)
mkdir -p /home/${DEV_USER}/.npm-global
chown -R ${DEV_USER}:${DEV_USER} /home/${DEV_USER}/.npm-global

# ── Virtual Display ──────────────────────────────────────────
echo "Starting virtual display..."
Xvfb :99 -screen 0 1280x800x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 1

export DISPLAY=:99
echo "DISPLAY=:99" >> /etc/environment

# ── noVNC Web Viewer (token routing mode) ────────────────────
# NOTE: no global x11vnc — BrowserModule spawns x11vnc per-session
NOVNC_PORT=${NOVNC_PORT:-6080}
echo "Starting noVNC on port ${NOVNC_PORT} (token mode)..."
touch /tmp/vnc-tokens.cfg
chmod 666 /tmp/vnc-tokens.cfg
websockify --web=/usr/share/novnc --daemon \
    --log-file=/tmp/websockify.log \
    --token-plugin=TokenFile \
    --token-source=/tmp/vnc-tokens.cfg \
    0.0.0.0:${NOVNC_PORT}
echo "✅ noVNC ready — port ${NOVNC_PORT}"

# code-server (iPad / browser)
echo "✅ code-server ready — port ${CODE_SERVER_PORT}"
su - ${DEV_USER} -c "PASSWORD='${CODE_SERVER_PASSWORD}' code-server --config ${CODE_SERVER_CONFIG}" &

# Openclaw gateway
# sudo -u ${DEV_USER} openclaw gateway --bind ${OPENCLAW_GATEWAY_BIND} --port ${OPENCLAW_GATEWAY_PORT} &
# echo "✅ openclaw gateway ready — port ${OPENCLAW_GATEWAY_PORT}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VS Code Desktop → Remote-SSH"
echo "  Host: YOUR_SERVER_IP  Port: ${SSH_PORT}  User: ${DEV_USER}"
echo ""
echo "  iPad / Browser → http://YOUR_SERVER_IP:${CODE_SERVER_PORT}"
echo "  Password: ${CODE_SERVER_PASSWORD}"
echo ""
echo "  noVNC Viewer → http://YOUR_SERVER_IP:${NOVNC_PORT}/vnc.html"
# echo ""
# echo "  Openclaw Gateway → port ${OPENCLAW_GATEWAY_PORT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

tail -f /dev/null
