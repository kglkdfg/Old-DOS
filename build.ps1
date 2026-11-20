param(
    [switch]$Clean,
    [switch]$Run
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$Nasm = Get-Command nasm -ErrorAction SilentlyContinue
if (-not $Nasm) {
    throw "NASM was not found in PATH. Install NASM or add its folder to PATH."
}

$Qemu = Get-Command qemu-system-i386 -ErrorAction SilentlyContinue
if ($Run -and -not $Qemu) {
    throw "QEMU was not found in PATH. Install QEMU or add its folder to PATH."
}

$BuildDir = Join-Path $Root "build"
$BootBin = Join-Path $BuildDir "boot.bin"
$KernelBin = Join-Path $BuildDir "kernel.bin"
$Image = Join-Path $BuildDir "olddos.img"

if ($Clean -and (Test-Path $BuildDir)) {
    Remove-Item $BuildDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Write-Host "[1/4] Assembling BIOS boot sector..." -ForegroundColor Cyan
& $Nasm.Source -f bin "boot/boot.asm" -o $BootBin
if ($LASTEXITCODE -ne 0) { throw "NASM failed while assembling boot/boot.asm" }

Write-Host "[2/4] Assembling 16-bit kernel..." -ForegroundColor Cyan
& $Nasm.Source -f bin "kernel/kernel.asm" -o $KernelBin
if ($LASTEXITCODE -ne 0) { throw "NASM failed while assembling kernel/kernel.asm" }

$BootBytes = [System.IO.File]::ReadAllBytes($BootBin)
$KernelBytes = [System.IO.File]::ReadAllBytes($KernelBin)

if ($BootBytes.Length -ne 512) {
    throw "Invalid boot sector size: $($BootBytes.Length) bytes; expected exactly 512."
}
if ($BootBytes[510] -ne 0x55 -or $BootBytes[511] -ne 0xAA) {
    throw "Invalid BIOS boot signature. Expected bytes 55 AA at offsets 510-511."
}
if ($KernelBytes.Length -eq 0 -or $KernelBytes.Length -gt 4096) {
    throw "Invalid kernel size: $($KernelBytes.Length) bytes; expected 1..4096."
}

Write-Host "[3/4] Creating 1.44 MiB floppy image..." -ForegroundColor Cyan
$ImageBytes = New-Object byte[] 1474560
[Array]::Copy($BootBytes, 0, $ImageBytes, 0, $BootBytes.Length)
[Array]::Copy($KernelBytes, 0, $ImageBytes, 512, $KernelBytes.Length)
[System.IO.File]::WriteAllBytes($Image, $ImageBytes)

Write-Host "[4/4] Verifying generated image..." -ForegroundColor Cyan
$VerifiedImage = [System.IO.File]::ReadAllBytes($Image)
if ($VerifiedImage.Length -ne 1474560) {
    throw "Invalid floppy image size: $($VerifiedImage.Length) bytes."
}
if ($VerifiedImage[510] -ne 0x55 -or $VerifiedImage[511] -ne 0xAA) {
    throw "Boot signature was not preserved in the disk image."
}
for ($i = 0; $i -lt $KernelBytes.Length; $i++) {
    if ($VerifiedImage[512 + $i] -ne $KernelBytes[$i]) {
        throw "Kernel verification failed at image offset $($512 + $i)."
    }
}

Write-Host ""
Write-Host "Build successful!" -ForegroundColor Green
Write-Host "Boot sector : $($BootBytes.Length) bytes"
Write-Host "Kernel      : $($KernelBytes.Length) bytes"
Write-Host "Disk image  : $Image ($($VerifiedImage.Length) bytes)"

if ($Run) {
    Write-Host "Starting Old-DOS in QEMU..." -ForegroundColor Cyan
    & $Qemu.Source -drive "format=raw,file=$Image,if=floppy"
    if ($LASTEXITCODE -ne 0) {
        throw "QEMU exited with code $LASTEXITCODE."
    }
}
