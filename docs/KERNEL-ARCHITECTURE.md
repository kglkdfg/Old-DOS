# Kernel architecture notes

This document defines the interfaces and memory constraints used while implementing Phase 1. It distinguishes implemented code from planned modules.

## Execution model

- CPU target: 16-bit x86 real mode.
- BIOS services remain available through software interrupts.
- Kernel entry point is physical address 0x8000.
- The stage-1 loader reserves 0000:7C00 as the initial stack region.
- The stage-1 loader currently reads exactly eight sectors (4096 bytes) after the boot sector. It uses EDD LBA when available and CHS only for floppy media.
- The kernel must remain within the fixed 4 KiB load limit until the loader becomes metadata-driven.
- Keep kernel code, stack, disk buffers, and BIOS data from overwriting one another.

## Implemented disk module

The first disk module is in `kernel/disk.asm`.

- `disk_boot_drive` stores the BIOS drive number passed in DL at kernel entry.
- `disk_init` probes INT 13h extensions (EDD) and returns status in CF.
- `disk_read_lba` accepts a 32-bit LBA in EAX, a sector count from 1 to 127 in CX, and a destination buffer in ES:BX. It returns status in CF.
- The read routine retries BIOS failures three times and rejects buffers that cross a physical 64 KiB DMA boundary.
- This is read-only support. Disk writes, MBR parsing, partition bounds, and volume discovery are not implemented.
- Runtime behavior still needs NASM build and QEMU verification.

## Planned module boundaries

### Console

The console module should own text output and screen operations:

- `console_putc(AL)`
- `console_write(DS:SI)`
- `console_newline()`
- `console_clear()`
- `console_set_cursor(DH, DL)`

Callers should not issue BIOS video interrupts directly once the module is integrated, except inside the console implementation.

### Keyboard

The keyboard module should expose key events instead of forcing callers to interpret BIOS registers:

- ASCII character (zero when the key has no printable character)
- BIOS scan code
- modifier snapshot: Shift, Ctrl, Alt
- key flags for extended keys

The initial implementation may use BIOS INT 16h. Keep physical key events separate from later English/Russian character translation so Alt+Shift can be implemented without rewriting the editor.

### Shell

The shell should own input-line editing and command dispatch. Individual commands should be separate routines and receive a parsed command/argument buffer. Device drivers and filesystem code must never print shell prompts.

## Phase 1 completion checklist

- [ ] Console output, clear, and cursor operations go through one module.
- [ ] Keyboard events preserve scan code and modifier state.
- [ ] Shell parsing is separated from command implementations.
- [ ] Memory map and buffer ownership are documented.
- [ ] Kernel loading supports an image larger than eight sectors.
- [ ] The complete build boots and the original commands still work.

Until every item is implemented and tested, Phase 1 remains in progress.
