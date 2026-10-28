# ADR 0002: ci and devel are siblings built from base

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`
- **Implemented in:** `Dockerfile.ci`, `Dockerfile.devel` (`FROM ${BASE_IMAGE}`), `build.sh`, `publish-images.yml`

## Context

GitHub-hosted runners need the SDK baked in (no persistent volume); developers want to choose
their own SDK and need flashing and editor tools. A chain (base -> ci -> devel) would give devel a
baked SDK it does not use.

## Decision

Two images built `FROM` the same base: `ci` adds the Zephyr SDK and tree, `devel` adds hardware
tools, the Actions runner, editor tooling and the runtime scripts.

## Alternatives considered

- One image for both: CI carries flashing tools, devel carries an unused ~10 GB SDK.
- Chain base -> ci -> devel: devel inherits the baked SDK.

## Consequences

- `build.sh`, `.devcontainer/devcontainer.json` and `publish-images.yml` each build the set and are kept in step by hand.
- `base` must reach a registry before the siblings build (ADR 0006).
