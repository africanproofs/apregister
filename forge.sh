#!/bin/bash
# Wrapper to run forge via Docker (host glibc 2.31 is too old for native binaries).
# Forwards the env vars that scripts/tests read at runtime — keep this list in sync
# with anything wired through `vm.envOr` / `vm.envAddress` / `vm.envString`.
exec docker run --rm \
  -v "$(cd "$(dirname "$0")" && pwd)":/app -w /app \
  -e PRIVATE_KEY \
  -e FCR_ADDRESS \
  -e IDENTITY_REGISTRY \
  -e PROBE_IDENTITY \
  -e FLARE_RPC \
  -e SONGBIRD_RPC \
  -e COSTON2_RPC \
  --entrypoint forge ghcr.io/foundry-rs/foundry:latest "$@"
