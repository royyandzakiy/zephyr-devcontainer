# ADR 0004: containerEnv is the consumer's only configuration

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0002](../rfc/0002-shared-sdk-volume.md)
- **Commits:** `c7508fb`
- **Implemented in:** `scripts/setup-sdks.sh`, `scripts/fetch-zephyr.sh`, `_zephyr_env_version` in `Dockerfile.devel`

## Context

Consumers once had a `versions.env` and also had to set `ZEPHYR_BASE` and
`ZEPHYR_SDK_INSTALL_DIR` in `containerEnv`, because the VS Code extension host cannot read an env
file. The two could disagree, and `setup-sdks.sh` carried a guard for it.

## Decision

Consumers set only `containerEnv`. The Zephyr version is the directory above `ZEPHYR_BASE`'s
`zephyr/`, the SDK version is the suffix of `ZEPHYR_SDK_INSTALL_DIR`; `ZSDK_TOOLCHAINS` and
`ZEPHYR_BLOBS` say what to install. No script or `.bashrc` line hardcodes a version.
`versions.env` in this repository only drives what `ci` bakes and the image tag.

## Alternatives considered

- `versions.env` in each project: VS Code cannot read it, so `containerEnv` is needed anyway.

## Consequences

- Nothing can desync; the mismatch guard was removed.
- The store layout (`<store>/<ver>/zephyr`, `zephyr-sdk-<ver>`) is now part of the contract.
