# FAT12 and FAT16 driver requirements

Status: **implementation requirements**. No FAT driver is present in the
current kernel yet.

## Scope

FAT12 is intended primarily for floppy images and small removable volumes.
FAT16 is intended for additional partitions. Both drivers must plug into the
common filesystem API in `FILESYSTEM-API.md`.

## Mount validation

Read the BIOS Parameter Block (BPB) from the volume boot sector and validate:

- 512-byte sector size for the initial implementation.
- Sectors per cluster is a non-zero power of two.
- Reserved sector count is non-zero.
- Number of FAT copies is supported (normally 2).
- Root entry count, FAT size, total sector count, and geometry are consistent.
- Derived root-directory, FAT, and data-region boundaries fit inside the
  partition's declared sector count.
- Cluster count classifies the volume as FAT12 or FAT16; do not trust the
  textual filesystem label.
- Reject FAT32 and malformed/unsupported BPBs explicitly.

All multiplication/addition used to derive offsets must be overflow-checked.

## FAT entry handling

- FAT12 entries are packed 12-bit values; reading an entry must correctly handle
  entries that straddle sector boundaries.
- FAT16 entries are little-endian 16-bit values.
- Validate every cluster number before reading its data.
- Detect free, reserved, bad, and end-of-chain values according to the format.
- Detect cyclic chains by limiting traversal to the volume's cluster count.
- Validate chain length against file size without reading beyond the volume.
- Keep FAT-copy update policy explicit; writes must not leave copies silently
  inconsistent.

## Directory and filename behavior

- Support the fixed root directory layout for FAT12/FAT16.
- Support subdirectories through cluster chains.
- Initially support short 8.3 names and the standard attribute bits.
- Long File Name (LFN) entries may be added after short-name reads are stable.
- Skip deleted entries and stop at the first 0x00 entry.
- Treat volume labels and special entries separately from ordinary files.
- Never interpret untrusted directory data as a pointer without bounds checks.

## Write support order

1. Read-only mount and root listing.
2. Subdirectory traversal and file reads.
3. Create and write files.
4. Create directories and delete files.
5. Free-cluster accounting and cross-volume copy tests.

Do not enable writes until read-only parsing passes known-good FAT12/FAT16
fixtures and malformed-image tests.

## Test fixtures required

- Empty FAT12 floppy image (1.44 MiB).
- FAT12 image with empty file, multi-cluster file, deleted entry, and subfolder.
- FAT16 image with equivalent fixtures.
- Images with invalid BPB fields, truncated FAT, out-of-range cluster chains,
  cyclic chains, bad clusters, and inconsistent FAT copies.
