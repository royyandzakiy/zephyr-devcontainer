# ADR 0011: Shell helpers only change environment variables

- **Status:** Accepted
- **Date:** 2026-09-11
- **RFC:** [0002](../rfc/0002-shared-sdk-volume.md)
- **Commits:** `c7508fb`
- **Implemented in:** `use-vanilla`, `use-ncs`, `reset-ncs` in `Dockerfile.devel`

## Context

`use-vanilla` used to run the SDK's `setup.sh -h -c` in every shell: ~7 s per prompt, it timed
out VS Code's shell-environment probe, and two concurrent runs (probe and `postStartCommand`)
made one exit 30 with `Host tools installation failed`.

## Decision

`use-vanilla`, `use-ncs` and `reset-ncs` only set or unset variables and source
`zephyr-env.sh`. `setup.sh -h -c` and registry writes happen once per start in `setup-sdks.sh`.
`use-vanilla` resolves both paths before resetting anything, so a failure leaves the shell
unchanged. `_ORIG_PATH` folds back entries VS Code adds after the probe, so `code` stays on PATH.

## Alternatives considered

- Run `setup.sh` per shell: slow and racy, as above.

## Consequences

- Opening a terminal is instant.
- `reset-ncs` must unset everything `nrfutil toolchain-manager env` sets (`NRFUTIL_HOME`, `PYTHONHOME`, ...).
