FROM ubuntu:24.04

ARG DEV_USER=dev
ARG DEV_USER_PASSWORD=changeme

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/*

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

# Install Claude CLI
RUN npm install -g @anthropic-ai/claude-code@latest

# Create dev user
RUN useradd -m -s /bin/bash ${DEV_USER} \
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
COPY .bashrc /etc/safehouse-bashrc

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22 8080

CMD ["/start.sh"]
