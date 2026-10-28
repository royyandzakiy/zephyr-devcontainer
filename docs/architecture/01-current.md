# Stage 1: Current, living document

- **Period:** 2026-09-11 – now (last updated 2026-10-28)
- **Code:** this repository, `HEAD`
- **Shaped by:** ADR [0001](../adr/0001-build-from-ubuntu.md) – [0020](../adr/0020-mcumgr-from-source.md);
  RFC [0001](../rfc/0001-image-split.md) – [0005](../rfc/0005-devel-build-hygiene.md)

> Update this file when the architecture changes; see [Updating](README.md#updating).

## Summary

This repository publishes two images to GHCR, both built from a shared `base`. `devel` is what a
project's `devcontainer.json` runs: it carries the tools and scripts, and fetches the Zephyr tree
and SDK the project asks for into a volume shared by every project on the machine. `ci` has one
Zephyr/SDK pair baked in for GitHub-hosted jobs. Flashing runs on a self-hosted runner inside a
devel container. Both images can run firmware in Renode or Espressif QEMU.

## Context (C4 level 1)

```mermaid
flowchart TB
    dev(["Firmware developer"]):::person
    maint(["Maintainer"]):::person
    repo["zephyr-devcontainer<br/>Dockerfiles, scripts, versions.env"]:::system
    ghcr["GHCR<br/>devel, ci, base, :buildcache"]:::external
    gha["GitHub Actions<br/>publish-images.yml"]:::external
    proj["Consuming project<br/>.devcontainer/devcontainer.json,<br/>.github/workflows"]:::external
    up["Upstreams<br/>Zephyr + modules, SDK, Nordic,<br/>Renode, Espressif QEMU"]:::external
    board["Dev board<br/>USB, J-Link"]:::external

    maint -->|"push to main"| repo
    repo --> gha
    gha -->|"push images"| ghcr
    gha -->|"download at build"| up
    dev -->|"Reopen in Container"| proj
    proj -->|"pull devel / ci"| ghcr
    proj -->|"first start: fetch Zephyr + SDK"| up
    proj -->|"flash, debug"| board

    classDef person fill:#08427b,color:#fff,stroke:#052e56
    classDef system fill:#1168bd,color:#fff,stroke:#0b4884
    classDef external fill:#999,color:#fff,stroke:#6b6b6b
```

## Containers (C4 level 2): images, volumes, runners

```mermaid
flowchart TB
    subgraph images["Images (linux/amd64)"]
        base["base<br/>ubuntu:24.04 + build tools,<br/>Python venv, emulators"]:::container
        ci["ci<br/>+ Zephyr tree and SDK baked<br/>in /opt/zephyr-sdks"]:::container
        devel["devel<br/>+ hardware tools, Actions runner,<br/>editor tools, /opt/devcontainer"]:::container
        base --> ci
        base --> devel
    end

    subgraph machine["Developer machine"]
        dc["devel container<br/>one per open project"]:::container
        runner["self-hosted runner<br/>inside a devel container"]:::container
        zv[("zephyr-sdks volume<br/>shared by all projects")]:::external
        nv[("ncs-sdks volume<br/>shared")]:::external
        cv[("&lt;project&gt;-cmake-registry<br/>volume")]:::external
    end

    hosted["GitHub-hosted job<br/>container: ci"]:::external

    devel -.->|runs as| dc
    devel -.->|runs as| runner
    ci -.->|runs as| hosted
    dc -->|/workdir/zephyr-sdks| zv
    dc -->|/workdir/ncs-sdks| nv
    dc -->|/root/.cmake| cv
    runner --> zv

    classDef container fill:#438dd5,color:#fff,stroke:#2e6295
    classDef external fill:#999,color:#fff,stroke:#6b6b6b
```

| Image | Consumer | Has the SDK? | Size |
|---|---|---|---|
| `base` | `ci` and `devel` builds only (private) | no | ~3.2 GB |
| `devel` | `devcontainer.json`, self-hosted runner | no, fetched into `zephyr-sdks` | ~4.8 GB |
| `ci` | `container:` of GitHub-hosted jobs | yes, the pair in `versions.env` | ~14 GB |

Configuration flows in two separate directions, and they never meet:

- **This repository's `versions.env`** sets what `ci` bakes, the `ZSDK_TOOLCHAINS` union and the
  image tag (ADR [0007](../adr/0007-tag-by-zephyr-sdk-pair.md), [0009](../adr/0009-ci-toolchains-union.md)).
- **A consumer's `containerEnv`** sets what `devel` fetches at start
  (ADR [0004](../adr/0004-containerenv-only-config.md)).

## Components (C4 level 3)

```mermaid
flowchart TB
    subgraph b["base"]
        tools["apt: gcc(-multilib), cmake, ninja, dtc,<br/>gdb, valgrind, sparse, SDL2/fuse i386"]:::container
        venv["/opt/python-venv<br/>west, Zephyr requirements, esptool,<br/>Robot Framework"]:::container
        renode["/opt/renode<br/>renode, renode-test, SVD cache"]:::container
        qemu["/opt/qemu-esp<br/>qemu-system-xtensa-esp"]:::container
        emu["/opt/devcontainer/emu<br/>renode-nrf-run, qemu-esp-run,<br/>nrf52840.resc"]:::container
        emu --> renode
        emu --> qemu
    end

    subgraph d["devel"]
        setup["setup-sdks.sh<br/>postStartCommand"]:::container
        fetch["fetch-zephyr.sh<br/>clone / seed, west update, SDK"]:::container
        reg["register-sdks.sh<br/>~/.cmake/packages"]:::container
        ncs["ncs.py<br/>nrfutil toolchain-manager"]:::container
        sh["~/.bashrc helpers<br/>use-vanilla, use-ncs,<br/>reset-ncs, zephyr-stores"]:::container
        hw["nrfutil, J-Link, mcumgr,<br/>picocom, dfu-util"]:::container
        ed["clangd, clang-tidy,<br/>clang-format, nano, vi"]:::container
        ar["/actions-runner"]:::container
        setup --> fetch
        setup --> reg
        sh --> ncs
        ncs --> hw
    end

    subgraph c["ci"]
        baked["/opt/zephyr-sdks/&lt;ver&gt;<br/>/opt/zephyr-sdks/toolchains/zephyr-sdk-&lt;ver&gt;"]:::container
    end

    zv[("zephyr-sdks")]:::external
    nv[("ncs-sdks")]:::external
    cv[("~/.cmake")]:::external
    fetch --> zv
    reg --> cv
    ncs --> nv
    sh -->|"search order"| zv
    sh -.->|"then"| baked

    classDef container fill:#438dd5,color:#fff,stroke:#2e6295
    classDef external fill:#999,color:#fff,stroke:#6b6b6b
```

| Component | File |
|---|---|
| Build tools, venv, emulators, launcher install and checks | `Dockerfile.base` |
| Emulator launchers and machine descriptions | `scripts/emu/` |
| Baked Zephyr/SDK | `Dockerfile.ci` |
| Downloads stage, mcumgr stage, hardware/editor tools, shell helpers | `Dockerfile.devel` |
| First-start install, verify, register | `scripts/setup-sdks.sh`, `fetch-zephyr.sh`, `register-sdks.sh` |
| nRF Connect SDK install and environment | `scripts/ncs.py` |
| Image build and publish | `build.sh`, `.github/workflows/publish-images.yml`, `.devcontainer/devcontainer.json` |
| Emulator smoke test | `test/app/`, `test/emu-smoke.sh` |

## Key flow: publishing

```mermaid
sequenceDiagram
    actor M as Maintainer
    participant W as publish-images.yml
    participant G as GHCR

    M->>W: push to main (or dispatch)
    W->>W: source versions.env -> pair z<zephyr>-sdk<sdk>
    W->>G: build + push base:pair (cache base:buildcache)
    par
        W->>G: build devel FROM base:pair, push devel:pair + latest
    and
        W->>G: build ci FROM base:pair (bake Zephyr + SDK), push ci:pair + latest
    end
    Note over G: devel and ci public, base private
```

## Key flow: first start of a devel container

```mermaid
sequenceDiagram
    participant V as VS Code
    participant C as devel container
    participant S as setup-sdks.sh
    participant F as fetch-zephyr.sh
    participant Z as zephyr-sdks volume
    participant U as GitHub / SDK releases

    V->>C: create, with containerEnv + mounts
    C->>S: postStartCommand
    S->>S: versions from ZEPHYR_BASE / ZEPHYR_SDK_INSTALL_DIR paths
    S->>Z: flock .lock
    S->>Z: .complete for <ver> and zephyr-sdk-<ver>?
    alt missing
        S->>F: fetch the missing half
        F->>Z: seed from newest complete v*/zephyr, if any
        F->>U: fetch tag (or full clone), west update --path-cache
        F->>U: SDK minimal + ZSDK_TOOLCHAINS, blobs
        F->>Z: write .complete
    end
    S->>S: verify, setup.sh -h -c
    S->>C: register-sdks.sh -> /root/.cmake
    Note over V,C: new shells run use-vanilla, which only sets env vars
```

## Key flow: running firmware in an emulator

```mermaid
flowchart LR
    wb["west build -b &lt;board&gt;"] --> bd["build/"]
    bd --> rn{"board"}
    rn -->|nrf52840| r1["renode-nrf-run<br/>&lt;app&gt;/boards/&lt;board&gt;.resc<br/>or emu/&lt;soc&gt;.resc"]
    rn -->|esp32, esp32s3| q1["qemu-esp-run<br/>merge flash at runners.yaml offset,<br/>eFuse image rev 3"]
    r1 --> out["UART on terminal<br/>--gdb, --timeout"]
    q1 --> out
```

## Decisions

| Area | ADR |
|---|---|
| Image layout and contents | [0001](../adr/0001-build-from-ubuntu.md), [0002](../adr/0002-ci-and-devel-siblings.md), [0008](../adr/0008-hardware-tools-in-devel.md), [0013](../adr/0013-linux-amd64-only.md), [0017](../adr/0017-emulators-in-base.md), [0020](../adr/0020-mcumgr-from-source.md) |
| Where the SDK lives and how it is configured | [0003](../adr/0003-sdk-in-shared-volume.md), [0004](../adr/0004-containerenv-only-config.md), [0009](../adr/0009-ci-toolchains-union.md), [0012](../adr/0012-one-venv-newest-zephyr.md) |
| Runtime scripts | [0005](../adr/0005-scripts-in-image.md), [0010](../adr/0010-sentinels-and-store-lock.md), [0011](../adr/0011-shell-helpers-env-only.md), [0014](../adr/0014-cmake-registry-volume.md) |
| Fetching | [0015](../adr/0015-git-http1-and-retries.md), [0016](../adr/0016-seeded-fetch.md) |
| Building and publishing | [0006](../adr/0006-registry-cache-and-pushed-base.md), [0007](../adr/0007-tag-by-zephyr-sdk-pair.md), [0018](../adr/0018-lf-line-endings.md), [0019](../adr/0019-vendor-downloads-stage.md) |

## Known limits

- `linux/amd64` only; on Apple Silicon emulated and without USB.
- `build.sh`, `.devcontainer/devcontainer.json` and `publish-images.yml` build the same images
  and are kept in step by hand.
- Republishing an unchanged tag is invisible to consumers who already pulled it.
- The publish workflow does not run `test/emu-smoke.sh`; it is run by hand in the devel container.
- Emulation limits (no radio in QEMU, partial Renode nRF52840 model, no MCUboot in
  `qemu-esp-run`, no ESP32-C3/C6) are in RFC [0004](../rfc/0004-emulation.md).
