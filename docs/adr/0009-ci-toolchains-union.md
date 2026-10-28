# ADR 0009: ci bakes the union of every consumer's toolchains

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`
- **Implemented in:** `versions.env` (`ZSDK_TOOLCHAINS`), `Dockerfile.ci`

## Context

A hosted runner cannot add an SDK toolchain at runtime, and one ci image serves several
projects (arm, x86_64, xtensa esp32/esp32s3).

## Decision

`ZSDK_TOOLCHAINS` in `versions.env` lists the union of what every consuming project builds
for; ci installs exactly those, and the build fails if one is missing.

## Alternatives considered

- One ci image per project: many ~14 GB images.
- All SDK toolchains: much larger image.

## Consequences

- Adding a board family to any consumer means editing `versions.env` here and republishing.
- devel is unaffected: it installs the consumer's own `ZSDK_TOOLCHAINS` at start.
