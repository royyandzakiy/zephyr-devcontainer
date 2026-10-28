# Documentation

| What | Where |
|---|---|
| How the images, volumes and scripts connect | [architecture/](architecture/README.md) |
| Why each change was made, with evidence | [rfc/](rfc/README.md) |
| One record per decision | [adr/](adr/README.md) |
| Using the images, emulation, publishing | [../README.md](../README.md) |

## Decision log

Every major decision, oldest first, traced to its record, its write-up, the commits that made it
and where it lives today. To find why a line exists, search this table for the file; to find
what a commit decided, search for its hash.

| Date | Decision (ADR) | RFC | Commits | Implemented in |
|---|---|---|---|---|
| 2026-09-11 | [0001](adr/0001-build-from-ubuntu.md) Build from ubuntu:24.04, not zephyr-build | [0001](rfc/0001-image-split.md) | `c7508fb` | `Dockerfile.base` (`FROM ubuntu:24.04`) |
| 2026-09-11 | [0002](adr/0002-ci-and-devel-siblings.md) ci and devel are siblings built from base | [0001](rfc/0001-image-split.md) | `c7508fb` | `Dockerfile.ci`, `Dockerfile.devel` (`FROM ${BASE_IMAGE}`), `build.sh`, `publish-images.yml` |
| 2026-09-11 | [0003](adr/0003-sdk-in-shared-volume.md) Zephyr and the SDK live in one machine-wide volume | [0002](rfc/0002-shared-sdk-volume.md) | `c7508fb`, `cd58671` (renamed to `zephyr-sdks` / `ncs-sdks`) | `scripts/setup-sdks.sh`, `scripts/fetch-zephyr.sh`; consumer `mounts` |
| 2026-09-11 | [0004](adr/0004-containerenv-only-config.md) containerEnv is the consumer's only configuration | [0002](rfc/0002-shared-sdk-volume.md) | `c7508fb` | `scripts/setup-sdks.sh`, `scripts/fetch-zephyr.sh`, `_zephyr_env_version` in `Dockerfile.devel` |
| 2026-09-11 | [0005](adr/0005-scripts-in-image.md) Runtime scripts ship in the devel image | [0001](rfc/0001-image-split.md) | `c7508fb` | `Dockerfile.devel` (`COPY scripts/ /opt/devcontainer/`) |
| 2026-09-11 | [0006](adr/0006-registry-cache-and-pushed-base.md) Push base, and cache layers in the registry | [0001](rfc/0001-image-split.md) | `c7508fb` | `.github/workflows/publish-images.yml` |
| 2026-09-11 | [0007](adr/0007-tag-by-zephyr-sdk-pair.md) Tag images by their Zephyr/SDK pair | [0001](rfc/0001-image-split.md) | `c7508fb` | `publish-images.yml` (`pair=z<zephyr>-sdk<sdk>`), `versions.env` |
| 2026-09-11 | [0008](adr/0008-hardware-tools-in-devel.md) Hardware tools in devel; flashing runs on a self-hosted runner inside it | [0001](rfc/0001-image-split.md) | `c7508fb`, `c9a89c4` | `Dockerfile.devel` (nrfutil, J-Link, `/actions-runner`) |
| 2026-09-11 | [0009](adr/0009-ci-toolchains-union.md) ci bakes the union of every consumer's toolchains | [0001](rfc/0001-image-split.md) | `c7508fb` | `versions.env` (`ZSDK_TOOLCHAINS`), `Dockerfile.ci` |
| 2026-09-11 | [0010](adr/0010-sentinels-and-store-lock.md) Complete-markers and a lock for the shared store | [0002](rfc/0002-shared-sdk-volume.md) | `c7508fb` | `scripts/setup-sdks.sh`, `scripts/fetch-zephyr.sh` (`.complete`, `flock`) |
| 2026-09-11 | [0011](adr/0011-shell-helpers-env-only.md) Shell helpers only change environment variables | [0002](rfc/0002-shared-sdk-volume.md) | `c7508fb` | `use-vanilla`, `use-ncs`, `reset-ncs` in `Dockerfile.devel` |
| 2026-09-11 | [0012](adr/0012-one-venv-newest-zephyr.md) One Python venv, pinned to the newest Zephyr in use | [0002](rfc/0002-shared-sdk-volume.md) | `c7508fb`, `c9cd6a3` | `Dockerfile.base` (`ZEPHYR_REQ_REF`) |
| 2026-09-11 | [0013](adr/0013-linux-amd64-only.md) Images are linux/amd64 only | [0001](rfc/0001-image-split.md) | `c7508fb` | `Dockerfile.*` (x86_64 downloads), README "macOS" |
| 2026-09-15 | [0014](adr/0014-cmake-registry-volume.md) CMake package registry on a per-project volume | [0002](rfc/0002-shared-sdk-volume.md) | `cd58671` | consumer `mounts` (`<project>-cmake-registry` -> `/root/.cmake`), `scripts/register-sdks.sh` |
| 2026-09-24 | [0015](adr/0015-git-http1-and-retries.md) Fetch git over HTTP/1.1, and retry network steps | [0003](rfc/0003-fetch-on-bad-links.md) | `8011385` | `scripts/fetch-zephyr.sh` (`GIT_CONFIG_*`, `retry`) |
| 2026-09-27 | [0016](adr/0016-seeded-fetch.md) Build a new Zephyr version from one already in the store | [0003](rfc/0003-fetch-on-bad-links.md) | `37180aa`, `89d04b9` | `seed_repo`, `seed_clone`, `--path-cache` in `scripts/fetch-zephyr.sh` |
| 2026-09-27 | [0017](adr/0017-emulators-in-base.md) Emulators in base, with launchers for real boards | [0004](rfc/0004-emulation.md) | `8e3fb73`, `6ee9dbd` | `Dockerfile.base`, `scripts/emu/` |
| 2026-09-27 | [0018](adr/0018-lf-line-endings.md) LF line endings, enforced at image build | [0005](rfc/0005-devel-build-hygiene.md) | `89d04b9` | `.gitattributes`, CRLF checks in `Dockerfile.base` and `Dockerfile.devel` |
| 2026-09-27 | [0019](adr/0019-vendor-downloads-stage.md) Vendor downloads in their own build stage | [0005](rfc/0005-devel-build-hygiene.md) | `c9a89c4` | `Dockerfile.devel` (`FROM ubuntu:24.04 AS downloads`) |
| 2026-10-01 | [0020](adr/0020-mcumgr-from-source.md) Build the mcumgr CLI from source at a pinned commit | [0005](rfc/0005-devel-build-hygiene.md) | `a92693d` | `Dockerfile.devel` (`FROM golang:1.22-bookworm AS mcumgr`) |
| 2026-10-28 | *Proposed:* rename `emu` to `emulator`, smoke test in pytest | [0006](rfc/0006-emulator-naming-and-pytest.md) | – | `scripts/emu/`, `test/emu-smoke.sh` |

## Keeping it traceable

- A change that makes or reverses a decision gets an ADR (and an RFC when it needs evidence), a
  row here, and the ADR number in its commit message, e.g. `adr-0021: ...`.
- A reversed decision keeps its row; its ADR's status becomes "Superseded by NNNN".
- When a file moves, update **Implemented in** here and in the ADR.
