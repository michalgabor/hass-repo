ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG CLAUDE_VERSION=latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs npm git ripgrep ttyd openssh-client ca-certificates curl \
    && npm install -g "@anthropic-ai/claude-code@${CLAUDE_VERSION}" \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

ENV HOME=/data \
    DISABLE_AUTOUPDATER=1

COPY rootfs /

RUN chmod +x \
        /etc/cont-init.d/*.sh \
        /etc/services.d/*/run \
        /usr/local/bin/agent-run \
        /usr/local/bin/agent-setup
