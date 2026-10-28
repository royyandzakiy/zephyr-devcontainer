# RFC 0005: devel build hygiene: downloads stage, CRLF guard, mcumgr

- **Status:** Implemented
- **Date:** 2026-09-27 – 2026-10-01
- **Commits:** `89d04b9` (CRLF), `c9a89c4` (downloads stage), `8542dff` (nano, vim-tiny),
  `a92693d` (mcumgr)
- **ADR:** [0008](../adr/0008-hardware-tools-in-devel.md), [0018](../adr/0018-lf-line-endings.md),
  [0019](../adr/0019-vendor-downloads-stage.md), [0020](../adr/0020-mcumgr-from-source.md)

## Summary

Make the devel image cheap to rebuild and safe to edit from Windows: move the vendor downloads
into a stage that does not depend on base, refuse scripts with CRLF line endings at build time,
and add the mcumgr CLI for SMP / DFU over serial and BLE.

## Findings

1. **Every change to base or `scripts/` re-ran the Nordic downloads.** They sat on top of base, so
   any earlier layer change invalidated them; on a bad link that took 90+ minutes or failed.
   Nordic's server also drops connections mid-download (`Peer disconnected`).
2. **A CRLF script fails only at runtime**, with `$'\r': command not found`. `register-sdks.sh`
   was saved with CRLF once (Git for Windows sets `core.autocrlf=true`) and every `setup-sdks.sh`
   run failed at registration.
3. **No terminal editor** when VS Code is not attached (`docker exec`, the self-hosted runner).
4. **No mcumgr CLI** for talking to MCUboot / SMP devices from the container.

## Architecture

```
Dockerfile.devel
  stage downloads  FROM ubuntu:24.04   nrfutil (+toolchain-manager, device), J-Link,
                                       Actions runner 2.336.0          (retried x5)
  stage mcumgr     FROM golang:1.22    go install mynewt-mcumgr-cli@<commit>
  main             FROM base           apt tools, COPY --from both stages,
                                       scripts -> /opt/devcontainer, shell helpers
```

## Alternatives

| Problem | Option | Why not |
|---|---|---|
| Download cache | Keep on top of base, order layers carefully | Any base change still invalidates it |
| | **Separate stage from plain ubuntu** (chosen) | Cache survives base and script changes |
| CRLF | Ask contributors to configure git | Already failed once |
| | **`.gitattributes eol=lf` + build-time check** (chosen) | The build fails before a consumer does |
| mcumgr | Distro package | Not packaged for Ubuntu 24.04 |
| | **`go install` at a pinned commit in its own stage** (chosen) | No Go toolchain in the final image |

## Implementation (as executed)

1. `downloads` stage holds nrfutil, J-Link (64-bit library only) and the Actions runner; the
   main stage copies them to the same paths so nrfutil's components and J-Link's relative links
   stay valid, then links `JLinkExe` and runs `ldconfig`.
2. The build checks the J-Link library is 64-bit and `nrfutil device --version` runs.
3. `.gitattributes` forces LF for `*.sh`, `*.py`, `*.resc`, `*.env`, `Dockerfile.*`,
   `scripts/emu/*` and `test/app/**`; base and devel `grep -rl $'\r'` their scripts and fail.
4. `nano` and `vim-tiny` added; `mcumgr` from `apache/mynewt-mcumgr-cli@5c56bd2`.

## Verification

- `mcumgr version`, `nrfutil device --version` and the J-Link ELF check run during the build.
