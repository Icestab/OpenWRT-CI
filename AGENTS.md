# AGENTS.md

## What this is
An OpenWRT CI/CD build system that compiles custom firmware via GitHub Actions and releases artifacts as GitHub Releases.

## Architecture
- **Reusable workflow**: `WRT-CORE.yml` is the shared build core; all target workflows call it via `workflow_call`.
- **Workflow chain**: `Auto-Clean` (daily 22:00 UTC) → triggers `QCA-AX6` + `OWRT-ALL` on completion.
- **Two source branches** from `VIKINGYFY/immortalwrt`: `main` for QCA targets, `owrt` for Mediatek/Rockchip/X86.

## Directory map
| Path | Purpose |
|------|---------|
| `.github/workflows/WRT-CORE.yml` | Reusable build logic (clone → feeds → packages → config → compile → release) |
| `.github/workflows/QCA-AX6.yml` | AX6/IPQ807X build, source branch `main` |
| `.github/workflows/OWRT-ALL.yml` | Mediatek/Rockchip/X86 builds, source branch `owrt` |
| `.github/workflows/WRT-TEST.yml` | Manual test build, all configs/sources selectable |
| `.github/workflows/Auto-Clean.yml` | Deletes old releases/tags daily |
| `.github/workflows/Cache-Clean.yml` | Clears GHA caches weekly |
| `Config/` | OpenWRT `.config` fragments — one per target platform |
| `Scripts/Packages.sh` | Clones custom packages into the build tree |
| `Scripts/Handles.sh` | Patches/fixes for specific packages after install |
| `Scripts/Settings.sh` | Injects default IP, SSID, password, theme, kernel config tweaks |
| `build-ax6.sh` | Standalone local build script (not used by CI) |

## Config system
- `.config` is assembled from `Config/<WRT_CONFIG>.txt` + `Config/GENERAL.txt`, then `Scripts/Settings.sh` appends runtime tweaks.
- Config naming: `{PLATFORM}-WIFI-{YES/NO}.txt` (e.g. `IPQ807X-WIFI-YES`, `MEDIATEK-WIFI-NO`).
- `WIFI-NO` configs trigger the `WRT_WIFI=wifi-no` env flag; Settings.sh uses this to swap DTS includes for nowifi variants.
- Qualcommax targets get extra NSS firmware handling and NSS feed disabling in Settings.sh.

## Key conventions
- **Variable prefix**: all build variables use `WRT_` (e.g. `WRT_CONFIG`, `WRT_IP`, `WRT_THEME`).
- **Build retry**: `make -j$(nproc) || make -j1 V=s` — first attempt parallel, second single-job with verbose output.
- **Test mode**: `WRT_TEST=true` generates `.config` only, skips download/compile/release.
- **Cache key**: `{WRT_CONFIG}-{WRT_INFO}-{WRT_HASH}` for ccache + staging_dir.
- **Feeds must be updated then installed** in that order: `./scripts/feeds update -a` then `./scripts/feeds install -a`.
- **CI env setup**: builds symlink `/mnt/build_wrt` to `$GITHUB_WORKSPACE/wrt` for disk space; requires `immortalwrt.org` init script.
- **Line endings**: enforced as LF for `.txt` and `.sh` via `.gitattributes`.

## Local development
- `bash build-ax6.sh` runs a full build locally on Ubuntu.
- Edit the variables in the "固定配置" section to change target device, source, IP, SSID, etc.
- Requires `apt install dos2unix python3-netifaces libfuse-dev curl jq` plus the immortalwrt init script.

## When adding a new target
1. Add a new `Config/<PLATFORM>-WIFI-{YES/NO}.txt` with the appropriate `CONFIG_TARGET_*` settings.
2. If it needs special Settings.sh logic, look for the platform detection patterns in that file.
3. Add a new caller workflow or extend the matrix in an existing one.
4. Follow the existing naming pattern for consistency with Wi-Fi detection logic.
