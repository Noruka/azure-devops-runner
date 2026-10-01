#!/usr/bin/env bash
set -euo pipefail

: "${AZP_URL:?Missing AZP_URL}"
: "${AZP_TOKEN:?Missing AZP_TOKEN}"
: "${AZP_POOL:?Missing AZP_POOL}"

echo -n "$AZP_TOKEN" > /azp/.token
unset AZP_TOKEN

AGENT_PID=""

cleanup() {
  trap - EXIT INT TERM

  # Para primero el agente para que el remove no choque con la sesión activa
  if [ -n "$AGENT_PID" ] && kill -0 "$AGENT_PID" 2>/dev/null; then
    kill -TERM "$AGENT_PID" 2>/dev/null || true
    wait "$AGENT_PID" 2>/dev/null || true
  fi

  # Solo intenta desregistrar si el agente llegó a configurarse
  if [ -f /azp/.agent ]; then
    /azp/config.sh remove --unattended --auth PAT --token "$(cat /azp/.token)" || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Obtiene URL oficial del paquete (firmada) desde Azure DevOps
AGENT_PACKAGE_URL=$(curl -fsSL --retry 5 --retry-all-errors \
  -u "user:$(cat /azp/.token)" \
  -H "Accept: application/json" \
  "${AZP_URL}/_apis/distributedtask/packages/agent?platform=linux-x64&%24top=1" \
  | jq -r '.value[0].downloadUrl')

if [ -z "${AGENT_PACKAGE_URL}" ] || [ "${AGENT_PACKAGE_URL}" = "null" ]; then
  echo "Could not resolve agent package URL from Azure DevOps API"
  exit 1
fi

curl -fL --retry 5 --retry-delay 3 --retry-all-errors -o /azp/agent.tar.gz "$AGENT_PACKAGE_URL"
tar -xzf /azp/agent.tar.gz -C /azp
rm -f /azp/agent.tar.gz

/azp/bin/installdependencies.sh

/azp/config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "$AZP_URL" \
  --auth PAT \
  --token "$(cat /azp/.token)" \
  --pool "$AZP_POOL" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula

# En segundo plano (no exec) para que el trap siga vivo y desregistre al parar
/azp/run.sh &
AGENT_PID=$!
wait "$AGENT_PID"
