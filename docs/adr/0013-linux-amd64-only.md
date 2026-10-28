# ADR 0013: Images are linux/amd64 only

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`
- **Implemented in:** `Dockerfile.*` (x86_64 downloads), README "macOS"

## Context

J-Link, nrfutil, Renode's portable build, Espressif QEMU and the SDK host tools are all fetched
as x86_64 Linux binaries.

## Decision

Publish `linux/amd64` only. Apple Silicon runs it with `--platform=linux/amd64`, emulated.

## Alternatives considered

- Multi-arch: every x86_64-only download would need an arm64 counterpart, and CI time doubles.

## Consequences

- On Apple Silicon builds are about 3-5x slower, and USB passthrough is not available, so a `macos/devcontainer.json` without `/dev` is documented.
