; Old-DOS stage-1 BIOS bootloader
; Loads 8 sectors (4 KiB) from the floppy into 0000:8000 and jumps there.

BITS 16
ORG 0x7C00

KERNEL_SEGMENT equ 0x0000
KERNEL_OFFSET equ 0x8000
KERNEL_SECTORS equ 8

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

    ; Read sectors 2..9 from cylinder 0, head 0.
    mov ax, KERNEL_SEGMENT
    mov es, ax
    mov bx, KERNEL_OFFSET
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

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
error_message db 13, 10, 'Old-DOS: disk read error', 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
