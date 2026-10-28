# ADR 0017: Emulators in base, with launchers for real boards

- **Status:** Accepted
- **Date:** 2026-09-27
- **RFC:** [0004](../rfc/0004-emulation.md)
- **Commits:** `8e3fb73`, `6ee9dbd`
- **Implemented in:** `Dockerfile.base`, `scripts/emu/`

## Context

Upstream QEMU has no esp32 machine, and Zephyr's `run_renode` target exists only for boards
whose `board.cmake` sets `RENODE_SCRIPT`, which `nrf52840dk` does not. CI should be able to run
emulated tests too.

## Decision

Install Renode (portable) and Espressif QEMU in **base**, so both ci and devel have them.
Link Espressif QEMU as `qemu-system-xtensa-esp` so the SDK's `qemu-system-xtensa` still serves
`qemu_xtensa`. `renode-nrf-run` picks `<app>/boards/<board>.resc` or a shipped `<soc>.resc`;
`qemu-esp-run` builds the flash and eFuse images. Renode's SVD cache is warmed at build time,
and Robot Framework is installed for `renode-test`.

## Alternatives considered

- devel only: CI could not run emulated smoke tests.
- Patch boards with `RENODE_SCRIPT`: copies of every board.

## Consequences

- Base grows by the two emulators.
- A new Renode SoC is one `.resc` in `scripts/emu/`.
