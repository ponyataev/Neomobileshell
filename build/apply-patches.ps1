param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

# Applies the Win11 ARM64 compatibility patches to the vendored MobileShell
# source. The patches are stored relative to the repository root
# (prefix "mobile-shell/src/..."), so run this from a checkout of this repo.
#
# The vendored source under mobile-shell/ is ALREADY patched; this script is
# only needed when you replace mobile-shell/ with a pristine upstream checkout.

$ErrorActionPreference = "Stop"

$patchDir = Join-Path $RepoRoot "patches"
$patchFiles = Get-ChildItem $patchDir -Filter "*.patch" | Sort-Object Name

if (-not $patchFiles) {
    Write-Host "No patches found in $patchDir"
    exit 0
}

foreach ($patch in $patchFiles) {
    Write-Host "Applying $($patch.Name) ..."
    git -C $RepoRoot apply --check $patch.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "SKIPPED $($patch.Name) (already applied or conflicts)"
        continue
    }
    git -C $RepoRoot apply $patch.FullName
    if ($LASTEXITCODE -ne 0) { throw "Failed to apply $($patch.Name)" }
    Write-Host "Applied $($patch.Name)"
}

Write-Host "Done."
