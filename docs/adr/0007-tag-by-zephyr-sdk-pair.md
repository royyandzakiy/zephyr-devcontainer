# ADR 0007: Tag images by their Zephyr/SDK pair

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0001](../rfc/0001-image-split.md)
- **Commits:** `c7508fb`
- **Implemented in:** `publish-images.yml` (`pair=z<zephyr>-sdk<sdk>`), `versions.env`

## Context

Consumers need a tag that says what ci contains, and a version bump should not move a tag
someone already uses.

## Decision

Tag `z<zephyr>-sdk<sdk>` (e.g. `z4.4.0-sdk1.0.1`) plus `latest`, published on every push to
`main`. If a fix must reach consumers who already pulled a tag, add a build suffix
(`z4.4.0-sdk1.0.1-2`) instead of republishing it.

## Alternatives considered

- Semantic versions for the images: say nothing about the SDK inside.
- Commit SHA tags: immutable but unreadable in a `devcontainer.json`.

## Consequences

- A tag is only immutable while `versions.env` is unchanged. Republishing it leaves consumers on a cached copy with no signal; `docker pull` is then required.
- For devel the pair is only the default; a consumer can ask for any pair at runtime (ADR 0004).
