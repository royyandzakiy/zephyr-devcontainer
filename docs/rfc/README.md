# RFCs

Design write-ups for significant changes and findings: what was wrong or needed (with evidence),
the architecture before and after, why this approach over the alternatives, and how it was
implemented and verified. Decisions that shape the architecture also get a short record in
[`../adr/`](../adr/README.md); the
[decision log](../README.md#decision-log) traces each one to its RFC, commit and file.

One chronological series. The **Origin** column says where each document comes from:

- **history**: written afterwards from the code, its comments and git history.
- **proposal**: written before the work, from the plans in `DEVELOPMENT.md`.

Older documents describe the repository as it was then; where today's differs, they say so
("Outcome").

| # | Title | Origin | Status | Date | ADRs |
|---|---|---|---|---|---|
| [0001](0001-image-split.md) | Images extracted from the workshop: base, ci, devel | history | Implemented | 2026-09-11 | [0001](../adr/0001-build-from-ubuntu.md), [0002](../adr/0002-ci-and-devel-siblings.md), [0005](../adr/0005-scripts-in-image.md), [0006](../adr/0006-registry-cache-and-pushed-base.md), [0007](../adr/0007-tag-by-zephyr-sdk-pair.md), [0008](../adr/0008-hardware-tools-in-devel.md), [0009](../adr/0009-ci-toolchains-union.md), [0013](../adr/0013-linux-amd64-only.md) |
| [0002](0002-shared-sdk-volume.md) | One shared SDK volume, configured only by containerEnv | history | Implemented | 2026-09-11 – 2026-09-15 | [0003](../adr/0003-sdk-in-shared-volume.md), [0004](../adr/0004-containerenv-only-config.md), [0010](../adr/0010-sentinels-and-store-lock.md), [0011](../adr/0011-shell-helpers-env-only.md), [0012](../adr/0012-one-venv-newest-zephyr.md), [0014](../adr/0014-cmake-registry-volume.md) |
| [0003](0003-fetch-on-bad-links.md) | Fetching Zephyr on a bad link: HTTP/1.1, retries, seeded clone | history | Implemented | 2026-09-24 – 2026-09-27 | [0015](../adr/0015-git-http1-and-retries.md), [0016](../adr/0016-seeded-fetch.md) |
| [0004](0004-emulation.md) | Emulation: Renode for nRF52840, Espressif QEMU for ESP32 | history | Implemented | 2026-09-27 | [0017](../adr/0017-emulators-in-base.md) |
| [0005](0005-devel-build-hygiene.md) | devel build hygiene: downloads stage, CRLF guard, mcumgr | history | Implemented | 2026-09-27 – 2026-10-01 | [0008](../adr/0008-hardware-tools-in-devel.md), [0018](../adr/0018-lf-line-endings.md), [0019](../adr/0019-vendor-downloads-stage.md), [0020](../adr/0020-mcumgr-from-source.md) |
| [0006](0006-emulator-naming-and-pytest.md) | Rename emu- to emulator-, smoke test in pytest | proposal | Proposed | 2026-10-28 | – |

## Format

Header (Status, Date, Commits, ADR, Related), then **Summary**, **Findings** (with evidence),
**Architecture**, **Alternatives**, **Implementation**, **Verification** / **Outcome**,
**Follow-ups**. Sections without content are left out.

## Writing a new one

Copy the newest RFC, take the next number, and add a row above. Write one when a change alters
what consumers see (image contents, tags, `devcontainer.json`), the structure of the images or
the publish pipeline, or needs evidence to justify; small fixes only need a commit message.
