# ADR 0012: One Python venv, pinned to the newest Zephyr in use

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0002](../rfc/0002-shared-sdk-volume.md)
- **Commits:** `c7508fb`, `c9cd6a3`
- **Implemented in:** `Dockerfile.base` (`ZEPHYR_REQ_REF`)

## Context

The shared volume holds several Zephyr versions, but the image has one Python environment.
Older Zephyrs tolerate extra packages; newer ones fail hard on a missing one (4.4 added
`jsonschema`, and on a venv from v4.2.2 every build died in `zephyr_module.cmake`).

## Decision

One venv at `/opt/python-venv`, installed from the requirements of the **newest** Zephyr any
consumer uses (`ZEPHYR_REQ_REF`), without `requirements-doc` (sphinx, several hundred MB).
Renode's test requirements are installed after it and `pip check` must pass.

## Alternatives considered

- A venv per Zephyr version in the volume: created at runtime, slow, and the editor's Python setup would have to follow `use-vanilla`.

## Consequences

- Moving to a newer Zephyr in any project means bumping `ZEPHYR_REQ_REF` and republishing.
