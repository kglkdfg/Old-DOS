; Old-DOS stage-1 BIOS bootloader
; Loads the 4 KiB kernel payload at LBA 1 into 0000:8000.
; Uses INT 13h extensions when available, with a floppy-compatible CHS fallback.

BITS 16
ORG 0x7C00

KERNEL_SEGMENT equ 0x0000
KERNEL_OFFSET equ 0x8000
KERNEL_SECTORS equ 8
DISK_RETRIES equ 3

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    mov [boot_drive], dl

    ; Probe INT 13h extensions (EDD).
    mov bx, 0x55AA
    mov ah, 0x41
    mov dl, [boot_drive]
    int 0x13
    jc .no_edd
    cmp bx, 0xAA55
    jne .no_edd
    test cx, 1
    jz .no_edd

    ; EDD read: kernel begins immediately after the boot sector (LBA 1).
    mov byte [retries], DISK_RETRIES
.edd_retry:
    mov word [disk_packet + 2], KERNEL_SECTORS
    mov si, disk_packet
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jnc boot_kernel

    ; Reset the device before retrying.
    xor ah, ah
    mov dl, [boot_drive]
    int 0x13
    dec byte [retries]
    jnz .edd_retry

    ; Do not guess CHS geometry for hard disks.
    cmp byte [boot_drive], 0x80
    jae disk_error
    jmp chs_read

.no_edd:
    ; CHS fallback is intentionally limited to floppy drives.
    cmp byte [boot_drive], 0x80
    jae disk_error

chs_read:
    ; Compatibility path for the 1.44 MiB floppy image:
    ; cylinder 0, head 0, sectors 2 through 9.
    mov byte [retries], DISK_RETRIES
.chs_retry:
    mov ax, KERNEL_SEGMENT
    mov es, ax
    mov bx, KERNEL_OFFSET
    mov ax, 0x0200 | KERNEL_SECTORS
    mov cx, 0x0002
    xor dh, dh
    mov dl, [boot_drive]
    int 0x13
    jnc boot_kernel

    xor ah, ah
    mov dl, [boot_drive]
    int 0x13
    dec byte [retries]
    jnz .chs_retry
    jmp disk_error

boot_kernel:
    mov dl, [boot_drive]
    jmp KERNEL_SEGMENT:KERNEL_OFFSET

disk_error:
    mov si, error_message
.print_error:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp .print_error
.halt:
    cli
    hlt
    jmp .halt

boot_drive db 0
retries db 0
align 4
disk_packet:
    db 0x10, 0
    dw KERNEL_SECTORS
    dw KERNEL_OFFSET
    dw KERNEL_SEGMENT
    dq 1

error_message db 13, 10, 'Old-DOS: disk read error', 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
