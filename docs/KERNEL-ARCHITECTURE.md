# Kernel architecture notes

This document defines the interfaces to use while implementing development
Phase 1. It is a design contract, not a claim that all interfaces are already
implemented in the current kernel.

## Execution model

- CPU target: 16-bit x86 real mode.
- BIOS services remain available through software interrupts.
- Kernel entry point is currently physical address 0x8000.
- Current bootloader reserves 0x0000:0x7C00 as the initial stack region.
- Current stage-1 loader reads exactly eight sectors (4096 bytes) after the boot
  sector. The kernel must remain within this limit until the loader is extended.
- Do not let kernel code, stack, disk buffers, or BIOS data overwrite one another.

## Planned module boundaries

### Console

The console module should own text output and screen operations:

- `console_putc(AL)`
- `console_write(DS:SI)`
- `console_newline()`
- `console_clear()`
- `console_set_cursor(DH, DL)`

Callers should not issue BIOS video interrupts directly once the module is
integrated, except inside the console implementation.

### Keyboard

The keyboard module should expose key events instead of forcing callers to
interpret BIOS registers:

- ASCII character (zero when the key has no printable character)
- BIOS scan code
- modifier snapshot: Shift, Ctrl, Alt
- key flags for extended keys

The initial implementation may use BIOS INT 16h. Keep physical key events
separate from later English/Russian character translation so Alt+Shift can be
implemented without rewriting the editor.

### Shell

The shell should own input-line editing and command dispatch. Individual
commands should be separate routines and receive a parsed command/argument
buffer. Device drivers and filesystem code must never print shell prompts.

## Phase 1 completion checklist

- [ ] Console output, clear, and cursor operations go through one module.
- [ ] Keyboard events preserve scan code and modifier state.
- [ ] Shell parsing is separated from command implementations.
- [ ] Memory map and buffer ownership are documented.
- [ ] Kernel loading supports an image larger than eight sectors.
- [ ] The complete build boots and the original commands still work.

Until every item is implemented and tested, Phase 1 remains in progress.
