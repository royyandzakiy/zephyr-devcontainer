# ADR 0019: Vendor downloads in their own build stage

- **Status:** Accepted
- **Date:** 2026-09-27
- **RFC:** [0005](../rfc/0005-devel-build-hygiene.md)
- **Commits:** `c9a89c4`
- **Implemented in:** `Dockerfile.devel` (`FROM ubuntu:24.04 AS downloads`)

## Context

nrfutil, J-Link and the Actions runner were downloaded on top of base, so any change to base or
`scripts/` re-ran them. Nordic's server drops connections mid-download; on a bad link that took
90+ minutes or failed.

## Decision

Download them in a `downloads` stage from plain `ubuntu:24.04`, retried 5 times, and copy the
results into the main stage at the same paths.

## Alternatives considered

- Reorder layers on top of base: any base change still invalidates them.

## Consequences

- Their cache survives base and script changes.
- System-wide setup (`/usr/local/bin` link, `ld.so.conf`) stays in the main stage.
