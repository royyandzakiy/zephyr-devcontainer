# ADR 0014: CMake package registry on a per-project volume

- **Status:** Accepted
- **Date:** 2026-09-15
- **RFC:** [0002](../rfc/0002-shared-sdk-volume.md)
- **Commits:** `cd58671`
- **Implemented in:** consumer `mounts` (`<project>-cmake-registry` -> `/root/.cmake`), `scripts/register-sdks.sh`

## Context

The nRF Connect extension finds SDKs only through the CMake user package registry. It lives in
the container's throwaway layer, and the extension reads it once at activation, before
`postStartCommand` can re-register anything, so the picker was empty after every rebuild.

## Decision

Mount `/root/.cmake` on `${localWorkspaceFolderBasename}-cmake-registry`, and still re-register
every workspace and SDK on each start (`register-sdks.sh`). `setup-sdks.sh` fails if no
`Zephyr-sdk` entry exists, since it is `FindZephyr-sdk.cmake`'s only fallback.

## Alternatives considered

- Re-register at start only: too late for the extension.
- Share one registry volume across projects: entries for another project's workspaces would appear.

## Consequences

- One more mount in every consumer's `devcontainer.json`.
