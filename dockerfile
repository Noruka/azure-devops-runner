FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git jq bash libicu-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /azp
COPY start.sh .
RUN chmod +x /azp/start.sh

ENV AGENT_ALLOW_RUNASROOT=1
ENTRYPOINT ["/azp/start.sh"]