# ADR 0020: Build the mcumgr CLI from source at a pinned commit

- **Status:** Accepted
- **Date:** 2026-10-01
- **RFC:** [0005](../rfc/0005-devel-build-hygiene.md)
- **Commits:** `a92693d`
- **Implemented in:** `Dockerfile.devel` (`FROM golang:1.22-bookworm AS mcumgr`)

## Context

Talking to MCUboot / SMP devices needs the mcumgr CLI, which Ubuntu 24.04 does not package.

## Decision

`go install github.com/apache/mynewt-mcumgr-cli/mcumgr@<commit>` in a Go stage and copy only the
binary into devel. `mcumgr version` runs during the build.

## Alternatives considered

- Install Go in devel: a toolchain no one uses there.

## Consequences

- Updating mcumgr means changing `MCUMGR_CLI_COMMIT`.
