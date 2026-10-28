# Architecture Decision Records

One short record per architectural decision: the context, what was decided, what was rejected,
and what follows from it. Each one names the commits that made it and the files that implement
it, so a line in a Dockerfile or script can be traced back to why it is there. The reasoning and
evidence are in the matching [RFC](../rfc/README.md); the [decision log](../README.md#decision-log)
lists all of them on one page.

ADRs dated 2026-09-11 were recorded when the images were extracted from zephyr-testing-workshop
(`c7508fb`); some were made earlier, in that repository.

| # | Title | Status | Date | RFC |
|---|---|---|---|---|
| [0001](0001-build-from-ubuntu.md) | Build from ubuntu:24.04, not zephyr-build | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0002](0002-ci-and-devel-siblings.md) | ci and devel are siblings built from base | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0003](0003-sdk-in-shared-volume.md) | Zephyr and the SDK live in one machine-wide volume | Accepted | 2026-09-11 | [0002](../rfc/0002-shared-sdk-volume.md) |
| [0004](0004-containerenv-only-config.md) | containerEnv is the consumer's only configuration | Accepted | 2026-09-11 | [0002](../rfc/0002-shared-sdk-volume.md) |
| [0005](0005-scripts-in-image.md) | Runtime scripts ship in the devel image | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0006](0006-registry-cache-and-pushed-base.md) | Push base, and cache layers in the registry | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0007](0007-tag-by-zephyr-sdk-pair.md) | Tag images by their Zephyr/SDK pair | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0008](0008-hardware-tools-in-devel.md) | Hardware tools in devel; flashing runs on a self-hosted runner inside it | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0009](0009-ci-toolchains-union.md) | ci bakes the union of every consumer's toolchains | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0010](0010-sentinels-and-store-lock.md) | Complete-markers and a lock for the shared store | Accepted | 2026-09-11 | [0002](../rfc/0002-shared-sdk-volume.md) |
| [0011](0011-shell-helpers-env-only.md) | Shell helpers only change environment variables | Accepted | 2026-09-11 | [0002](../rfc/0002-shared-sdk-volume.md) |
| [0012](0012-one-venv-newest-zephyr.md) | One Python venv, pinned to the newest Zephyr in use | Accepted | 2026-09-11 | [0002](../rfc/0002-shared-sdk-volume.md) |
| [0013](0013-linux-amd64-only.md) | Images are linux/amd64 only | Accepted | 2026-09-11 | [0001](../rfc/0001-image-split.md) |
| [0014](0014-cmake-registry-volume.md) | CMake package registry on a per-project volume | Accepted | 2026-09-15 | [0002](../rfc/0002-shared-sdk-volume.md) |
| [0015](0015-git-http1-and-retries.md) | Fetch git over HTTP/1.1, and retry network steps | Accepted | 2026-09-24 | [0003](../rfc/0003-fetch-on-bad-links.md) |
| [0016](0016-seeded-fetch.md) | Build a new Zephyr version from one already in the store | Accepted | 2026-09-27 | [0003](../rfc/0003-fetch-on-bad-links.md) |
| [0017](0017-emulators-in-base.md) | Emulators in base, with launchers for real boards | Accepted | 2026-09-27 | [0004](../rfc/0004-emulation.md) |
| [0018](0018-lf-line-endings.md) | LF line endings, enforced at image build | Accepted | 2026-09-27 | [0005](../rfc/0005-devel-build-hygiene.md) |
| [0019](0019-vendor-downloads-stage.md) | Vendor downloads in their own build stage | Accepted | 2026-09-27 | [0005](../rfc/0005-devel-build-hygiene.md) |
| [0020](0020-mcumgr-from-source.md) | Build the mcumgr CLI from source at a pinned commit | Accepted | 2026-10-01 | [0005](../rfc/0005-devel-build-hygiene.md) |

## Format

**Status** (Proposed / Accepted / On hold / Superseded by NNNN), **Date**, **RFC**, **Commits**,
**Implemented in**, then **Context**, **Decision**, **Alternatives considered**, **Consequences**.

A decision is never edited away: when it changes, add a new ADR and set the old one's status to
"Superseded by NNNN". Keep **Implemented in** current when files move.
