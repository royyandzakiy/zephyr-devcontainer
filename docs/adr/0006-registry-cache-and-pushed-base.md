# ADR 0006: Push base, and cache layers in the registry

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`
- **Implemented in:** `.github/workflows/publish-images.yml`

## Context

buildx's `docker-container` driver does not share the host daemon's image store, so a `load`ed
base is invisible to the sibling builds (`pull access denied` on `docker.io/library/...`). The
GitHub Actions cache is capped at 10 GB per repository; ci alone is ~14 GB.

## Decision

Push `base` to GHCR (it can stay private) and build the siblings `FROM` that reference. Cache
each image's layers in a `:buildcache` tag with `type=registry,mode=max`.

## Alternatives considered

- `load` base locally: invisible to buildx.
- `type=gha` cache: thrashes at 10 GB and evicts other workflows' caches.

## Consequences

- Three packages on GHCR; devel and ci were made public by hand, since there is no API for it.
- Publishing needs only `GITHUB_TOKEN` with `packages: write`.
