# ADR 0016: Build a new Zephyr version from one already in the store

- **Status:** Accepted
- **Date:** 2026-09-27
- **RFC:** [0003](../rfc/0003-fetch-on-bad-links.md)
- **Commits:** `37180aa`, `89d04b9`
- **Implemented in:** `seed_repo`, `seed_clone`, `--path-cache` in `scripts/fetch-zephyr.sh`

## Context

Even over HTTP/1.1 the full clone failed 6 of 6 times on one link, while most of the data was
already on disk in another version.

## Decision

If the store has a complete Zephyr, local-clone it (hardlinked, no `--shared`/`--reference`),
point `origin` at GitHub, fetch only the target tag, check it out and delete the seed's other
refs. `west update --path-cache <seed workspace>` does the same for modules. Fall back to a full
clone if the seeded fetch fails.

## Alternatives considered

- `--reference` / `--shared`: deleting the seed would break the new checkout.

## Consequences

- Adding a version took 11 s on the link where the full clone always failed.
- The first version on a machine still needs the full clone.
