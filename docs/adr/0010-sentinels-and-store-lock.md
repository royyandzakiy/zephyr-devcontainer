# ADR 0010: Complete-markers and a lock for the shared store

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0002](../rfc/0002-shared-sdk-volume.md)
- **Commits:** `c7508fb`
- **Implemented in:** `scripts/setup-sdks.sh`, `scripts/fetch-zephyr.sh` (`.complete`, `flock`)

## Context

A `west update` that died half way left a directory that looked ready forever. Two containers
starting together ran two `west update`s into one directory and corrupted it.

## Decision

Write `<ws>/.complete` and `<sdk>/.complete` only after a step fully succeeds; a missing marker
means refetch that piece only. Hold `flock` on `<store>/.lock` (30 min timeout) while populating;
`fetch-zephyr.sh` skips the lock when `setup-sdks.sh` already holds it (`ZEPHYR_STORE_LOCKED`).
Installs made before markers existed are adopted if their key files are present.

## Alternatives considered

- Check for the directory: reports partial installs as ready.

## Consequences

- Repair is `rm -rf` the broken piece and reopen; the rest stays.
- A second container waits up to 30 minutes on the first's download.
