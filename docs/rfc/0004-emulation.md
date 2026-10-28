# RFC 0004: Emulation: Renode for nRF52840, Espressif QEMU for ESP32

- **Status:** Implemented
- **Date:** 2026-09-27
- **Commits:** `8e3fb73` (Renode, Espressif QEMU, launchers, test app, smoke test), `6f03e9d`,
  `6ee9dbd` (renode-test, Robot Framework)
- **ADR:** [0017](../adr/0017-emulators-in-base.md)

## Summary

Run firmware for real boards with no board attached, in the devcontainer and in CI. Two launchers
wrap the emulators so `west build` followed by `renode-nrf-run` or `qemu-esp-run` puts the UART on
the terminal, with optional GDB and timeout. A smoke test builds a small app for three boards and
checks it boots.

## Findings

1. **Zephyr's `run_renode` target only exists when `board.cmake` sets `RENODE_SCRIPT`**, and most
   real boards, `nrf52840dk` included, do not.
2. **Upstream QEMU (the SDK's) has no esp32 machine.** Espressif's fork does, but it boots a whole
   flash image, not an ELF, and the app offset differs (0x1000 on ESP32, 0x0 on ESP32-S3).
3. **QEMU reports chip revision 0 by default, which Zephyr refuses to boot.**
4. **Renode fetches SVD files from dl.antmicro.com on first use**, at ~1 KB/s at times, and fails
   offline. The first real `renode-nrf-run` timed out on it.
5. **`renode-test` stops at `No module named 'robot'`** without Robot Framework, so Twister's
   `harness: robot` suites could not run.

## Architecture

```
Dockerfile.base
  /opt/renode            Renode 1.17.0 portable (own .NET), sha256-checked
  /opt/qemu-esp          Espressif QEMU 9.2.2, linked as qemu-system-xtensa-esp
  /opt/devcontainer/emu/ renode-nrf-run, qemu-esp-run, nrf52840.resc
  Robot Framework (Renode's tests/requirements.txt), renode-test
  ~/.config/renode       SVD cache warmed for every platform a shipped .resc loads

renode-nrf-run [build] : .resc from <app>/boards/<board>.resc, else emu/<soc>.resc
                         UART -> PTY, Renode log -> <build>/renode.log
qemu-esp-run [build]   : merge zephyr.bin at the offset from runners.yaml,
                         write qemu_efuse.bin (rev 3 / 0.3), keep it if present
both                   : --gdb[=port], --timeout=sec

test/app + test/emu-smoke.sh : nrf52840dk, esp32, esp32s3 -> banner + 3 ticks
```

## Alternatives

| Problem | Option | Why not |
|---|---|---|
| Where the emulators live | devel only | CI jobs in the ci image could not run emulated smoke tests |
| | **base** (chosen) | Both images get them |
| QEMU name | `qemu-system-xtensa` | Would shadow the SDK's QEMU, which `qemu_xtensa` needs |
| | **`qemu-system-xtensa-esp`** (chosen) | |
| Renode for nRF | Add `RENODE_SCRIPT` to each board | Means copying boards |
| | **Launcher that picks a `.resc`** (chosen) | One file per SoC in `scripts/emu/` |
| SVD files | Fetch at runtime | Slow, fails offline |
| | **Warm the cache at image build** (chosen) | |

## Verification

- `bash test/emu-smoke.sh` passes for nrf52840, esp32 and esp32s3 in the devel container.
- The base image build checks both QEMU machines exist, `ldd` finds every library, both launchers
  answer `--help`, `pytest` and `robot` import, and the SVD cache is present.

## Follow-ups

- No Wi-Fi/Bluetooth in QEMU; Renode's radio only links nodes within one session.
- Renode's nRF52840 model is partial; Renode 1.17's GPIOTE misses the first falling edge on a pin
  that rests high (workaround in the README).
- `qemu-esp-run` does not take MCUboot builds yet.
- ESP32-C3/C6 need Espressif's `qemu-riscv32`, not included.
- Naming and the smoke test language: RFC [0006](0006-emulator-naming-and-pytest.md).
