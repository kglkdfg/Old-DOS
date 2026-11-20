# Old-DOS

An open-source DOS-inspired operating system built from scratch.

**License:** GNU General Public License v3.0 (GPL-3.0)

## Current milestone: 0.1 prototype

Old-DOS boots in 16-bit x86 real mode through a BIOS boot sector. The boot sector
loads a small kernel from a floppy image. The kernel initializes the text console
and provides a keyboard-driven command prompt.

### Implemented commands

| Command | Description |
| --- | --- |
| `HELP` | List available commands |
| `CLS` | Clear the screen |
| `VER` | Show the OS version |
| `ECHO text` | Print text |
| `REBOOT` | Restart the virtual machine |

Commands are case-insensitive. This is an early educational prototype, not yet
a fully DOS-compatible operating system. Filesystem access, a text editor,
keyboard layout switching, and the additional commands below are planned, not
implemented in the current kernel.

## Planned commands and features

| Command / feature | Description |
| --- | --- |
| `DIR [path]` | List files and directories |
| `COPY source destination` | Copy a file |
| `DEL file` | Delete a file |
| `CAT file` | Display a text file |
| `EDIT [file]` | Built-in text editor |
| `MKDIR path` | Create a directory |
| `CRTF file` | Create an empty file (CReaTe File) |
| `Alt+Shift` | Switch English/Russian keyboard layout |
| ODFS | Native filesystem for the system volume `S:` |
| FAT12 / FAT16 | Support for removable and additional volumes |

**CRTF safety rule:** creating a file must never silently overwrite an existing
file. If the target already exists, Old-DOS will display
`File already exists` and leave its contents unchanged.

The planned editor controls are `Ctrl+O` to save (then `Enter` to confirm)
and `Ctrl+X` to exit. If there are unsaved changes, the editor must ask before
discarding them.

## Development plan

Development is divided into ten phases:

1. **Phase 0 — Stabilize prototype:** repeatable builds and baseline checks.
2. **Phase 1 — Kernel foundations:** console, keyboard events, memory layout,
   and a larger-kernel loading path.
3. **Phase 2 — Disk I/O:** BIOS sector access, MBR partition discovery, volumes.
4. **Phase 3 — ODFS:** native filesystem design and system volume `S:`.
5. **Phase 4 — FAT12/FAT16:** drivers for additional volumes.
6. **Phase 5 — Shell file commands:** paths, `DIR`, `MKDIR`, `CRTF`, `CAT`,
   `COPY`, and `DEL`.
7. **Phase 6 — Text editor:** `EDIT`, safe saving, and exit behavior.
8. **Phase 7 — Keyboard layouts:** English/Russian switching with `Alt+Shift`.
9. **Phase 8 — Integration:** connect the kernel, drivers, filesystems, shell,
   editor, and keyboard modules.
10. **Phase 9 — Testing:** comprehensive functional, filesystem, failure,
    regression, and QEMU/hardware verification before release.

See [docs/COMMANDS.md](docs/COMMANDS.md) for the detailed tasks and exit criteria
for every phase. Filesystem work in phases 3–5 currently consists of design
documents only; the kernel does not yet contain ODFS/FAT drivers or file commands.

Design documents:
- [ODFS v1 format proposal](docs/ODFS-SPEC.md)
- [Common filesystem API](docs/FILESYSTEM-API.md)
- [FAT12/FAT16 driver requirements](docs/FAT12-FAT16.md)
- [Shell file command specification](docs/FILE-COMMANDS.md)
- [BIOS disk I/O prerequisites](docs/DISK-IO.md)

## Filesystem architecture

- `S:` is reserved as the logical system drive and will use the native ODFS
  filesystem.
- FAT12 and FAT16 will be supported for other detected volumes.
- Shell commands will use a shared filesystem interface so they can work
  across supported filesystem formats.
- ODFS is planned to use 32-bit sector addressing.

These are design goals; disk and partition discovery, filesystem drivers, and
file commands are not implemented in the current prototype.

## Requirements

- NASM
- GNU Make (optional if using the manual PowerShell build instructions)
- QEMU with `qemu-system-i386`

On Debian/Ubuntu:

```sh
sudo apt update
sudo apt install nasm make qemu-system-x86
```

## Build

```sh
make clean
make
```

This creates `build/olddos.img`, a 1.44 MiB floppy disk image.

## Run in QEMU

```sh
make run
```

Or launch it directly:

```sh
qemu-system-i386 -drive format=raw,file=build/olddos.img,if=floppy
```

On Windows PowerShell, GNU Make is not required. From the repository folder:

```powershell
.\build.ps1 -Clean
.\test.ps1
.\build.ps1 -Run
```

The build script checks the 512-byte boot sector, the 0x55AA BIOS signature,
the current 4 KiB kernel limit, and the resulting 1.44 MiB image. The test
script verifies the image layout and kernel payload. These are static checks;
a successful QEMU boot still needs to be tested manually.

## Project layout

```text
boot/boot.asm       BIOS boot sector (loads the kernel)
kernel/kernel.asm   16-bit kernel, text console, and command shell
docs/COMMANDS.md   Phased development plan and filesystem specification
docs/KERNEL-ARCHITECTURE.md  Kernel module interface plan
docs/DISK-IO.md     BIOS disk I/O and partition discovery design
build.ps1           Native Windows PowerShell build and QEMU runner
test.ps1            Static floppy image validation
Makefile            Build floppy image and launch QEMU
```

Contributions, bug reports, and ideas are welcome.
