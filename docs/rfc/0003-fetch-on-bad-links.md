# RFC 0003: Fetching Zephyr on a bad link: HTTP/1.1, retries, seeded clone

- **Status:** Implemented
- **Date:** 2026-09-24 – 2026-09-27
- **Commits:** `8011385` (HTTP/1.1, retry), `37180aa` (seeded clone), `89d04b9` (seed for
  `west update --path-cache`)
- **ADR:** [0015](../adr/0015-git-http1-and-retries.md), [0016](../adr/0016-seeded-fetch.md)
- **Related:** RFC [0002](0002-shared-sdk-volume.md)

## Summary

`fetch-zephyr.sh` failed on slow or unstable connections, which is exactly where a ~10 minute
first download hurts most. It now forces HTTP/1.1 for git, retries network steps, and builds a
new Zephyr version from one already in the volume, fetching only the difference.

## Findings

1. **GitHub drops long HTTP/2 transfers on a slow link**: `curl 92 ... stream was not closed
   cleanly: CANCEL`, then `early EOF`. It killed the Zephyr clone at 24% twice in a row.
2. **Even over HTTP/1.1 the full clone kept dying**: `GnuTLS recv error` / `early EOF` after
   ~10 minutes, 6 of 6 attempts.
3. **Most of a new version is already on disk.** Switching between patch releases changes few
   module revisions, but each fetch started from nothing.
4. **A failed clone leaves a partial checkout** that the next attempt trips over.

## Architecture

```
clone_zephyr
  seed = newest complete v*/zephyr in the store (has .complete and .git), not the target
  seed?  git clone --no-checkout <seed>      (local, hardlinks objects, same volume)
         set-url origin github; fetch --depth 1 tag <ver>; checkout
         delete every ref except refs/tags/<ver>
         on failure -> fall back to a full clone
  else   git clone --depth 1 --branch <ver> github
west update --narrow -o=--depth=1 [--path-cache <seed workspace>]
```

## Alternatives

| Problem | Option | Why not |
|---|---|---|
| HTTP/2 resets | `git config --global http.version HTTP/1.1` | Changes the user's `~/.gitconfig` |
| | **`GIT_CONFIG_COUNT` / `KEY_0` / `VALUE_0` in the environment** (chosen) | west's git calls inherit it; nothing persists |
| Reusing the old version | `--reference` / `--shared` | Deleting the seed later would break the new checkout |
| | **Plain local clone, then fetch one tag** (chosen) | Hardlinked, independent of the seed |
| Modules | Full `west update` | Re-downloads ~50 modules that did not change |
| | **`west update --path-cache <seed>`** (chosen) | Clones each module from the seed, fetches the difference |

## Implementation (as executed)

1. `export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=http.version GIT_CONFIG_VALUE_0=HTTP/1.1`.
2. `retry` runs a network step up to 3 times, 10 s apart; everything else fails fast.
   `clone_zephyr` removes a partial checkout before each attempt.
3. `seed_repo` / `seed_clone` as above; refs from the seed are removed so `git describe` and
   west see a plain `clone --depth 1 --branch <ver>`.
4. `SEED` is computed once, before the retries, and passed to `west update --path-cache`.

## Verification

- On the link where the full clone failed 6 of 6 times, the seeded fetch took **11 s**.

## Follow-ups

- The first version on a machine still needs the full clone; there is no seed to start from.
