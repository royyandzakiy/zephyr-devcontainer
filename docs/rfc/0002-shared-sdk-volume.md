# RFC 0002: One shared SDK volume, configured only by containerEnv

- **Status:** Implemented
- **Date:** 2026-09-11 – 2026-09-15
- **Commits:** `c7508fb` (setup-sdks.sh, fetch-zephyr.sh, register-sdks.sh), `cd58671` (volume
  names, CMake registry volume)
- **ADR:** [0003](../adr/0003-sdk-in-shared-volume.md), [0004](../adr/0004-containerenv-only-config.md),
  [0010](../adr/0010-sentinels-and-store-lock.md), [0011](../adr/0011-shell-helpers-env-only.md),
  [0012](../adr/0012-one-venv-newest-zephyr.md), [0014](../adr/0014-cmake-registry-volume.md)

## Summary

The devel image ships no Zephyr tree or SDK. On first start, `setup-sdks.sh` installs the pair
the project asks for into a named volume shared by every project on the machine, and every start
after that takes seconds with no network. The project says what it wants only through
`containerEnv`.

## Findings

1. **A baked SDK fixes the version for every consumer.** Projects pin different Zephyr releases;
   one image per pair would multiply ~14 GB images.
2. **Per-project volumes download the same ~10 minutes of data once per project.**
3. **Two sources of truth desync.** Consumers had a `versions.env` and also had to set
   `ZEPHYR_BASE` and `ZEPHYR_SDK_INSTALL_DIR` in `containerEnv`, because the VS Code extension
   host cannot read an env file. A guard in `setup-sdks.sh` existed only to catch the mismatch.
4. **A directory existing does not mean the install finished.** A `west update` that died half
   way left a workspace that looked ready forever.
5. **The nRF Connect SDK picker came up empty after a rebuild.** It reads the CMake user package
   registry (`~/.cmake/packages`), which lives in the throwaway container layer, and it enumerates
   once at activation, before `postStartCommand` re-registers anything.

## Architecture

```
devcontainer.json containerEnv
  ZEPHYR_BASE=/workdir/zephyr-sdks/v4.4.0/zephyr                 -> Zephyr v4.4.0
  ZEPHYR_SDK_INSTALL_DIR=/workdir/zephyr-sdks/toolchains/zephyr-sdk-1.0.1  -> SDK 1.0.1
  ZSDK_TOOLCHAINS, ZEPHYR_BLOBS

volume zephyr-sdks  -> /workdir/zephyr-sdks     (shared by every project)
  v4.4.0/{zephyr,modules,.west,.complete}
  toolchains/zephyr-sdk-1.0.1/{gnu/...,.complete}
  .lock
volume ncs-sdks     -> /workdir/ncs-sdks        (nRF Connect SDK, via use-ncs)
volume <project>-cmake-registry -> /root/.cmake
```

Versions are recovered from the two paths, so there is nothing to keep in step. Versions install
side by side; `use-vanilla <ver> <sdk>` switches a shell, `fetch-zephyr.sh` adds another pair.

## Alternatives

| Problem | Option | Why not |
|---|---|---|
| Where the SDK lives | Baked into devel | One image per pair; large pulls on every bump |
| | Per-project volume | Same download once per project |
| | **One named volume, no project prefix** (chosen) | Once per machine |
| Consumer config | `versions.env` in the project | VS Code cannot read it; needs `containerEnv` anyway |
| | **`containerEnv` only, versions from paths** (chosen) | One source of truth |
| Concurrent first starts | Hope | Two `west update`s into one directory corrupt it |
| | **`flock` on `<store>/.lock`, 30 min wait** (chosen) | |
| SDK picker empty | Re-register in `postStartCommand` only | Runs after the extension has cached the registry |
| | **Also mount `/root/.cmake` on a volume** (chosen) | Registry is populated at activation |

## Implementation (as executed)

1. `setup-sdks.sh` (`postStartCommand`): derive versions from the paths, take the store lock,
   adopt pre-sentinel installs that look complete, call `fetch-zephyr.sh` for what is missing,
   verify, run `setup.sh -h -c` with its log kept on failure, then `register-sdks.sh`.
2. `.complete` sentinels are written only after a step fully succeeds; deleting one piece
   refetches only that piece.
3. A shorter `ZSDK_TOOLCHAINS` from another project is topped up incrementally (`setup.sh -t`).
4. `cd58671`: volumes renamed from `zephyr-sdks-cache` / `ncs-sdks-cache` to `zephyr-sdks` /
   `ncs-sdks`; `<project>-cmake-registry` mounted at `/root/.cmake`.

## Verification

- First start on a fresh machine: ~10 minutes; later starts in any project: seconds, offline.
- `use-vanilla` resolves the workspace and SDK before calling `reset-ncs`, so a missing version
  leaves the shell unchanged.

## Follow-ups

- The single Python venv in base serves every Zephyr version in the volume, so it tracks the
  newest one used (4.4 added `jsonschema`; a 4.2.2 venv broke every 4.4 build).
