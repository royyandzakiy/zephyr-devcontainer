# zephyr-devcontainer

Container images for Zephyr development and CI, published to GHCR. A project
that uses them needs **one file** — its own `.devcontainer/devcontainer.json`.
No scripts to copy, no submodule.

```
ghcr.io/royyandzakiy/zephyr-devcontainer-devel:z4.4.2-sdk1.0.1   the devcontainer
ghcr.io/royyandzakiy/zephyr-devcontainer-ci:z4.4.2-sdk1.0.1      GitHub Actions `container:`
```

## Using it in a project

```jsonc
{
  "name": "Zephyr Development",
  "image": "ghcr.io/royyandzakiy/zephyr-devcontainer-devel:z4.4.2-sdk1.0.1",
  "containerEnv": {
    "ZEPHYR_BASE": "/workdir/zephyr-sdks/v4.4.2/zephyr",
    "ZEPHYR_SDK_INSTALL_DIR": "/workdir/zephyr-sdks/toolchains/zephyr-sdk-1.0.1",
    "ZEPHYR_TOOLCHAIN_VARIANT": "zephyr",
    "ZSDK_TOOLCHAINS": "arm-zephyr-eabi x86_64-zephyr-elf",
    "ZEPHYR_BLOBS": ""
  },
  "mounts": [
    "source=zephyr-sdks,target=/workdir/zephyr-sdks,type=volume",
    "source=ncs-sdks,target=/workdir/ncs-sdks,type=volume",
    "source=${localWorkspaceFolderBasename}-cmake-registry,target=/root/.cmake,type=volume"
  ],
  "postStartCommand": "/opt/devcontainer/setup-sdks.sh"
}
```

**`containerEnv` is the only configuration.** There is no `versions.env` in a
consuming project. `ZEPHYR_BASE` and `ZEPHYR_SDK_INSTALL_DIR` have to be set
there anyway — the VS Code extension host cannot read an env file — and both
version numbers are recovered from those paths, so nothing can desync.

Pick any Zephyr/SDK pair you like: the devel image ships no SDK and fetches what
you ask for on first start.

## The volume

`zephyr-sdks` is mounted by name with **no project prefix**, so every
project shares it. Zephyr and the SDK are downloaded once per *machine*, not
once per project: first start ~10 minutes, every start after that seconds and no
network. Versions install side by side, so switching costs one download and
never a re-download.

Inside the container: `zephyr-stores` lists what is installed and where,
`use-vanilla <ver> <sdk>` switches the current shell, `use-ncs <ver>` switches to
an nRF Connect SDK, `reset-ncs` goes back to baseline.

## The images

`ci` and `devel` are **siblings** off `base`, not a chain — different consumers:

```
Dockerfile.base    build tools, Python venv, Zephyr's Python requirements
├─ Dockerfile.ci     + Zephyr SDK and tree BAKED IN     -> GitHub Actions only
└─ Dockerfile.devel  + flashing tools, Actions runner,  -> the devcontainer
                       editor tooling, /opt/devcontainer scripts
```

`ci` bakes the SDK because a hosted runner has no persistent volume. `devel` does
not, because it has one. Conversely `ci` carries no nrfutil or J-Link: jobs that
flash run `runs-on: [self-hosted, linux]` with no container, on a runner hosted
inside the `devel` container.

**Constraint:** the `ci` image's toolchain set is fixed at publish time, so
`ZSDK_TOOLCHAINS` in `versions.env` must be the **union** of what every consuming
project builds for. A hosted runner cannot add one at runtime. `devel` is
unaffected — it installs from the consumer's `ZSDK_TOOLCHAINS` at start.

Built ground-up from `ubuntu:24.04` rather than `zephyrprojectrtos/zephyr-build`
(~32 GB, mostly toolchains and emulators unused here). Sizes: base ~3.2 GB,
devel ~4.8 GB, ci ~14 GB.

## Developing on the images

```bash
bash build.sh              # base + devel, tagged :local
WITH_CI=1 bash build.sh    # also ci (large)
```

Or open this repo in its own devcontainer, which builds base + devel from source.

`versions.env` here is **not** consumer config — it only drives what `ci` bakes
and how images are tagged.

## Publishing

`.github/workflows/publish-images.yml` builds and pushes on every push to `main`,
or on manual dispatch. Tags are `z<zephyr>-sdk<sdk>` plus `latest`.

Things that are easy to get wrong, all learned the hard way:

- **`base` must be pushed, not `load`ed.** buildx's `docker-container` driver
  does not share the host daemon's image store, so `FROM ${BASE_IMAGE}` in the
  devel/ci builds resolves against a *registry*. A local tag is looked up as
  `docker.io/library/...` and fails with `pull access denied`.
- **Cache is registry-backed, not `type=gha`.** The Actions cache is capped at
  10 GB per repository; the ci image alone is ~14 GB.
- **New packages are private.** Flip `devel` and `ci` to public once by hand at
  `github.com/users/<owner>/packages`. There is no API for it.
- **Republishing an unchanged tag** leaves consumers on a cached copy with no
  signal. After such a fix, `docker pull` is required, not just a container
  rebuild. If consumers already have the tag, add a build suffix instead.
