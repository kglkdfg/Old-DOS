# Filesystem API contract

Status: **interface proposal**. The current kernel does not yet implement these
functions. ODFS, FAT12, and FAT16 drivers must implement the same contract so
shell commands do not depend on a specific on-disk format.

## Core types

- `fs_result`: success or a stable error code.
- `fs_handle`: opaque open-file handle owned by the mounted driver.
- `fs_stat`: type, size, attributes, and timestamps.
- `fs_dirent`: name, type, and metadata for one directory entry.
- `fs_volume`: filesystem driver, BIOS drive, partition start LBA, sector count,
  read-only state, and mount state.

## Required operations

| Operation | Contract |
| --- | --- |
| `fs_mount(volume)` | Validate metadata and mount without writing |
| `fs_unmount(volume)` | Release driver state; fail if unsafe open handles remain |
| `fs_lookup(path)` | Resolve a path from the volume root/current directory |
| `fs_stat(path)` | Return metadata or a precise not-found/error result |
| `fs_list(path)` | Enumerate directory entries |
| `fs_create_file(path)` | Create a new empty file; fail if it exists |
| `fs_mkdir(path)` | Create a directory; fail if the name exists |
| `fs_open(path, mode)` | Open for read or write under explicit permissions |
| `fs_read(handle, buffer, bytes)` | Return actual byte count and status |
| `fs_write(handle, buffer, bytes)` | Return actual byte count and status |
| `fs_close(handle)` | Flush required metadata and release handle |
| `fs_delete(path)` | Delete a file; reject directories in v1 |
| `fs_get_free_space(volume)` | Return free and total bytes |

All path and sector calculations require overflow checks. Drivers receive a
partition-relative LBA and must translate it to an absolute BIOS LBA only after
checking that the request lies inside the partition. The volume manager owns
drive letters; drivers must not hard-code `S:` or any other letter.

## Error codes

The shell should map stable errors to readable messages:

- `FS_OK`
- `FS_NOT_FOUND`
- `FS_ALREADY_EXISTS`
- `FS_NOT_DIRECTORY`
- `FS_IS_DIRECTORY`
- `FS_READ_ONLY`
- `FS_NO_SPACE`
- `FS_INVALID_NAME`
- `FS_INVALID_PATH`
- `FS_IO_ERROR`
- `FS_CORRUPT`
- `FS_UNSUPPORTED`
- `FS_TOO_MANY_OPEN_FILES`
- `FS_ACCESS_DENIED`

Never collapse I/O failure or corruption into `NOT_FOUND`.

## Path rules

- Drive-qualified paths: `S:\\DIR\\FILE.TXT`.
- A path without a drive uses the current drive.
- Absolute paths begin at the selected volume root.
- Relative paths begin at the current directory.
- Accept slash and backslash as separators, but emit backslashes in prompts.
- Resolve `.` and `..` without allowing traversal above the volume root.
- Reject empty components where they are ambiguous and reject overlong paths.
- FAT drivers enforce FAT's filename constraints; ODFS supports its documented
  UTF-8 name limit.

## Safety invariants

- `CRTF` calls create-exclusive semantics. Existing files are never truncated.
- `COPY` must fail with `FS_ALREADY_EXISTS` if the destination exists.
- `DEL` never deletes a directory in the initial implementation.
- A failed write must return an error; shell must not report success.
- Read-only media must reject all mutations.
- Cross-volume copy uses a bounded memory buffer and checks every read/write.
  On failure, it removes a partially created destination when safe; it must
  never delete or alter the source.
- System-critical files require a protected attribute or explicit policy.
