param(
    [string]$ImagePath = "build/olddos.img"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$ImagePath = Join-Path $Root $ImagePath
$KernelPath = Join-Path $Root "build/kernel.bin"
if (-not (Test-Path $ImagePath)) {
    throw "Disk image not found: $ImagePath. Run .\build.ps1 first."
}
if (-not (Test-Path $KernelPath)) {
    throw "Kernel binary not found. Run .\build.ps1 first."
}

$Bytes = [System.IO.File]::ReadAllBytes($ImagePath)
$Kernel = [System.IO.File]::ReadAllBytes($KernelPath)
if ($Bytes.Length -ne 1474560) {
    throw "FAIL: floppy image must be 1,474,560 bytes; got $($Bytes.Length)."
}
if ($Bytes[510] -ne 0x55 -or $Bytes[511] -ne 0xAA) {
    throw "FAIL: missing 0x55AA BIOS boot signature."
}
if ($Kernel.Length -eq 0 -or $Kernel.Length -gt 4096) {
    throw "FAIL: kernel must be between 1 and 4096 bytes; got $($Kernel.Length)."
}
for ($i = 0; $i -lt $Kernel.Length; $i++) {
    if ($Bytes[512 + $i] -ne $Kernel[$i]) {
        throw "FAIL: kernel differs from disk image at byte $i."
    }
}

Write-Host "PASS: floppy image size is 1.44 MiB" -ForegroundColor Green
Write-Host "PASS: BIOS boot signature is 0x55AA" -ForegroundColor Green
Write-Host "PASS: kernel payload matches build/kernel.bin" -ForegroundColor Green
Write-Host ""
Write-Host "Static image checks passed. This does not replace a QEMU boot test." -ForegroundColor Yellow
