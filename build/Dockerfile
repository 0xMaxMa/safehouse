FROM ubuntu:24.04

ARG DEV_USER=dev
ARG DEV_USER_PASSWORD=changeme

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --fix-missing \
    openssh-server \
    curl \
    git \
    tmux \
    sudo \
    python3 \
    python3-pip \
    vim \
    wget \
    ca-certificates \
    gnupg \
    htop \
    jq \
    unzip \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.com/install | bash \
    && cp /root/.bun/bin/bun /usr/local/bin/bun \
    && chmod 755 /usr/local/bin/bun

# Install Node.js 22.x (latest LTS)
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu noble stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install code-server (iPad / browser access)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Cloudflare Tunnel
RUN curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" | tee /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update \
    && apt-get install -y cloudflared \
    && rm -rf /var/lib/apt/lists/*

# Install oh-my-zsh system-wide (home dir is volume-mounted, so ~/.oh-my-zsh won't survive)
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Install Claude CLI + Openclaw
# RUN npm install -g @anthropic-ai/claude-code@latest openclaw@latest
RUN npm install -g @anthropic-ai/claude-code@latest

# Create dev user (remove pre-existing ubuntu user to free UID 1000)
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -s /bin/zsh --uid 1000 ${DEV_USER} \
    && echo "${DEV_USER}:${DEV_USER_PASSWORD}" | chpasswd \
    && echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# SSH hardening
RUN mkdir /var/run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && echo "AllowUsers ${DEV_USER}" >> /etc/ssh/sshd_config

# Store templates in /etc so start.sh can seed them on first run
# (home dir is volume-mounted, so nothing copied there will persist)
COPY code-server-config.yaml /etc/code-server-config.yaml
COPY code-server-settings.json /etc/code-server-settings.json
COPY .zshrc /etc/safehouse-zshrc
COPY tmux-picker.sh /opt/safehouse/tmux-picker.sh

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22 8080 18789 18790

CMD ["/start.sh"]
