FROM mcr.microsoft.com/devcontainers/python:3.13-trixie

RUN echo 'alias ll="ls -lrta"' >> ~vscode/.bashrc

RUN apt-get update && apt-get install -y \
        hexyl sysvbanner ttyrec dnsutils \
        jq miller \
        x11-apps mesa-utils dbus-x11 libgl1-mesa-dri fonts-liberation \
        chromium \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# --- Neovim (latest stable, multi-arch) ---
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
 && case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
      amd64) ARCH=x86_64 ;; \
      arm64) ARCH=arm64 ;; \
      *) echo "unsupported arch: ${TARGETARCH:-unknown}" && exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz" -o /tmp/nvim.tar.gz \
 && tar -xzf /tmp/nvim.tar.gz -C /opt \
 && ln -s /opt/nvim-linux-${ARCH}/bin/nvim /usr/local/bin/nvim \
 && rm /tmp/nvim.tar.gz \
 && rm -rf /var/lib/apt/lists/*

COPY init.lua /tmp/init.lua
RUN mkdir -p /home/${USERNAME}/.config/nvim \
 && cp /tmp/init.lua /home/${USERNAME}/.config/nvim/init.lua \
 && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config

# Install the CLIs AS vscode so they land in /home/vscode, not /root
USER vscode

# Put both install dirs on PATH explicitly — doesn't depend on any .bashrc
# being sourced, or on $SHELL being set.
ENV PATH="/home/vscode/.local/bin:/home/vscode/.opencode/bin:${PATH}"

RUN curl -fsSL https://claude.ai/install.sh | bash && \
    echo "Claude installed."

# --no-modify-path skips the installer's shell-detection step, which is the
# part that aborts under `set -u` when $SHELL is unset during the build.
RUN curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path && \
    echo "Opencode installed."

RUN echo "echo 'Hello.'" >> ~/.bashrc && \
    echo "date" >> ~/.bashrc && \
    echo "python --version" >> ~/.bashrc && \
    echo "cat /etc/os-release | tr '\n' ',' " >> ~/.bashrc && \
    echo "uname -a" >> ~/.bashrc
