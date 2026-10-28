# RFC 0001: Images extracted from the workshop: base, ci, devel

- **Status:** Implemented
- **Date:** 2026-09-11
- **Commits:** `c7508fb` (extracted from zephyr-testing-workshop)
- **ADR:** [0001](../adr/0001-build-from-ubuntu.md), [0002](../adr/0002-ci-and-devel-siblings.md),
  [0005](../adr/0005-scripts-in-image.md), [0006](../adr/0006-registry-cache-and-pushed-base.md),
  [0007](../adr/0007-tag-by-zephyr-sdk-pair.md), [0008](../adr/0008-hardware-tools-in-devel.md),
  [0009](../adr/0009-ci-toolchains-union.md), [0013](../adr/0013-linux-amd64-only.md)

## Summary

The container setup used to live inside zephyr-testing-workshop. It moved to its own repository
that publishes images to GHCR, so any project, the workshop included, needs only its own
`.devcontainer/devcontainer.json`: no scripts to copy, no submodule.

## Findings

1. **Two consumers with opposite needs.** A developer's container has a persistent volume and
   wants to pick its own Zephyr/SDK; a GitHub-hosted runner has no persistent volume and must
   start with the SDK already present.
2. **Hardware tools only matter on one side.** Flashing jobs run on a self-hosted runner, never
   on a GitHub-hosted one, so nrfutil, J-Link and the Actions runner do not belong in the CI image.
3. **`zephyrprojectrtos/zephyr-build` is ~32 GB**, mostly toolchains and emulators not used here.
4. **Copied scripts drift.** Each project carried its own `setup-sdks.sh`, and `use-ncs` found
   `ncs.py` with `find /workspaces -name ncs.py`, which picked an arbitrary copy when several
   projects were open.

## Architecture

```
Dockerfile.base    build tools, Python venv, Zephyr's Python requirements
├─ Dockerfile.ci     + Zephyr SDK and tree baked in   -> GitHub Actions `container:`
└─ Dockerfile.devel  + nrfutil, J-Link, Actions runner,
                       editor tooling, /opt/devcontainer scripts, shell helpers
```

`versions.env` sets the Zephyr/SDK pair that `ci` bakes and the image tag; it is not consumer
configuration. `build.sh`, `.devcontainer/devcontainer.json` and `publish-images.yml` build the
same images and are kept in step by hand.

## Alternatives

| Problem | Option | Why not |
|---|---|---|
| Starting point | `FROM zephyrproject-rtos/zephyr-build` | ~32 GB, most of it unused |
| | **`ubuntu:24.04` + only what is needed** (chosen) | base ~3.2 GB, devel ~4.8 GB, ci ~14 GB |
| Image layout | One image for both | CI would carry flashing tools; devel would carry a baked SDK it does not use |
| | Chain base -> ci -> devel | devel would inherit the baked SDK |
| | **Siblings off base** (chosen) | Each gets only what its consumer needs |
| Distributing scripts | Copy into each project | Drifts; `ncs.py` lookup ambiguity |
| | **Bake into devel at `/opt/devcontainer`** (chosen) | Editing one now costs a publish and a `docker pull` |
| Build cache | `type=gha` | Capped at 10 GB per repository; ci alone is ~14 GB |
| | **Registry `:buildcache` tags** (chosen) | GHCR has no such cap |

## Implementation (as executed)

1. Three Dockerfiles as above; `devel` copies `scripts/` to `/opt/devcontainer` and writes
   `use-vanilla`, `use-ncs`, `reset-ncs` and `zephyr-stores` into `/root/.bashrc`.
2. `publish-images.yml` on every push to `main`: push `base`, then `devel` and `ci` from it,
   tagged `z<zephyr>-sdk<sdk>` and `latest`. Skipped on forks.
3. The repository's own `devcontainer.json` builds base + devel from source with
   `initializeCommand`, inlined because on Windows `bash` usually resolves to the WSL shim.

## Outcome

- `base` has to be **pushed**, not `load`ed: buildx's `docker-container` driver does not share
  the host daemon's image store, so `FROM ${BASE_IMAGE}` resolves against a registry and a local
  tag fails with `pull access denied`.
- New GHCR packages are private; `devel` and `ci` were made public by hand. There is no API for it.
- Emulators were added to `base` later (RFC [0004](0004-emulation.md)), and the downloads in
  `devel` moved to their own stage (RFC [0005](0005-devel-build-hygiene.md)).

## Follow-ups

- Republishing an unchanged tag leaves consumers on a cached copy with no signal (ADR
  [0007](../adr/0007-tag-by-zephyr-sdk-pair.md)).
- Images are `linux/amd64` only; on Apple Silicon they run emulated, 3-5x slower.
