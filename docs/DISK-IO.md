# BIOS disk I/O and volume discovery design

This document defines the scope of development Phase 2. A first read-only
EDD implementation is now present, but partition discovery, volume bounds, and
write support are not implemented.

## Disk service

The first implementation will use BIOS INT 13h from real mode.

- Preserve the BIOS boot drive number passed to the boot sector in DL. The stage-1 loader now does this and passes it to the kernel.
- The stage-1 loader probes EDD and reads the fixed eight-sector kernel payload from LBA 1. It retries failed reads and uses CHS only for floppy boot media.
- `kernel/disk.asm` provides `disk_init` and `disk_read_lba` for read-only EDD access. `disk_read_lba` accepts a 32-bit LBA in EAX, a sector count in CX (1–127), and a destination in ES:BX; it returns status in CF.
- The kernel still has a fixed 4 KiB load limit; the loader is not yet metadata-driven.
- Prefer INT 13h extensions (AH=41h capability check and AH=42h read / AH=43h
  write) when the BIOS reports support.
- Use a Disk Address Packet for extended LBA transfers.
- Keep a CHS fallback only for devices where geometry is known and conversion
  is range-checked.
- Return explicit success/failure status; never continue after a failed read.
- Validate transfer count, buffer range, and volume boundaries before issuing
  BIOS calls.
- Retry only a small documented number of times, then return an error.

## Initial API contract

The planned low-level interface is:

- `disk_init`: probe EDD support for the boot drive.
- `disk_read_lba`: read 1–127 sectors from a 32-bit LBA into ES:BX using an EDD Disk Address Packet.
- `disk_write_lba`: planned; not implemented.
- `disk_last_error`: planned; BIOS status reporting is not yet exposed.

The API must document segment:offset buffer rules and must not assume that
arbitrary buffers can cross a 64 KiB DMA boundary.

## Partition discovery

- Read sector 0 and validate the MBR signature 0x55AA before parsing entries.
- Parse all four 16-byte primary partition entries.
- Treat partition start LBA and sector count as unsigned values.
- Reject empty, overflowing, out-of-device, or overlapping ranges.
- Do not write to partition tables during discovery.
- Recognize filesystem types in later filesystem-driver phases; Phase 2 only
  reports partition metadata.
- Drive letters are assigned by the volume manager in a later integration
  step. The system volume will ultimately be exposed as S:.

## Safety and test images

- Use disposable QEMU raw images for all write tests.
- Keep partition discovery read-only.
- Test zero-length, out-of-range, unsupported, and malformed inputs.
- Verify sector reads against known byte patterns generated outside the OS.
- Never test write paths against a user's host disk.

## Phase 2 completion checklist

- [x] EDD capability detection routine and read-only LBA API are present in the kernel source (runtime verification pending).
- [ ] LBA sector reads work in QEMU and are verified against known patterns.
- [ ] Read API is verified for zero/oversized counts, physical 64 KiB DMA boundaries, and BIOS errors; write API is not implemented.
- [ ] MBR signature and partition entries are parsed safely.
- [ ] Invalid LBAs and BIOS errors return to the caller without hanging.
- [ ] Tests use disposable disk images only.

Until every item is implemented and tested, Phase 2 remains in progress.
