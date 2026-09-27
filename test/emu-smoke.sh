#!/usr/bin/env bash
# Build test/app for each emulated board and check that it boots and keeps
# ticking. Run inside the devel or ci container:
#
#     bash test/emu-smoke.sh              # every target
#     bash test/emu-smoke.sh esp32s3      # just the ones whose name matches
#
# Uses whatever Zephyr/SDK the environment points at (containerEnv, or
# use-vanilla). Build dirs go to build/emu-<name>; the emulator output of each
# run is kept next to them as emu.out.
set -euo pipefail

cd "$(dirname "$0")/.."
APP=test/app
RUN_SECS="${RUN_SECS:-60}"   # upper bound per target
mkdir -p build

#        name     board                            launcher
TARGETS=("nrf52840 nrf52840dk/nrf52840            renode-nrf-run"
         "esp32    esp32_devkitc/esp32/procpu     qemu-esp-run"
         "esp32s3  esp32s3_devkitc/esp32s3/procpu qemu-esp-run")

results=()
fail=0
for t in "${TARGETS[@]}"; do
    read -r name board launcher <<< "$t"
    [ -n "${1:-}" ] && [[ "$name" != *"$1"* ]] && continue

    dir="build/emu-$name"
    echo "=== $name: $board via $launcher"
    # rm rather than `west build -p`: pristine still trips over a CMakeCache made
    # from another path, e.g. the same repo mounted elsewhere in another container.
    rm -rf "$dir"
    if ! west build -b "$board" "$APP" -d "$dir" > "$dir.build.log" 2>&1; then
        echo "    build failed -- $dir.build.log"
        results+=("FAIL  $name  (build)"); fail=1; continue
    fi

    # Stop as soon as tick 3 is out rather than always waiting RUN_SECS --
    # emulated ESP32-S3 is several times slower to get there than the others.
    # setsid gives the launcher its own process group, so the kill reaches the
    # emulator it started too.
    : > "$dir/emu.out"
    setsid "$launcher" "$dir" --timeout="$RUN_SECS" >> "$dir/emu.out" 2>&1 &
    pid=$!
    # 2>/dev/null: on a Windows bind mount, reading a file mid-write can fail
    # with ENODATA ("No data available"); the next poll reads it fine.
    while kill -0 "$pid" 2>/dev/null && ! grep -aq "emu-smoke: tick 3" "$dir/emu.out" 2>/dev/null; do
        sleep 0.5
    done
    kill -- -"$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true

    if grep -aq "emu-smoke: boot ok on $board" "$dir/emu.out" \
       && grep -aq "emu-smoke: tick 3" "$dir/emu.out"; then
        results+=("PASS  $name")
    else
        echo "    no boot banner / tick 3 in $RUN_SECS s -- $dir/emu.out:"
        tail -15 "$dir/emu.out" | sed 's/^/    | /'
        results+=("FAIL  $name  (run)"); fail=1
    fi
done

[ "${#results[@]}" -gt 0 ] || { echo "no target matches '$1'" >&2; exit 2; }
echo
printf '%s\n' "${results[@]}"
exit "$fail"
