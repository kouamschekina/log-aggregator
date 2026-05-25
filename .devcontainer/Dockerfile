FROM mcr.microsoft.com/devcontainers/go:1.21

RUN apt-get update \
  && apt-get install -y --no-install-recommends docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

USER vscode
