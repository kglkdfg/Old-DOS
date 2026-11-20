# Old-DOS phased development plan

This is the implementation roadmap for Old-DOS. The current 0.1 prototype only
has a BIOS boot sector, a small 16-bit kernel, text console, keyboard line input,
and the built-in commands `HELP`, `CLS`, `VER`, `ECHO`, `REBOOT`, `DISKTEST`, and `PARTITIONS`.
Everything below is planned until implemented and tested.

## Product goals

- Keep the current 16-bit x86 BIOS/real-mode target for the first releases.
- Use `S:` for the system volume, formatted with the native ODFS filesystem.
- Support FAT12 and FAT16 volumes as additional drives.
- Expose one common filesystem API to the shell and editor.
- Never silently overwrite files or discard unsaved editor content.

## Phase 0 — Stabilize the prototype

**Goal:** make the existing bootable baseline repeatable before adding storage.

Tasks:
- Keep NASM build steps deterministic on Windows and Linux.
- Add build checks for the 512-byte boot sector, boot signature, and kernel size.
- Add a documented PowerShell build/run script so GNU Make is optional on Windows.
- Test boot, prompt, backspace, empty input, all existing commands, and reboot in QEMU.
- Record known memory layout and bootloader/kernel loading limits.

Exit criteria:
- A clean checkout builds using the documented commands.
- The generated floppy image boots in QEMU on a clean run.
- Existing shell commands pass a short manual test checklist.

## Phase 1 — Kernel foundations

**Goal:** prepare the kernel for drivers and larger features.

Tasks:
- Introduce a consistent console API (print, clear, cursor, scrolling).
- Introduce keyboard input as key events, preserving modifier keys and scan codes.
- Separate shell parsing from command implementations.
- Define a memory map and reserve safe regions for kernel, stack, buffers, and disk I/O.
- Expand the boot path beyond the current fixed 4 KiB kernel load limit (for example, a second-stage loader).

Exit criteria:
- Shell and console use shared APIs rather than duplicated BIOS calls.
- Key events expose Ctrl, Alt, Shift, Enter, Backspace, and ordinary keys.
- Kernel loading is no longer limited to the current eight sectors.

## Phase 2 — BIOS disk I/O and volume discovery

**Goal:** read and write sectors safely.

Tasks:
- Add BIOS INT 13h disk services, preferring extended LBA access when supported.
- Provide sector read/write APIs with bounds checks and error reporting.
- Detect BIOS drives and read MBR partition tables.
- Identify supported partition types and volume boundaries.
- Define a stable drive-letter assignment policy: system volume is `S:`; other volumes receive available letters.
- Add a read-only disk inspection/debug command before enabling writes.

Exit criteria:
- QEMU disk images can be read by LBA and sector contents can be verified.
- Invalid LBAs and BIOS errors are reported without hanging.
- Partition boundaries are checked before any filesystem driver accesses a volume.

## Phase 3 — Filesystem interface and ODFS format

**Goal:** design and implement the native filesystem for `S:`.

Tasks:
- Define a filesystem interface: mount, unmount, lookup, list, create file,
  create directory, read, write, delete, and get free space.
- Publish an ODFS on-disk format specification with a magic value, version,
  sector size, volume size, metadata locations, and feature flags.
- Use 32-bit LBA/sector addressing.
- Define directory records, long filename encoding, file metadata, and allocation.
- Add allocation tracking and consistency checks.
- Design safe metadata update behavior; document recovery limitations before
  claiming crash consistency.
- Implement format/mount/read-only validation first, then writable operations.
- Reserve `S:` for the mounted ODFS system volume.

Exit criteria:
- ODFS volumes can be identified and validated.
- Files and nested directories survive unmount/remount (or emulator restart).
- Corrupt or unsupported ODFS metadata is rejected safely.

## Phase 4 — FAT12 and FAT16 drivers

**Goal:** use standard FAT volumes as secondary storage.

Tasks:
- Implement FAT12 mount, root directory listing, file read, and path lookup.
- Add FAT12 create/write/delete only after read operations are tested.
- Implement FAT16 using the same filesystem interface.
- Handle FAT copies, cluster chains, end-of-chain markers, bad clusters,
  free-cluster allocation, and volume bounds.
- Enforce each format's filename and size limitations; do not pretend FAT
  supports ODFS long names.

Exit criteria:
- Known-good FAT12 and FAT16 test images mount and list correctly.
- File contents match known test fixtures after reads.
- Write/delete tests do not corrupt neighboring files or FAT metadata.

## Phase 5 — Paths, drive letters, and shell file commands

**Goal:** make files usable from the command prompt on ODFS and FAT volumes.

Tasks:
- Implement path parsing for absolute paths, relative paths, current directory,
  drive prefixes, separators, and `.` / `..`.
- Add `DIR [path]`.
- Add `MKDIR path`.
- Add `CRTF file` (CReaTe File): create an empty file only.
- If a `CRTF` target already exists, print `File already exists` and leave
  its contents unchanged.
- Add `CAT file` for text output.
- Add `COPY source destination`; reject existing destinations unless an
  explicit future overwrite option is supplied.
- Add `DEL file` with protection for critical system files.
- Report read-only media, missing paths, invalid names, and insufficient space.

Exit criteria:
- All commands work on ODFS and on mounted FAT12/FAT16 volumes where supported.
- Tests cover missing files, existing files, nested paths, full volumes,
  read-only media, and cross-volume copies.

## Phase 6 — Text editor

**Goal:** add a reliable built-in editor.

Tasks:
- Add `EDIT [file]` with insert, delete, cursor movement, and scrolling.
- Support opening an existing text file and creating a new one.
- `Ctrl+O` opens/confirms the save operation; `Enter` confirms the filename
  or save action.
- `Ctrl+X` exits.
- If there are unsaved changes, offer Save, Discard, and Cancel.
- Save through the common filesystem interface; handle disk-full and write errors.
- Set and document an initial editor size/line-length limit until dynamic
  memory management is available.

Exit criteria:
- New and existing files can be edited and reopened with correct contents.
- Exiting with unsaved changes never silently loses data.
- Failed saves leave the previous file intact where the filesystem supports
  safe replacement.

## Phase 7 — English/Russian keyboard layout and localization

**Goal:** make text entry usable in both languages.

Tasks:
- Implement `Alt+Shift` layout switching between English and Russian.
- Keep physical key events separate from layout translation.
- Display the active layout in the status area or prompt.
- Ensure editor text entry and shell input use the selected layout.
- Add localized messages only after the keyboard and text encoding strategy
  (including Cyrillic rendering) is defined.

Exit criteria:
- The layout toggles reliably without interfering with Ctrl shortcuts.
- English and Russian text can be entered and displayed in supported contexts.
- Editor save/reopen preserves the chosen character encoding.

## Phase 8 — Integration

**Goal:** connect all implemented subsystems into one coherent operating system.

Tasks:
- Connect disk I/O, volume discovery, filesystem drivers, path handling, shell,
  editor, and keyboard layout modules through documented interfaces.
- Verify drive letters and current-directory behavior consistently across commands.
- Ensure ODFS is used for the system volume `S:` and FAT12/FAT16 volumes mount
  through the same filesystem API.
- Add clear error propagation between drivers, filesystem code, and shell.
- Update documentation to describe the integrated architecture and known limitations.

Exit criteria:
- The subsystems work together in a complete user workflow.
- No feature relies on a temporary stub where a real implementation is required.
- The integrated build boots and can access each supported filesystem.

## Phase 9 — Testing and verification

**Goal:** systematically test the complete system before calling it a release.

Tasks:
- Create repeatable test disk images and known file/directory fixtures.
- Test boot and kernel startup on clean, malformed, and unsupported disk images.
- Test ODFS format, mount, create, read, write, rename (if implemented), delete,
  directory traversal, free-space accounting, and remount persistence.
- Test FAT12 and FAT16 against known-good images, including cluster-chain edge cases.
- Test shell commands with valid paths, missing paths, existing destinations,
  nested directories, full disks, and read-only media.
- Test editor insertion, deletion, cursor movement, save, cancel, exit, and
  unsaved-change prompts.
- Test Alt+Shift switching, modifier-key combinations, and Cyrillic text handling.
- Test disk-full, write failures, corrupted metadata, invalid sectors, and
  interrupted operations; verify that errors do not silently destroy data.
- Run regression tests after every bug fix and record the results.
- Test in QEMU and, where practical, on real BIOS-compatible hardware.

Exit criteria:
- All critical test cases pass and results are recorded.
- No known data-loss or filesystem-corruption bugs remain in supported workflows.
- Any unsupported feature or limitation is clearly documented.
- A release candidate is approved only after this phase passes.

## Command reference (planned)

| Command / shortcut | Meaning |
| --- | --- |
| `DIR [path]` | List directory contents |
| `MKDIR path` | Create a directory |
| `CRTF file` | Create an empty file (CReaTe File); never overwrite |
| `CAT file` | Display a text file |
| `COPY source destination` | Copy a file; no silent overwrite |
| `DEL file` | Delete a file |
| `EDIT [file]` | Open the text editor |
| `Ctrl+O`, then `Enter` | Save/confirm in the editor |
| `Ctrl+X` | Exit the editor; prompt if changes are unsaved |
| `Alt+Shift` | Switch English/Russian keyboard layout |
| `PARTITIONS` | List structurally validated primary MBR partition entries |

## Current implementation status

The 0.1 shell remains the only user-facing runtime, but the boot path and a first read-only BIOS disk service have now been added. No filesystem driver or file command has been added. `DISKTEST` and `PARTITIONS` are read-only disk diagnostics, not filesystem commands.

- Phase 0: PowerShell build/image-validation scripts and a GitHub Actions build
  check are present. A developer still needs to run them and verify QEMU boot.
- Phase 1: architecture is documented. The loader now uses EDD LBA reads with a floppy-only CHS fallback, but still loads a fixed 4 KiB payload; console/keyboard refactoring is not implemented.
- Phase 2: a read-only EDD capability probe and LBA sector-read routine are present in `kernel/disk.asm`. Runtime verification, write support, MBR parsing, and volume bounds are not implemented.
- Phase 3: proposed ODFS v1 format documented; formatter, mount, and driver are
  not implemented. Format remains draft pending review and fixture tests.
- Phase 4: FAT12/FAT16 driver requirements documented; drivers are not
  implemented.
- Phase 5: file-command behavior and shared filesystem API documented; commands
  and filesystem API are not implemented.
- Phases 6–9: planned.

Phases 3–5 are design/specification work in this batch, not completed runtime
features. Do not mark a phase complete until its code and exit criteria have
been tested.
