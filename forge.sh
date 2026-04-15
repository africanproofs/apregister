#!/bin/bash
# Wrapper to run forge via Docker (host glibc 2.31 is too old for native binaries)
exec docker run --rm -v "$(cd "$(dirname "$0")" && pwd)":/app -w /app --entrypoint forge ghcr.io/foundry-rs/foundry:latest "$@"
