# Neomobileshell

Windows-Phone-style shell for **Windows on ARM64 devices** (Redmi Note 9 Pro /
Poco M2 Pro / any WoA phone), built on top of
[MobileShell](https://github.com/ADeltaX/MobileShell) and made to actually work
on **Windows 11 ARM64**.

## What this is

Upstream MobileShell is a C++/XAML Islands project that brings back the
Windows 10 Mobile navigation bar, status bar, notification positioning and a
touch-first look. It was designed for Windows 10 — **on Windows 11 it never
activates**, because:

1. Windows 11 removed Tablet Mode. Upstream waited for the WNF state
   `WNF_TMCN_ISTABLETMODE`, which no longer fires.
2. The old build targets (CppWinRT 2.0.190730, Windows SDK 18362, toolset v140)
   don't build on modern VS2022/ARM64 toolchains.
3. The app manifest declared `processorArchitecture="amd64"`, which is wrong
   for ARM64 binaries.

This project vendors the [WOA-Project/MobileShell](https://github.com/WOA-Project/MobileShell)
fork (which already had Win11-era fixes) and adds a set of patches so the shell
reliably activates and runs on Windows 11 ARM64.

## Repository layout

```
mobile-shell/   vendored MobileShell source (already patched)
patches/        Win11 ARM64 compatibility patches as unified diffs
build/          PowerShell build scripts
deploy/         install/launch scripts for the device
.github/        GitHub Actions workflow that builds ARM64
docs/           technical notes
```

## The patches

| Patch | What it fixes |
|---|---|
| `001-robust-win11-detection.patch` | Replaces `GetVersionEx` with `RtlGetVersion` (works regardless of manifest), adds `IsSlateMode()`, fixes the app manifest (arch + maxversiontested). |
| `002-win11-posture-shell-activation.patch` | Forces the shell to activate on Win11 or when the device is in slate mode, and live-toggles it on `WM_SETTINGCHANGE` (ConvertibleSlateMode). |

## Building

The shell uses MSVC + C++/WinRT + XAML Islands, so it **must be built on
Windows** (a normal Windows PC, or CI). You cannot cross-compile it from Linux.

### Option A — GitHub Actions (no Windows PC needed)

1. Push this repo to GitHub.
2. Go to **Actions → build-arm64 → Run workflow**.
3. Download the `Neomobileshell-arm64` artifact.

### Option B — Windows PC with Visual Studio

1. Install **VS2022** with the *Desktop development with C++* workload and the
   **MSVC v143 - VS 2022 C++ ARM64 build tools** component.
2. Run:

```powershell
.\build\build.ps1 -Configuration Release -Platform ARM64
```

The ARM64 `MobileShellPlus.exe` lands in `out\Release-ARM64\`.

## Installing on the phone (Windows 11 ARM64)

1. Transfer the build output to the phone (PairDrop, USB, etc.).
2. On the phone, run `deploy\install.cmd` (as administrator) from the folder
   that contains `MobileShellPlus.exe`.

This copies the binary to `%ProgramData%\Neomobileshell`, registers it to start
at logon, and sets `ConvertibleSlateMode=0` / `ConvertibilityEnabled=1` so
Windows 11 treats the device as a tablet. Reboot or sign out, then the shell
appears.

`deploy\launch.cmd` starts the shell on demand.

## Notes & limitations

- Charging in Windows is a separate known WoA limitation (not addressed here).
- The shell is an overlay — it does not replace `explorer.exe`.
- If the shell does not appear, verify `ConvertibleSlateMode` is `0` and the
  process is running (`tasklist | findstr MobileShell`).

## License

MIT. The MobileShell source is (c) 2019 ADeltaX and is used under MIT.
