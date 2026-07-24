#!/usr/bin/env bash
set -euo pipefail

: "${AZP_URL:?Missing AZP_URL}"
: "${AZP_TOKEN:?Missing AZP_TOKEN}"
: "${AZP_POOL:?Missing AZP_POOL}"

echo -n "$AZP_TOKEN" > /azp/.token
unset AZP_TOKEN

cleanup() {
  if [ -f /azp/config.sh ]; then
    /azp/config.sh remove --unattended --auth PAT --token "$(cat /azp/.token)" || true
  fi
}
trap cleanup EXIT INT TERM

AGENT_VERSION=$(curl -fsSL https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest | jq -r '.tag_name' | sed 's/^v//')
curl -fsSL "https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz" | tar -xz

/azp/bin/installdependencies.sh

/azp/config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "$AZP_URL" \
  --auth PAT \
  --token "$(cat /azp/.token)" \
  --pool "$AZP_POOL" \
  --work "${AZP_WORK:-_work}" \
  --acceptTeeEula

exec /azp/run.sh