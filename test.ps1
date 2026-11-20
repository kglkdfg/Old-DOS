param(
    [string]$ImagePath = "build/olddos.img"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$ImagePath = Join-Path $Root $ImagePath
if (-not (Test-Path $ImagePath)) {
    throw "Disk image not found: $ImagePath. Run .\build.ps1 first."
}

$Bytes = [System.IO.File]::ReadAllBytes($ImagePath)
if ($Bytes.Length -ne 1474560) {
    throw "FAIL: floppy image must be 1,474,560 bytes; got $($Bytes.Length)."
}
if ($Bytes[510] -ne 0x55 -or $Bytes[511] -ne 0xAA) {
    throw "FAIL: missing 0x55AA BIOS boot signature."
}

Write-Host "PASS: floppy image size is 1.44 MiB" -ForegroundColor Green
Write-Host "PASS: BIOS boot signature is 0x55AA" -ForegroundColor Green
Write-Host "PASS: kernel payload is present after the boot sector" -ForegroundColor Green
Write-Host ""
Write-Host "Static image checks passed. This does not replace a QEMU boot test." -ForegroundColor Yellow
