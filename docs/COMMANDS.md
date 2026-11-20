# Old-DOS command and filesystem specification

This document records the planned user-facing behavior for the Old-DOS shell.
It is a design specification; features marked planned are not implemented yet.

## Drives and filesystems

- `S:` is the system drive and uses the native Old-DOS File System (ODFS).
- ODFS is the native filesystem for the main system partition.
- FAT12 and FAT16 are supported as additional filesystem formats.
- The filesystem layer should expose one common interface to shell commands, regardless of the underlying filesystem.
- ODFS should use 32-bit sector addressing and support nested directories and long filenames.

The drive letters are a logical Old-DOS convention. Actual disk and partition discovery/mounting must assign letters based on detected volumes; the system volume is assigned `S:`.

## Commands

| Command | Purpose | Planned behavior |
| --- | --- | --- |
| `HELP` | Help | List built-in commands |
| `CLS` | Clear screen | Clear the text console |
| `VER` | Version | Display Old-DOS version |
| `ECHO text` | Print text | Print the supplied text |
| `REBOOT` | Restart | Reboot through BIOS |
| `DIR [path]` | Directory listing | List files and subdirectories |
| `COPY source destination` | Copy | Copy a file without silently overwriting a destination |
| `DEL file` | Delete | Delete a file, with safeguards for protected system files |
| `CAT file` | Display file | Print a text file to the console |
| `EDIT file` | Text editor | Open or create a text file in the built-in editor |
| `MKDIR path` | Create directory | Create a directory, including a single requested path component |
| `CRTF file` | Create file | Create an empty file without opening the editor |

### CRTF — CReaTe File

Example:

```dos
S:\> CRTF NOTES.TXT
File created: NOTES.TXT
```

Safety rules:

1. If the target does not exist, create an empty file.
2. If the target already exists, do not modify or truncate it.
3. In that case, print `File already exists` and return to the prompt.
4. Invalid paths, read-only media, and insufficient space must produce clear errors.

### EDIT keyboard controls

The built-in editor is planned to support:

- `Ctrl+O`: begin save; show a filename prompt or confirm the current filename.
- `Enter`: confirm the save.
- `Ctrl+X`: exit. If there are unsaved changes, ask whether to save, discard, or cancel.
- `Alt+Shift`: switch the keyboard layout between English and Russian.

The editor must not discard unsaved changes without confirmation.

## Implementation order

1. Disk I/O and partition/volume discovery.
2. Filesystem abstraction and ODFS on the system volume.
3. FAT12 driver, then FAT16 driver.
4. Path parsing and common directory/file operations.
5. Shell commands: `DIR`, `MKDIR`, `CRTF`, `CAT`, `COPY`, and `DEL`.
6. Text editor with safe save/exit behavior.
7. Keyboard layout switching and localized console messages.

Until each item is implemented and tested, it must be described as planned rather than available.
