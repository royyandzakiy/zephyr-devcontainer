# ADR 0015: Fetch git over HTTP/1.1, and retry network steps

- **Status:** Accepted
- **Date:** 2026-09-24
- **RFC:** [0003](../rfc/0003-fetch-on-bad-links.md)
- **Commits:** `8011385`
- **Implemented in:** `scripts/fetch-zephyr.sh` (`GIT_CONFIG_*`, `retry`)

## Context

GitHub dropped long HTTP/2 transfers on a slow link (`curl 92 ... CANCEL`, `early EOF`) and
killed the Zephyr clone at 24% twice in a row.

## Decision

Set `http.version=HTTP/1.1` through `GIT_CONFIG_COUNT` / `GIT_CONFIG_KEY_0` /
`GIT_CONFIG_VALUE_0`, so west's git calls inherit it and `~/.gitconfig` is untouched. Retry the
clone and `west update` up to 3 times, 10 s apart, removing a partial checkout first; every other
step fails fast. The vendor downloads in devel retry 5 times for the same reason (ADR 0019).

## Alternatives considered

- `git config --global`: changes the user's config.

## Consequences

- Slightly slower transfers on good links.
