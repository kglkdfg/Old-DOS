# BIOS disk I/O and volume discovery design

This document defines the intended scope of development Phase 2. The current
prototype does not yet provide a general-purpose disk driver or partition
mounting.

## Disk service

The first implementation will use BIOS INT 13h from real mode.

- Preserve the BIOS boot drive number passed to the boot sector in DL.
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

- `disk_get_info`: report BIOS drive number and supported access mode.
- `disk_read_sectors`: read one or more sectors from a 32-bit LBA into a
  caller-provided real-mode buffer.
- `disk_write_sectors`: write sectors only after read support and bounds
  validation have passed.
- `disk_last_error`: expose the last BIOS status for diagnostics.

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

- [ ] BIOS disk capability detection works.
- [ ] LBA sector reads work in QEMU and are verified against known patterns.
- [ ] Read/write APIs validate buffers and sector ranges.
- [ ] MBR signature and partition entries are parsed safely.
- [ ] Invalid LBAs and BIOS errors return to the caller without hanging.
- [ ] Tests use disposable disk images only.

Until every item is implemented and tested, Phase 2 remains in progress.
