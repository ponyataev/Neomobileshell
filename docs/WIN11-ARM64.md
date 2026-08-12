# Making MobileShell work on Windows 11 ARM64

## Why upstream MobileShell breaks on Windows 11

### 1. Tablet mode no longer exists

Upstream (ADeltaX/MobileShell) decides when to show the shell by subscribing to
the WNF state `WNF_TMCN_ISTABLETMODE`:

```cpp
Wnf::SubscribeWnf(WNF_TMCN_ISTABLETMODE, WnfCallback, NULL);
if (Wnf::IsTabletMode())
    OnTabletModeChanged(true);
```

Windows 10 exposed this state through the ImmersiveShell "tablet mode".
Windows 11 removed the tablet-mode UI concept, so this WNF state never reports
"tablet" and the shell never appears.

### 2. Old toolchain

- CppWinRT `2.0.190730.2` / `2.0.191018.6`
- Windows SDK `10.0.18362.0`
- Platform toolset `v140` (VS2015)

The WOA-Project fork bumped these to CppWinRT `2.0.210825.3`, SDK
`10.0.19041.0` and toolset `v143` (VS2022), which is what makes it buildable
on a modern ARM64 toolchain.

### 3. Manifest arch mismatch

`Application.manifest` hardcoded `processorArchitecture="amd64"` — wrong for an
ARM64 binary and could make Windows reject/mishandle the manifest.

## What Neomobileshell changes

### Patch 001 — robust Windows 11 / slate detection

- `Utils::IsWindows11()` and `Utils::IsMobileCellularSupported()` now use
  `RtlGetVersion` (ntdll) instead of `GetVersionExW`. `GetVersionEx` behavior
  depends on the application manifest and can return the legacy `6.2.9200`
  version; `RtlGetVersion` always reports the real build number.
- Added `Utils::IsSlateMode()` using `GetSystemMetrics(SM_CONVERTIBLESLATEMODE)`
  — on a phone this is always `0` (slate).
- Manifest: removed `processorArchitecture`, bumped `maxversiontested` to
  `10.0.26100.0`, kept the Windows 10 `supportedOS` GUID.

### Patch 002 — activation on Win11 + live posture switching

All activation sites now evaluate:

```cpp
Wnf::IsTabletMode() || Utils::IsWindows11() || Utils::IsSlateMode()
```

so the shell activates on any Windows 11 ARM64 phone even though the WNF
tablet-mode state is dead. The message loop also watches
`WM_SETTINGCHANGE("ConvertibleSlateMode")` and toggles the shell when the
posture changes.

## Windows 11 tablet posture registry

To make Windows 11 behave like a slate (which is what a WoA phone is), the
install script sets:

```
HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl
    ConvertibleSlateMode  = 0   (0 = slate)
    ConvertibilityEnabled = 1
```

These are the values Windows 11's shell uses to decide on tablet experiences
(see Microsoft's "Recommended settings for better tablet experiences").

## Build/run requirements

- Windows host with VS2022 (or the GitHub Actions workflow).
- MSVC `v143` ARM64 build tools.
- Windows SDK `10.0.19041.0` or newer.
- Target device: Windows 11 ARM64 (build >= 21990).
