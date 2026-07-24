FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git jq bash lsb-release gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable" \
    > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /azp
COPY start.sh .
RUN chmod +x /azp/start.sh

ENV AGENT_ALLOW_RUNASROOT=1
ENTRYPOINT ["/azp/start.sh"]