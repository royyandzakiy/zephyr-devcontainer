#!/usr/bin/env bash
# postStartCommand: ensure the Zephyr version this project wants is in the shared
# volume, then register it. First start on a machine takes ~10 min; every start
# after that, in any project sharing zephyr-sdks-cache, takes seconds.
#
# Baked into the devel image at /opt/devcontainer, so a consuming project needs
# no copy of this file -- only a devcontainer.json.
#
# CONFIG COMES ENTIRELY FROM containerEnv. There is no versions.env: ZEPHYR_BASE
# and ZEPHYR_SDK_INSTALL_DIR must be set in devcontainer.json anyway (the VS Code
# extension host cannot read an env file), and both version numbers are
# recoverable from those paths. One source of truth means nothing can desync, so
# the guard that used to live here is gone.
#
#   ZEPHYR_BASE=<store>/v4.4.2/zephyr                    -> ZEPHYR_VERSION=v4.4.2
#   ZEPHYR_SDK_INSTALL_DIR=<store>/.../zephyr-sdk-1.0.1  -> ZSDK_VERSION=1.0.1
#   ZSDK_TOOLCHAINS   which SDK toolchains to install
#   ZEPHYR_BLOBS      modules whose binary blobs to fetch (optional)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

for v in ZEPHYR_BASE ZEPHYR_SDK_INSTALL_DIR ZSDK_TOOLCHAINS; do
    if [ -z "${!v:-}" ]; then
        echo "ERROR: $v is not set -- it belongs in containerEnv in devcontainer.json." >&2
        exit 1
    fi
done

ZEPHYR_VERSION="$(basename "$(dirname "$ZEPHYR_BASE")")"
ZSDK_VERSION="$(basename "$ZEPHYR_SDK_INSTALL_DIR" | sed 's/^zephyr-sdk-//')"

STORE=/workdir/zephyr-sdks
ZEPHYR_WS="$STORE/$ZEPHYR_VERSION"
SDK_DIR="$STORE/toolchains/zephyr-sdk-$ZSDK_VERSION"

mkdir -p "$STORE"

# Two containers starting at once must not both populate the store -- concurrent
# west updates into one directory produce a corrupt workspace.
exec 9>"$STORE/.lock"
if ! flock -w 1800 9; then
    echo "ERROR: timed out waiting for another container to finish populating $STORE" >&2
    exit 1
fi

# SDK 0.17.x puts toolchains at <sdk>/<triple>; SDK 1.0.x moved them under a
# variant directory, <sdk>/gnu/<triple>. Accept either, and any future variant.
sdk_has_toolchain() {
    local sdk="$1" t="$2" p
    [ -d "$sdk/$t" ] && return 0
    for p in "$sdk"/*/"$t"; do [ -d "$p" ] && return 0; done
    return 1
}

# --- Adopt installs made before the sentinels existed -------------------------
# A volume provisioned by the old scripts has no .complete marker; stamp one if
# the install looks finished, so upgrading does not force a refetch. The checks
# are narrow on purpose: a half-extracted SDK has the directory but no setup.sh
# or Zephyr-sdkConfig.cmake, so it is not adopted and gets refetched below.
if [ ! -f "$SDK_DIR/.complete" ] \
   && [ -f "$SDK_DIR/setup.sh" ] \
   && [ -f "$SDK_DIR/cmake/Zephyr-sdkConfig.cmake" ]; then
    echo "=== Adopting existing Zephyr SDK $ZSDK_VERSION ==="
    touch "$SDK_DIR/.complete"
fi
if [ ! -f "$ZEPHYR_WS/.complete" ] \
   && [ -f "$ZEPHYR_WS/zephyr/VERSION" ] \
   && [ -d "$ZEPHYR_WS/.west" ] \
   && [ -d "$ZEPHYR_WS/modules/hal/espressif" ]; then
    echo "=== Adopting existing Zephyr $ZEPHYR_VERSION workspace ==="
    touch "$ZEPHYR_WS/.complete"
fi

# --- Populate on first use ---------------------------------------------------
need_zephyr=0
need_sdk=0
fresh_install=0
[ -f "$ZEPHYR_WS/.complete" ] || { need_zephyr=1; fresh_install=1; }
[ -f "$SDK_DIR/.complete" ] || { need_sdk=1; fresh_install=1; }

# Another project may have provisioned the shared store with a shorter
# ZSDK_TOOLCHAINS; fetch-zephyr.sh adds the missing ones incrementally.
if [ "$need_sdk" -eq 0 ]; then
    for t in $ZSDK_TOOLCHAINS; do
        if ! sdk_has_toolchain "$SDK_DIR" "$t"; then
            echo "=== Toolchain $t missing from the shared SDK -- installing ==="
            need_sdk=1
        fi
    done
fi

if [ "$fresh_install" -eq 1 ]; then
    cat <<BANNER

  ============================================================================
   FIRST RUN ON THIS MACHINE

   Installing into the shared volume. Takes up to 10 minutes and needs a
   network connection. Once per machine, not once per project -- every later
   project using these versions starts in seconds.
  ============================================================================

BANNER
fi

if [ "$need_zephyr" -eq 1 ] || [ "$need_sdk" -eq 1 ]; then
    ZEPHYR_STORE_LOCKED=1 FETCH_SKIP_REGISTER=1 \
        bash "$HERE/fetch-zephyr.sh" \
            "$([ "$need_zephyr" -eq 1 ] && echo "$ZEPHYR_VERSION" || echo "")" \
            "$([ "$need_sdk" -eq 1 ] && echo "$ZSDK_VERSION" || echo "")"
fi

# --- Verify ------------------------------------------------------------------
echo "=== Verifying Zephyr environment ==="

fail=0
if [ -f "$ZEPHYR_WS/zephyr/VERSION" ]; then
    echo "  Zephyr:      $ZEPHYR_WS/zephyr"
else
    echo "  ERROR: no Zephyr checkout at $ZEPHYR_WS/zephyr" >&2
    fail=1
fi

# hal/espressif is fetched late in west update, so its absence hints at a
# truncated one.
if [ ! -d "$ZEPHYR_WS/modules/hal/espressif" ]; then
    echo "  WARNING: $ZEPHYR_WS/modules/hal/espressif missing -- west update may be incomplete" >&2
fi

if [ -d "$SDK_DIR" ]; then
    echo "  Zephyr SDK:  $SDK_DIR"
    if [ ! -f "$SDK_DIR/cmake/Zephyr-sdkConfig.cmake" ]; then
        echo "  ERROR: $SDK_DIR/cmake/Zephyr-sdkConfig.cmake missing" >&2
        fail=1
    fi
    for t in $ZSDK_TOOLCHAINS; do
        if sdk_has_toolchain "$SDK_DIR" "$t"; then
            echo "               $t"
        else
            echo "  ERROR: toolchain $t not installed in $SDK_DIR" >&2
            fail=1
        fi
    done
else
    echo "  ERROR: no Zephyr SDK at $SDK_DIR" >&2
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    cat >&2 <<'HINT'

The shared volume is incomplete. Delete the broken piece and reopen the
container -- the .complete sentinels mean only that part is refetched:

    rm -rf /workdir/zephyr-sdks/<version>            # or .../toolchains/zephyr-sdk-<ver>

Or start over entirely (full ~10 min download):

    docker volume rm zephyr-sdks-cache

HINT
    exit 1
fi

# --- Re-register on every start ----------------------------------------------
# ~/.cmake is in the container's throwaway layer even though the SDK persists, so
# without this the nRF Connect SDK picker is empty after a rebuild.
echo "=== Setting up Zephyr SDK host tools ==="
# Output captured, not discarded: swallowing it once left an exit-30 "Host tools
# installation failed" with no explanation anywhere.
if ! (cd "$SDK_DIR" && ./setup.sh -h -c) > /tmp/zephyr-sdk-setup.log 2>&1; then
    echo "ERROR: $SDK_DIR/setup.sh -h -c failed:" >&2
    cat /tmp/zephyr-sdk-setup.log >&2
    exit 1
fi

bash "$HERE/register-sdks.sh"

# The registry is FindZephyr-sdk.cmake's only fallback when ZEPHYR_SDK_INSTALL_DIR
# is absent from a subprocess env. Empty means an opaque build failure later.
if ! ls "${HOME}/.cmake/packages/Zephyr-sdk/"* >/dev/null 2>&1; then
    echo "ERROR: no Zephyr-sdk entry in ${HOME}/.cmake/packages -- builds will fail" >&2
    echo "       to locate the SDK whenever ZEPHYR_SDK_INSTALL_DIR is not set." >&2
    exit 1
fi
