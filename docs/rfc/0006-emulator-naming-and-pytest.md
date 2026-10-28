# RFC 0006: Rename emu- to emulator-, smoke test in pytest

- **Status:** Proposed
- **Date:** 2026-10-28
- **Related:** RFC [0004](0004-emulation.md), `DEVELOPMENT.md`

## Summary

Two plans from `DEVELOPMENT.md`: spell out the `emu` abbreviation, and rewrite
`test/emu-smoke.sh` as a pytest suite.

## Findings

1. `emu` is used for `scripts/emu/`, `/opt/devcontainer/emu/`, `test/emu-smoke.sh` and the
   `build/emu-<name>` directories; it is not obvious to a newcomer.
2. `test/emu-smoke.sh` parses its own target table, keeps its own PASS/FAIL list and greps
   output by hand. pytest is already in base (Zephyr's test requirements) and would give
   parametrised targets, `-k` selection and JUnit XML for CI.

## Proposal

| Today | Proposed |
|---|---|
| `scripts/emu/` | `scripts/emulator/` |
| `/opt/devcontainer/emu/` | `/opt/devcontainer/emulator/` |
| `test/emu-smoke.sh` | `test/emulator-smoke-test.py` (pytest) |
| `build/emu-<name>` | `build/emulator-<name>` |

The launcher names `renode-nrf-run` and `qemu-esp-run` stay: consumers' `tasks.json` call them.

## Open questions

- Keep a `/opt/devcontainer/emu` symlink for one release, for anyone who hard-coded the path?
- Should the ci image run the pytest suite as part of publishing, before pushing `latest`?
