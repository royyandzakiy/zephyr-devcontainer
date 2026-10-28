# ADR 0001: Build from ubuntu:24.04, not zephyr-build

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`
- **Implemented in:** `Dockerfile.base` (`FROM ubuntu:24.04`)

## Context

The official `zephyrproject-rtos/zephyr-build` image is ~32 GB, mostly toolchains and emulators
these projects never use, and every consumer pulls it.

## Decision

Build `base` from `ubuntu:24.04` and install only what Zephyr's build, native_sim (32-bit) and
the static analysis in use need. Each requirement is checked at the end of the build
(`ldconfig`, `command -v`, `import pytest`).

## Alternatives considered

- `FROM zephyrproject-rtos/zephyr-build`: ~32 GB.
- `FROM` a slimmer community image: another upstream to track, same unknown contents.

## Consequences

- base ~3.2 GB, devel ~4.8 GB, ci ~14 GB.
- This repository owns the package list; a new Zephyr requirement is added by hand.
- Ubuntu 24.04 marks the system Python externally managed (PEP 668), so a venv is required (ADR 0012).
