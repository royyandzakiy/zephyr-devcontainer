# ADR 0003: Zephyr and the SDK live in one machine-wide volume

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0002](../rfc/0002-shared-sdk-volume.md)
- **Commits:** `c7508fb`, `cd58671` (renamed to `zephyr-sdks` / `ncs-sdks`)
- **Implemented in:** `scripts/setup-sdks.sh`, `scripts/fetch-zephyr.sh`; consumer `mounts`

## Context

Projects pin different Zephyr releases. Baking one into devel fixes the version for everyone;
a per-project volume downloads the same ~10 minutes of data once per project.

## Decision

devel ships no Zephyr tree or SDK. They are installed on first start into the named volume
`zephyr-sdks` (and `ncs-sdks` for nRF Connect SDK), mounted with **no project prefix** so every
project on the machine shares it. Versions install side by side under `<store>/<ver>` and
`<store>/toolchains/zephyr-sdk-<ver>`.

## Alternatives considered

- Bake the SDK into devel: one large image per pair.
- Per-project volume: a download per project.

## Consequences

- First start on a machine ~10 minutes, every later start seconds and offline.
- Concurrent first starts need a lock, and partial installs need detecting (ADR 0010).
- `/opt/zephyr-sdks` is a second store that `use-vanilla` also searches; ci fills it.
