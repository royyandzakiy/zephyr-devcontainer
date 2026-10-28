# ADR 0005: Runtime scripts ship in the devel image

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`
- **Implemented in:** `Dockerfile.devel` (`COPY scripts/ /opt/devcontainer/`)

## Context

Each project carried a copy of `setup-sdks.sh` and friends, which drifted, and `use-ncs` found
`ncs.py` with `find /workspaces`, picking an arbitrary copy when several projects were open.

## Decision

Copy `scripts/` to `/opt/devcontainer` in devel. `postStartCommand` is
`/opt/devcontainer/setup-sdks.sh`, and `use-ncs` uses a fixed path.

## Alternatives considered

- Copy scripts into each project, or a git submodule: drift, and one more thing per project.

## Consequences

- A project needs only `devcontainer.json`.
- Fixing a script costs a publish and a `docker pull`, where a copied script needed only a restart.
