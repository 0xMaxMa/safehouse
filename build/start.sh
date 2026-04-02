#!/bin/bash
set -e

# Use environment variables with defaults
DEV_USER=${DEV_USER:-dev}
SSH_PORT=${SSH_PORT:-2222}
CODE_SERVER_PORT=${CODE_SERVER_PORT:-8080}
CODE_SERVER_PASSWORD=${CODE_SERVER_PASSWORD:-changeme}
OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND:-lan}
OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT:-18789}

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

# Always update .bashrc from template (picks up changes on rebuild)
BASHRC=/home/${DEV_USER}/.bashrc
cp /etc/safehouse-bashrc "$BASHRC" && chown ${DEV_USER}:${DEV_USER} "$BASHRC"

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

# Openclaw gateway
sudo -u ${DEV_USER} openclaw gateway --bind ${OPENCLAW_GATEWAY_BIND} --port ${OPENCLAW_GATEWAY_PORT} &
echo "✅ openclaw gateway ready — port ${OPENCLAW_GATEWAY_PORT}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VS Code Desktop → Remote-SSH"
echo "  Host: YOUR_SERVER_IP  Port: ${SSH_PORT}  User: ${DEV_USER}"
echo ""
echo "  iPad / Browser → http://YOUR_SERVER_IP:${CODE_SERVER_PORT}"
echo "  Password: ${CODE_SERVER_PASSWORD}"
echo ""
echo "  Openclaw Gateway → port ${OPENCLAW_GATEWAY_PORT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

tail -f /dev/null
