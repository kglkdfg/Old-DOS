# Shell file command specification

Status: **behavior specification**. These commands are planned and are not
implemented in the current shell.

All commands use the common filesystem API. Unless stated otherwise, command
names are case-insensitive. Paths may include a drive prefix such as `S:\\DOCS`.

## DIR [path]

- Lists files and directories in the selected directory.
- With no path, lists the current directory.
- Displays entry type and file size where available.
- Reports missing paths and non-directory targets distinctly.

## MKDIR path

- Creates exactly one new directory at the requested path.
- Parent directory must already exist in v1.
- Fails if the target already exists.
- Does not silently create missing parent directories.

## CRTF file

- Creates an empty file only.
- Uses exclusive-create semantics.
- If the target exists, prints exactly: `File already exists`.
- Existing file contents and metadata must remain unchanged.
- Does not open or truncate an existing file.

## CAT file

- Writes text-file contents to the console.
- Reads in bounded chunks; never assumes the entire file fits in memory.
- Stops and reports I/O errors rather than printing uninitialized buffer data.
- Binary-file detection is not guaranteed in v1; document that CAT is intended
  for text files.

## COPY source destination

- Copies a file; directories are rejected in v1.
- Destination must not already exist. No implicit overwrite.
- Source and destination may be on different mounted volumes.
- Uses a bounded transfer buffer and checks every read and write.
- On failure, reports the error and removes a partial destination if that can
  be done safely. Source data is never modified.
- A future explicit overwrite option must be separately designed and tested.

## DEL file

- Deletes a file only; directories are rejected in v1.
- Rejects protected system files.
- Reports read-only media, missing files, and I/O errors.
- Must not report success until metadata changes have completed.

## Current-directory and drive behavior

- Initial current drive after mount: `S:` when a valid ODFS system volume exists.
- If no ODFS volume is mounted, retain the boot drive prompt until a volume
  manager provides a valid current volume; do not pretend S: is mounted.
- Prompt format: `S:\\PATH>` once current-directory support is implemented.
- `CD` is not part of this batch; until it exists, commands accept explicit
  paths and default to the volume root/current directory defined by the shell.

## Error messages

The shell translates filesystem status codes into stable human-readable
messages. In particular:
- Existing target: `File already exists`
- Missing source/path: `File not found` or `Path not found`
- Full volume: `Disk is full`
- Read-only volume: `Drive is read-only`
- Corrupt filesystem: `File system is corrupted`
- Device failure: `Disk I/O error`

Do not claim an operation succeeded when the driver returned an error.
