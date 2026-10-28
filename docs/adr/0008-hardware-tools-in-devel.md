# ADR 0008: Hardware tools in devel; flashing runs on a self-hosted runner inside it

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`, `c9a89c4`
- **Implemented in:** `Dockerfile.devel` (nrfutil, J-Link, `/actions-runner`)

## Context

GitHub-hosted jobs never touch hardware. Jobs that flash need USB and J-Link, which only a
developer's machine has.

## Decision

nrfutil, J-Link, picocom, dfu-util, mcumgr and the GitHub Actions runner are in devel only.
Flashing jobs use `runs-on: [self-hosted, linux]` with no `container:`, on a runner started
inside a devel container (`RUNNER_ALLOW_RUNASROOT=1`).

## Alternatives considered

- Hardware tools in ci too: larger image, unused on hosted runners.
- A separate runner image: a third image to keep in step.

## Consequences

- ci has no nrfutil, J-Link or mcumgr.
- On macOS there is no USB passthrough, so flashing happens outside the container.
