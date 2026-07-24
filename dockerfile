FROM mcr.microsoft.com/dotnet/sdk:8.0

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates git jq bash unzip && rm -rf /var/lib/apt/lists/*

# Blazor WASM tools
RUN dotnet workload install wasm-tools

# Azure CLI para publish/deploy
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

WORKDIR /azp
COPY start.sh .
RUN chmod +x /azp/start.sh

ENV AGENT_ALLOW_RUNASROOT=1
ENTRYPOINT ["/azp/start.sh"]