# Old-DOS

An open-source DOS-inspired operating system built from scratch.

**License:** GNU General Public License v3.0 (GPL-3.0)

## Current status

The first milestone is a 16-bit x86 BIOS boot sector. It prints a startup
message and halts. This is not yet a DOS-compatible operating system; kernel,
shell, filesystem, and DOS command compatibility are planned.

## Requirements

- NASM
- GNU Make
- QEMU with `qemu-system-i386`

## Build

```sh
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

## Clean

```sh
make clean
```

## Project goals

- BIOS boot and a small 16-bit real-mode kernel
- Keyboard and text-mode console
- Command-line shell
- FAT-compatible storage
- DOS-style utilities and program loading

Contributions, bug reports, and ideas are welcome.
