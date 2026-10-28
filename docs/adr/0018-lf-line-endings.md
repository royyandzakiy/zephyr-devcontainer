# ADR 0018: LF line endings, enforced at image build

- **Status:** Accepted
- **Date:** 2026-09-27
- **RFC:** [0005](../rfc/0005-devel-build-hygiene.md)
- **Commits:** `89d04b9`
- **Implemented in:** `.gitattributes`, CRLF checks in `Dockerfile.base` and `Dockerfile.devel`

## Context

Git for Windows sets `core.autocrlf=true`. `register-sdks.sh` was saved with CRLF once and every
`setup-sdks.sh` run failed with `$'\r': command not found`.

## Decision

`.gitattributes` forces `eol=lf` for everything that runs in the container, and both images
fail the build if any shipped script contains `\r`.

## Alternatives considered

- Rely on contributors' git settings: already failed once.

## Consequences

- A CRLF script fails the image build, not a consumer's container.
