FROM mcr.microsoft.com/devcontainers/base:ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    direnv \
    ripgrep \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    jq \
    nano \
    vim

USER vscode
RUN mkdir -p /home/vscode/.config
