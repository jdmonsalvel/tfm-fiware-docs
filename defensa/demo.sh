#!/usr/bin/env bash
# Demo en vivo para la defensa: Tabla 26 (401 / 401 / 403 / 200) contra el entorno real.
# Uso: KUBECONFIG=~/.kube/config-tfm bash defensa/demo.sh
# Reutiliza las credenciales de sandbox del smoke-test (mismos valores que kong.yaml).
set -euo pipefail

ORION="https://orion.lab-jdmonsalvel.com"
SMOKE="$HOME/Documents/Personal/Repositorios/github/TFM/tfm-fiware-gitops/tests/smoke-test.sh"
ISS="fiware-dataspace-provider-app";   SECRET="demo-jwt-secret-tfm-2026"
UNREG_ISS="unregistered-participant-app"; UNREG_SECRET="demo-unregistered-secret-tfm-2026"

bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; reset=$'\e[0m'

make_jwt() {
  python3 -I - "$1" "$2" <<'PYEOF'
import base64, hashlib, hmac, json, sys, time
b = lambda d: base64.urlsafe_b64encode(d if isinstance(d, bytes) else d.encode()).rstrip(b'=').decode()
iss, secret = sys.argv[1], sys.argv[2]
h = b(json.dumps({"alg": "HS256", "typ": "JWT"}))
p = b(json.dumps({"iss": iss, "exp": int(time.time()) + 3600}))
print(f"{h}.{p}.{b(hmac.new(secret.encode(), f'{h}.{p}'.encode(), hashlib.sha256).digest())}")
PYEOF
}

# caso <título> <args de curl...>: muestra el código HTTP y el cuerpo de la respuesta
caso() {
  local title="$1"; shift
  local out code body color
  out=$(curl -sk --max-time 15 -w '\n%{http_code}' "$@" "${ORION}/version")
  code="${out##*$'\n'}"; body="${out%$'\n'*}"
  case "$code" in 2*) color=$green ;; 403) color=$yellow ;; *) color=$red ;; esac
  printf '%s▶ %s%s\n' "$bold" "$title" "$reset"
  printf '  HTTP %s%s%s  %s\n\n' "$color$bold" "$code" "$reset" "$(tr -d '\n' <<<"$body" | cut -c1-110)"
}

pause() { read -r -p "${dim}[Enter para continuar]${reset}" _; echo; }

echo "${bold}Kong como PEP delante de Orion-LD — ${ORION}${reset}"
echo
TOKEN=$(make_jwt "$ISS" "$SECRET")
BAD=$(make_jwt "$ISS" "firma-incorrecta")
UNREG=$(make_jwt "$UNREG_ISS" "$UNREG_SECRET")

caso "1. Sin token" ; pause
caso "2. Token con firma inválida" -H "Authorization: Bearer ${BAD}" ; pause
caso "3. Firma válida, emisor NO registrado en la Trusted Issuers List" -H "Authorization: Bearer ${UNREG}" ; pause
caso "4. Participante registrado en la TIL" -H "Authorization: Bearer ${TOKEN}" ; pause

echo "${bold}▶ Emisores de confianza en la TIL${reset}"
curl -sk --max-time 15 "https://til.lab-jdmonsalvel.com/issuer" | python3 -I -m json.tool | head -20
echo
if [ "${1:-}" != "--sin-smoke" ]; then
  pause
  echo "${bold}▶ Smoke-test completo${reset}"
  bash "$SMOKE"
fi
