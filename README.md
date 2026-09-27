# zephyr-devcontainer

Container images for Zephyr development and CI, published to GHCR. A project
that uses them needs **one file** — its own `.devcontainer/devcontainer.json`.
No scripts to copy, no submodule.

```
ghcr.io/royyandzakiy/zephyr-devcontainer-devel:z4.4.0-sdk1.0.1   the devcontainer
ghcr.io/royyandzakiy/zephyr-devcontainer-ci:z4.4.0-sdk1.0.1      GitHub Actions `container:`
```

## Using it in a project

```jsonc
{
  "name": "Zephyr Development",
  "image": "ghcr.io/royyandzakiy/zephyr-devcontainer-devel:z4.4.0-sdk1.0.1",
  "containerEnv": {
    "ZEPHYR_BASE": "/workdir/zephyr-sdks/v4.4.0/zephyr",
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

### macOS

The current images run on `linux/amd64` only. To run them on Apple Silicon you
need to add `--platform=linux/amd64` to `runArgs`, though be aware this runs the
image emulated and makes builds roughly 3-5x slower.

Another note is that macOS does not allow USB passthrough into a container, so
the `/dev` mount has to go. You can still build and run `native_sim`, but you
cannot flash or debug a board directly from the devcontainer. A workaround is
you can simply open two vscode instances, one without the devcontainer activated, 
and flash the devcontainer produced firmware image from that instance.

```jsonc
"runArgs": [
  "--privileged",
  "--platform=linux/amd64"
],
...
"mounts": [
  ...
  // "source=/dev,target=/dev,type=bind,bind-propagation=rslave"  // remove on macOS
],
```

If you want the project to run on both, add a `.devcontainer/macos` folder next
to the default config. VS Code will ask which one to open.

```
.devcontainer/
├── devcontainer.json          Linux / Windows, with USB
└── macos/
    └── devcontainer.json      macOS, amd64 emulated, no USB
```

## The volume

`zephyr-sdks` is mounted by name with **no project prefix**, so every
project shares it. Zephyr and the SDK are downloaded once per *machine*, not
once per project: first start ~10 minutes, every start after that seconds and no
network. Versions install side by side, so switching costs one download and
never a re-download. Once any version is on the machine, the next one starts
from it and fetches only the difference from GitHub: seconds instead of ten
minutes, and far less for a flaky connection to break.

Inside the container: `zephyr-stores` lists what is installed and where,
`use-vanilla <ver> <sdk>` switches the current shell, `use-ncs <ver>` switches to
an nRF Connect SDK, `reset-ncs` goes back to baseline.

## Emulation

Both images can run firmware with no board attached. Build as usual, then point
the launcher at the build directory (`build` by default):

```bash
west build -b nrf52840dk/nrf52840 app && renode-nrf-run        # Renode
west build -b esp32_devkitc/esp32/procpu app && qemu-esp-run  # Espressif QEMU
```

The UART comes up on your terminal. Leave `renode-nrf-run` with Ctrl-A Ctrl-X and
`qemu-esp-run` with Ctrl-A X. Both launchers also take:

- `--gdb[=port]` starts halted with a GDB server (Renode :3333, QEMU :1234) and
  prints the GDB command to attach with.
- `--timeout=sec` exits after that many seconds, for CI. Grep the output:
  `qemu-esp-run --timeout=10 | grep -q "Hello World"`.

**`renode-nrf-run`** is for boards whose `board.cmake` has no `RENODE_SCRIPT`, which
means most real boards, `nrf52840dk` included, so Zephyr's `run_renode` target
does not exist for them. The machine comes from `<app>/boards/<board>.resc` if
the project has one (same name Zephyr uses), and otherwise from the shipped
`<soc>.resc`. Only `nrf52840.resc` ships for now. Adding another SoC means adding
one file in `scripts/emu/`, as long as Renode has a `platforms/cpus/<soc>.repl` for it.
Pick a different UART with `RENODE_UART=sysbus.uart1`. Renode's own log goes to
`build/renode.log`.

**`qemu-esp-run`** handles ESP32 and ESP32-S3. It merges `zephyr.bin` into a flash
image at the offset the build chose, and it writes an eFuse image that reports
a supported chip revision. Without that image QEMU reports rev 0, and Zephyr
refuses to boot on rev 0. The emulator is installed as `qemu-system-xtensa-esp`
so it does not shadow the SDK's `qemu-system-xtensa`. The `qemu_*` boards keep
using `west build -t run` as before.

Limits:
- No Wi-Fi or Bluetooth in `qemu-esp-run`: QEMU does not emulate the ESP32 radio.
  Renode does model the nRF52840 radio, but only between emulated nodes in one
  Renode session; `renode-nrf-run` starts a single node, so nothing answers it.
- Renode's nRF52840 model is partial. Unmodelled registers log a warning to
  `renode.log` and read back as zero, so check it when a driver misbehaves.
- `qemu-esp-run` does not take MCUboot builds yet, only simple boot.
- ESP32-C3/C6 (RISC-V) need Espressif's `qemu-riscv32` fork, which the images
  do not include.

To get this from VS Code, add these to the project's `.vscode/tasks.json`:

```jsonc
{ "label": "Run in Renode", "type": "shell", "command": "renode-nrf-run build", "problemMatcher": [] },
{ "label": "Run in QEMU",   "type": "shell", "command": "qemu-esp-run build", "problemMatcher": [] }
```

## The images

`ci` and `devel` are **siblings** off `base`, not a chain — different consumers:

```
Dockerfile.base    build tools, Python venv, Zephyr's Python requirements,
                   Renode + Espressif QEMU and their launchers
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
That tests uncommitted Dockerfile changes without publishing anything.

Inside it, `test/emu-smoke.sh` builds `test/app` for nrf52840dk, esp32 and
esp32s3. It runs each one in its emulator and checks for the boot banner and
three timer ticks:

```bash
bash test/emu-smoke.sh            # all targets, PASS/FAIL table at the end
bash test/emu-smoke.sh nrf        # only targets matching "nrf"
```

To use the app interactively, it has the Zephyr shell. Try `kernel uptime`:

```bash
west build -b nrf52840dk/nrf52840 test/app -d build/nrf && renode-nrf-run build/nrf
```

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
