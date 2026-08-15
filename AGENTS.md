# AGENTS.md

## What this is
An OpenWRT CI/CD build system that compiles custom firmware via GitHub Actions and releases artifacts as GitHub Releases. This is a personal fork of `VIKINGYFY/OpenWRT-CI`, focused on Redmi AX6 but also able to build the full platform matrix on demand.

## Architecture
- **Reusable workflow**: `WRT-CORE.yml` is the shared build core; every target workflow calls it via `workflow_call`.
- **Manual-trigger only**: all workflows are `workflow_dispatch`; there is no `schedule` / `workflow_run` automation in this fork.
- **Two source branches** from `VIKINGYFY/immortalwrt`: `main` for QCA targets, `owrt` for Mediatek/Rockchip/X86.

## Directory map
| Path | Purpose |
|------|---------|
| `.github/workflows/WRT-CORE.yml` | Reusable build logic (clone → feeds → packages → config → compile → release) |
| `.github/workflows/QCA-AX6.yml` | AX6-only build (`IPQ807X-WIFI-YES`), source branch `main` |
| `.github/workflows/QCA-ALL.yml` | QCA all devices (`IPQ60XX`/`IPQ807X` × `WIFI-YES/NO`), source branch `main` |
| `.github/workflows/MTK-ALL.yml` | Mediatek builds (`MEDIATEK-WIFI-YES/NO`), source branch `owrt` |
| `.github/workflows/OWRT-ALL.yml` | Rockchip/X86 builds (`ROCKCHIP`, `X86`), source branch `owrt` |
| `.github/workflows/WRT-TEST.yml` | Manual test build; config/source/branch selectable, generates `.config` by default |
| `.github/workflows/Auto-Clean.yml` | Deletes old releases/tags (manual) |
| `.github/workflows/Cache-Clean.yml` | Clears GHA caches (manual) |
| `Config/` | OpenWRT `.config` fragments — one per target platform |
| `Scripts/Packages.sh` | Clones custom packages into the build tree |
| `Scripts/Handles.sh` | Patches/fixes for specific packages after install |
| `Scripts/Settings.sh` | Injects default IP, SSID, password, theme, kernel config tweaks |

## Config system
- `.config` is assembled from `Config/<WRT_CONFIG>.txt` + `Config/GENERAL.txt`, then `Scripts/Settings.sh` appends runtime tweaks.
- `GENERAL.txt` is kept byte-identical with upstream. This fork's package differences live in `Config/PRIVATE.txt`, which Settings.sh appends to `.config` **after** `GENERAL.txt` — `make defconfig` then resolves duplicate symbols in favor of `PRIVATE.txt`.
- Config naming: `{PLATFORM}-WIFI-{YES/NO}.txt` (e.g. `IPQ807X-WIFI-YES`, `MEDIATEK-WIFI-NO`); `ROCKCHIP.txt`, `X86.txt`, `TEST.txt` use plain names.
- `WIFI-NO` configs trigger the `WRT_WIFI=wifi-no` env flag; Settings.sh uses this to swap DTS includes for nowifi variants.
- Qualcommax targets get extra NSS firmware handling and NSS feed disabling in Settings.sh.
- `IPQ807X-WIFI-YES.txt` is trimmed to only Redmi AX6 (`redmi_ax6` / `redmi_ax6-stock`) in this fork.

## Private extension hooks
- `Scripts/Packages.sh` sources `Scripts/PRIVATE.sh` if present — add custom `UPDATE_PACKAGE` calls there.
- `Scripts/Settings.sh` appends `Config/PRIVATE.txt` if present — add private `.config` overrides there.

## Key conventions
- **Variable prefix**: all build variables use `WRT_` (e.g. `WRT_CONFIG`, `WRT_IP`, `WRT_THEME`).
- **Build retry**: `make -j$(nproc) || make -j1 V=s` — first attempt parallel, second single-job with verbose output.
- **Test mode**: `WRT_TEST=true` generates `.config` only, skips download/compile/release.
- **Cache key**: `{WRT_CONFIG}-{WRT_INFO}-{WRT_HASH}` for ccache + staging_dir.
- **Feeds must be updated then installed** in that order: `./scripts/feeds update -a` then `./scripts/feeds install -a`.
- **CI env setup**: builds symlink `/mnt/build_wrt` to `$GITHUB_WORKSPACE/wrt` for disk space; requires `immortalwrt.org` init script.
- **Line endings**: enforced as LF for `.txt` and `.sh` via `.gitattributes`.

## When adding a new target
1. Add a new `Config/<PLATFORM>-WIFI-{YES/NO}.txt` with the appropriate `CONFIG_TARGET_*` settings.
2. If it needs special Settings.sh logic, look for the platform detection patterns in that file.
3. Add a new caller workflow or extend the matrix in an existing one.
4. Follow the existing naming pattern for consistency with Wi-Fi detection logic.
