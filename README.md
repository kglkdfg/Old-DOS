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
| `EDIT file` | Built-in text editor |
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

See [docs/COMMANDS.md](docs/COMMANDS.md) for the command behavior, filesystem
architecture, and implementation order.

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

On Windows PowerShell, if GNU Make is not installed, the boot sector and kernel
can be assembled with NASM and combined into a floppy image manually. See the
project discussion/instructions for the PowerShell commands.

## Project layout

```text
boot/boot.asm       BIOS boot sector (loads the kernel)
kernel/kernel.asm   16-bit kernel, text console, and command shell
docs/COMMANDS.md   Planned command and filesystem specification
Makefile            Build floppy image and launch QEMU
```

## Roadmap

- [x] BIOS boot sector
- [x] Load a small 16-bit kernel
- [x] Text-mode console and keyboard input
- [x] Basic built-in shell commands
- [ ] Disk I/O and partition/volume discovery
- [ ] Native ODFS filesystem for system drive S:
- [ ] FAT12 and FAT16 filesystem drivers
- [ ] File and directory commands
- [ ] Built-in text editor with safe save/exit
- [ ] English/Russian keyboard layout switching
- [ ] Load and execute external programs

Contributions, bug reports, and ideas are welcome.
