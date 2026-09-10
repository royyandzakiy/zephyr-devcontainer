#!/usr/bin/env python3
import sys
import os
import json
import subprocess
from pathlib import Path

NCS_BASE_DIR = Path("/workdir/ncs-sdks")
# Points directly to /workdir/ncs-sdks/toolchains
TOOLCHAINS_DIR = NCS_BASE_DIR / "toolchains"
TOOLCHAINS_JSON = TOOLCHAINS_DIR / "toolchains.json"

def fail(msg: str):
    print(f'echo "Error: {msg}" >&2', flush=True)
    sys.exit(1)

def load_toolchains():
    if not TOOLCHAINS_JSON.exists():
        return []

    try:
        with open(TOOLCHAINS_JSON, "r") as f:
            data = json.load(f)
    except Exception:
        return []

    if isinstance(data, list):
        return data[0].get("toolchains", []) if data else []
    elif isinstance(data, dict):
        return data.get("toolchains", [])
    return []

def install_version(target_ver: str):
    sdk_dir = NCS_BASE_DIR / target_ver
    zephyr_dir = sdk_dir / "zephyr"

    # 1. Check if toolchain is registered in toolchains.json
    toolchains = load_toolchains()
    has_tc = any(target_ver in tc.get("ncs_versions", []) for tc in toolchains)

    if not has_tc:
        print(f'echo "--- Installing nRF Connect Toolchain for {target_ver} ---" >&2')
        # IMPORTANT: Passing NCS_BASE_DIR (/workdir/ncs-sdks) because nrfutil 
        # auto-appends '/toolchains' to this path.
        tc_cmd = f"nrfutil toolchain-manager install --ncs-version {target_ver} --install-dir {NCS_BASE_DIR}"
        if subprocess.run(tc_cmd, shell=True).returncode != 0:
            fail(f"Failed to install toolchain for {target_ver} via nrfutil")

    # 2. Fetch SDK sources via west if zephyr directory is missing
    if not zephyr_dir.exists():
        print(f'echo "--- Fetching Zephyr/NCS sources for {target_ver} ---" >&2')
        sdk_dir.mkdir(parents=True, exist_ok=True)
        west_cmd = (
            f"cd {sdk_dir} && "
            f"west init -m https://github.com/nrfconnect/sdk-nrf --mr {target_ver} . && "
            f"west update --narrow -o=--depth=1"
        )
        if subprocess.run(west_cmd, shell=True).returncode != 0:
            fail(f"Failed to fetch west repositories for {target_ver}")

    # Cleanup download archives to save space
    subprocess.run(f"rm -rf {TOOLCHAINS_DIR}/downloads/* {TOOLCHAINS_DIR}/tmp/*", shell=True)
    print(f'echo "--- SDK {target_ver} is ready ---" >&2')

def list_versions(toolchains):
    versions = set()
    for tc in toolchains:
        for ver in tc.get("ncs_versions", []):
            versions.add(ver)

    if not versions:
        print('echo "No installed nRF Connect SDK versions found in /workdir/ncs-sdks." >&2')
        print('echo "To install one, run: use-ncs <version>" >&2')
        sys.exit(0)

    ver_list = "\n".join(f"   - {v}" for v in sorted(versions))
    print(f'echo "Available nRF Connect SDK versions:\n{ver_list}\n\nUsage: use-ncs <version>" >&2')
    sys.exit(0)

def clean_path_var(var_name: str) -> str:
    raw_val = os.environ.get(var_name, "")
    if not raw_val:
        return ""
    entries = raw_val.split(":")
    return ":".join([e for e in entries if not e.startswith("/workdir/ncs-sdks/")])

def main():
    if len(sys.argv) < 2 or sys.argv[1].strip() in ("--list", "-l", ""):
        list_versions(load_toolchains())

    cmd_or_ver = sys.argv[1].strip()

    if cmd_or_ver == "install":
        if len(sys.argv) < 3:
            fail("Usage: ncs.py install <version> (e.g. ncs.py install v3.3.0)")
        install_version(sys.argv[2].strip())
        sys.exit(0)

    target_ver = cmd_or_ver
    toolchains = load_toolchains()

    # Find toolchain hash
    hash_dir = None
    for tc in toolchains:
        if target_ver in tc.get("ncs_versions", []):
            # Check bundle_id first, fallback to path if needed
            hash_dir = tc.get("identifier", {}).get("bundle_id") or tc.get("path")
            break

    # If missing, install dynamic SDK
    if not hash_dir:
        print(f'echo "SDK {target_ver} not found locally. Installing..." >&2')
        install_version(target_ver)
        toolchains = load_toolchains()
        for tc in toolchains:
            if target_ver in tc.get("ncs_versions", []):
                hash_dir = tc.get("identifier", {}).get("bundle_id") or tc.get("path")
                break

    if not hash_dir:
        fail(f"Could not locate toolchain bundle_id for {target_ver}")

    tc_path = TOOLCHAINS_DIR / hash_dir
    zephyr_base = NCS_BASE_DIR / target_ver / "zephyr"

    base_path = os.environ.get("_ORIG_PATH") or clean_path_var("PATH")
    base_ld = os.environ.get("_ORIG_LD_LIBRARY_PATH") or clean_path_var("LD_LIBRARY_PATH")

    ld_paths = f"{tc_path}/usr/local/lib:{tc_path}/opt/lib" + (f":{base_ld}" if base_ld else "")
    bin_paths = f"{tc_path}/usr/local/bin:{tc_path}/opt/bin:{tc_path}/bin:{base_path}"

    exports = [
        f'export NCS_TOOLCHAIN_PATH="{tc_path}"',
        f'export ZEPHYR_BASE="{zephyr_base}"',
        f'export ZEPHYR_SDK_INSTALL_DIR="{tc_path}/opt/zephyr-sdk"',
        f'export LD_LIBRARY_PATH="{ld_paths}"',
        f'export PATH="{bin_paths}"',
    ]

    # Initialize workspace binding if missing
    west_dir = zephyr_base.parent / ".west"
    if not west_dir.exists() and zephyr_base.exists():
        exports.append(f'(cd "{zephyr_base.parent}" && west init -l "{zephyr_base}" > /dev/null 2>&1)')

    zephyr_env = zephyr_base / "zephyr-env.sh"
    if zephyr_env.exists():
        exports.append(f'source "{zephyr_env}"')

    exports.append(f'echo "Switched to nRF Connect SDK {target_ver} (Toolchain: {hash_dir})"')
    print("\n".join(exports))

if __name__ == "__main__":
    main()