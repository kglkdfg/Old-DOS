# Old-DOS

An open-source DOS-inspired operating system built from scratch.

**License:** GNU General Public License v3.0 (GPL-3.0)

## Current milestone: boot, console, and built-in commands

Old-DOS currently boots in 16-bit x86 real mode through a BIOS boot sector.
The boot sector loads a small kernel from a floppy image. The kernel initializes
the text console and provides a keyboard-driven command prompt.

### Commands

| Command | Description |
| --- | --- |
| `HELP` | List available commands |
| `CLS` | Clear the screen |
| `VER` | Show the OS version |
| `ECHO text` | Print text |
| `REBOOT` | Restart the virtual machine |

Commands are case-insensitive. This is an early educational prototype, not yet
a fully DOS-compatible operating system. Filesystem and external program
support are not implemented yet.

## Requirements

- NASM
- GNU Make
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

Press `Ctrl+C` in the terminal running QEMU to stop it, or close the QEMU
window.

## Project layout

```text
boot/boot.asm       BIOS boot sector (loads the kernel)
kernel/kernel.asm   16-bit kernel, text console, and command shell
Makefile            Build floppy image and launch QEMU
```

## Roadmap

- [x] BIOS boot sector
- [x] Load a small 16-bit kernel
- [x] Text-mode console and keyboard input
- [x] Basic built-in shell commands
- [ ] Cursor and screen handling improvements
- [ ] Disk and FAT12 filesystem support
- [ ] File commands (`DIR`, `TYPE`, `COPY`, `DEL`)
- [ ] Load and execute external programs

Contributions, bug reports, and ideas are welcome.
