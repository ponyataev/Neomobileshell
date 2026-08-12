param(
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [ValidateSet("ARM64", "x64", "x86", "ARM")]
    [string]$Platform = "ARM64",
    [string]$OutDir = "",
    [switch]$FullSolution
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root "mobile-shell\src"
$outDir = if ($OutDir) { $OutDir } else { Join-Path $root "out\$Configuration-$Platform" }
if (-not $outDir.EndsWith("\")) { $outDir += "\" }

Write-Host "== Neomobileshell build =="
Write-Host "  Configuration : $Configuration"
Write-Host "  Platform      : $Platform"
Write-Host "  Output        : $outDir"

# 1) Locate MSBuild from Visual Studio / Build Tools
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    throw "Visual Studio not found (vswhere.exe missing). Install VS2022 with the 'Desktop development with C++' workload and the 'MSVC v143 - VS 2022 C++ ARM64 build tools' component."
}
$msbuild = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
if (-not $msbuild) {
    throw "MSBuild not found inside Visual Studio."
}
Write-Host "  MSBuild       : $msbuild"

# 2) Restore NuGet packages (project uses packages.config)
$nuget = Join-Path $env:TEMP "nuget.exe"
if (-not (Test-Path $nuget)) {
    Write-Host "Downloading nuget.exe ..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nuget
}
Write-Host "Restoring NuGet packages ..."
& $nuget restore (Join-Path $srcDir "MobileShellPlus.sln") | Out-Null
if ($LASTEXITCODE -ne 0) { throw "NuGet restore failed." }

# 3) Build
$proj = if ($FullSolution) {
    Join-Path $srcDir "MobileShellPlus.sln"
} else {
    Join-Path $srcDir "MobileShellPlus\MobileShellPlus.vcxproj"
}
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Write-Host "Building $proj ..."
& $msbuild $proj -m `
    -p:Configuration=$Configuration `
    -p:Platform=$Platform `
    -p:OutDir=$outDir `
    -p:AppxPackageSigningEnabled=false `
    -v:minimal
if ($LASTEXITCODE -ne 0) { throw "MSBuild failed with exit code $LASTEXITCODE." }

Write-Host ""
Write-Host "== Build finished =="
Get-ChildItem $outDir -Recurse -Include *.exe,*.dll -File | ForEach-Object {
    Write-Host "  -> $($_.FullName)"
}
