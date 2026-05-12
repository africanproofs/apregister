#!/usr/bin/env bash
# Regenerate types/participant.d.ts and abi/*.abi.json from their canonical
# sources, then fail if `git diff` shows the committed files are out of sync.
#
# Use locally before pushing a schema or contract change. CI runs the same
# script and blocks merges on drift.

set -euo pipefail

cd "$(dirname "$0")/.."

JSTT_VERSION="latest"

# Use ./forge.sh (Docker wrapper) on hosts with glibc < 2.33, bare `forge` in CI / modern hosts.
if [[ -x ./forge.sh ]] && ! forge --version >/dev/null 2>&1; then
  FORGE="./forge.sh"
else
  FORGE="forge"
fi

regenerate_types() {
  echo "==> Regenerating types/participant.d.ts from assets/participant.schema.json..."
  npx --yes "json-schema-to-typescript@${JSTT_VERSION}" \
    assets/participant.schema.json > types/participant.d.ts
}

regenerate_abi() {
  local name="$1"
  local path="$2"
  echo "==> Regenerating abi/${name}.abi.json from ${path} (using ${FORGE})..."
  "${FORGE}" inspect "${path}:${name}" abi --json | python3 -c '
import json, sys
data = json.load(sys.stdin)
json.dump(data, sys.stdout, indent=2)
sys.stdout.write("\n")
' > "abi/${name}.abi.json"
}

regenerate_types
regenerate_abi "ParticipantRegister" "src/ParticipantRegister.sol"
regenerate_abi "FlareIdentityAdapter" "src/FlareIdentityAdapter.sol"

echo "==> Checking for drift..."
if ! git diff --exit-code types/ abi/; then
  echo
  echo "Drift detected. Either:"
  echo "  - You forgot to commit regenerated types/abi after editing the schema or contract source, OR"
  echo "  - Someone hand-edited a generated file. Don't."
  echo
  echo "Fix: run \`bash scripts/check-drift.sh\` locally and commit the regenerated files."
  exit 1
fi

echo "No drift. types/ and abi/ match their canonical sources."
