# ODFS v1 — Native Old-DOS filesystem specification

Status: **draft specification**. This document defines a proposed on-disk
format. It is not evidence that an ODFS driver or formatter exists yet.
The format must be reviewed and validated with test images before it is frozen.

## 1. Goals and limits

- ODFS is the native filesystem for the logical system volume `S:`.
- Little-endian fields and 512-byte logical sectors.
- 32-bit sector addressing within a volume.
- Nested directories and UTF-8 long names.
- Separate metadata and data allocation.
- A common filesystem API shared with FAT12/FAT16.
- No silent overwrite by the `CRTF` command.

Initial v1 limits:
- Maximum volume size: 2 TiB at 512 bytes per sector (32-bit LBA range).
- Maximum filename: 48 UTF-8 bytes per directory entry.
- Maximum directory depth is implementation-defined; path parser must detect
  and reject excessive depth rather than overflow its buffers.
- File size is an unsigned 32-bit byte count in v1.
- 512-byte sectors; cluster size is a power of two sectors, initially 1.
- No journaling in v1. A power loss during metadata updates may require repair.
  Do not claim crash consistency.

## 2. Volume layout

All sector numbers below are relative to the beginning of the ODFS volume.

| Region | Location | Description |
| --- | --- | --- |
| Primary superblock | Sector 0 | Volume identity and geometry |
| Reserved | Sectors 1..R-1 | Reserved for future metadata |
| Cluster allocation table (CAT) | Sector R | 32-bit next-cluster entries |
| Inode table | After CAT | Fixed-size inode records |
| Data area | After inode table | Directory and file clusters |
| Backup superblock | Last sector | Copy of primary superblock |

The formatter calculates region sizes using checked 64-bit host arithmetic.
The driver validates every region against the partition's sector count before
reading or writing it. Metadata regions must never overlap.

The allocation table has one 32-bit entry per data cluster:
- 0: free cluster
- 1..N: next cluster index (1-based)
- 0xFFFFFFFF: end of chain
- 0xFFFFFFFE: bad cluster
- 0xFFFFFFFD: reserved cluster

Cluster indices are relative to the data area. A chain must be range-checked,
must not loop, and must not exceed the number of data clusters.

## 3. Superblock (one 512-byte sector)

All integer fields are little-endian. Unused bytes are zero.

| Offset | Size | Field |
| --- | --- | --- |
| 0 | 8 | Magic: ASCII `OLDDOSFS` |
| 8 | 2 | Major version (1) |
| 10 | 2 | Minor version (0) |
| 12 | 2 | Sector size (512) |
| 14 | 2 | Cluster size in sectors |
| 16 | 4 | Total volume sectors |
| 20 | 4 | Reserved sector count |
| 24 | 4 | CAT start sector |
| 28 | 4 | CAT sector count |
| 32 | 4 | Inode table start sector |
| 36 | 4 | Inode table sector count |
| 40 | 4 | Data start sector |
| 44 | 4 | Data cluster count |
| 48 | 4 | Root inode number (1) |
| 52 | 4 | Inode record size (128) |
| 56 | 4 | Feature flags |
| 60 | 4 | CRC32 of bytes 0..59 |
| 64 | 4 | Backup superblock sector (last sector) |
| 68 | 444 | Reserved, must be zero in v1 |

A mount must reject an unknown major version, invalid sector/cluster sizes,
bad magic, invalid CRC, impossible region geometry, or a backup location that
does not match the volume size. Minor versions may only add optional features
that older readers can safely ignore.

## 4. Inode records (128 bytes)

Inode numbers are 1-based. Inode 0 is invalid. The inode table has a fixed
capacity determined by its sector count.

| Offset | Size | Field |
| --- | --- | --- |
| 0 | 2 | Type: 1=file, 2=directory |
| 2 | 2 | Flags |
| 4 | 4 | File size in bytes |
| 8 | 4 | First data cluster (0 for empty file) |
| 12 | 4 | Parent inode (root parent is root) |
| 16 | 4 | Creation timestamp (UTC seconds; 0 if unknown) |
| 20 | 4 | Modification timestamp (UTC seconds; 0 if unknown) |
| 24 | 4 | Link/reference count (v1 expects 1) |
| 28 | 4 | Reserved |
| 32 | 96 | Reserved for v1; must be zero |

A directory's data is a sequence of 64-byte directory entries. Directory size
must be a multiple of 64. Directory traversal validates each referenced inode
and rejects invalid types, out-of-range inode numbers, and corrupt chains.

## 5. Directory entries (64 bytes)

| Offset | Size | Field |
| --- | --- | --- |
| 0 | 4 | Inode number |
| 4 | 1 | Type: 1=file, 2=directory |
| 5 | 1 | Name length in bytes (1..48) |
| 6 | 2 | Flags |
| 8 | 48 | UTF-8 name, zero-padded |
| 56 | 4 | Reserved |
| 60 | 4 | Reserved |

Names may not contain NUL, slash, or backslash. The names `.` and `..` are
reserved for path traversal and are not stored as ordinary entries. Name
comparison is byte-exact in v1; Unicode normalization and case folding are
not specified. Duplicate names within one directory are forbidden.

## 6. Allocation and consistency rules

- CAT entry count must cover exactly the data cluster count.
- Every allocated inode and data cluster must be within its declared region.
- A cluster may belong to only one live chain.
- Chains must terminate with the end-of-chain marker.
- Free-space reporting counts free CAT entries; it must not trust cached values.
- Deletion frees a chain only after the directory entry is removed and the
  inode is no longer referenced. The implementation must document its update
  order and its power-loss limitations.
- On mount, validate geometry before following any metadata pointer.
- Never write outside the mounted volume boundaries.

## 7. Formatting and mounting

The future formatter must:
1. Require an explicit target image/device and volume size.
2. Refuse to format a non-empty target unless a deliberate force option is used.
3. Calculate metadata sizes with overflow-safe arithmetic.
4. Mark metadata-reserved allocation entries as unavailable.
5. Create inode 1 as the root directory.
6. Write primary and backup superblocks and verify them by reading back.

The future driver must mount read-only first. Writable mount is enabled only
after corruption and bounds tests pass. The first production image should be
created on a disposable QEMU disk image, never on a host system disk.

## 8. Open design questions before v1 freeze

- Whether to add a metadata checksum to each inode and directory block.
- Whether to add a small write-ahead journal in v2.
- Whether to add rename and symbolic links.
- Timestamp source and timezone policy.
- Whether the v1 48-byte UTF-8 name limit is sufficient.

These decisions must be resolved before publishing ODFS v1 as stable.
