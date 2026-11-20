; Old-DOS BIOS boot sector
; Assemble with: nasm -f bin boot/boot.asm -o build/boot.bin
; This is a tiny first milestone: verify BIOS boot and print a banner.

BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    mov si, message
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp .print

.halt:
    cli
.wait:
    hlt
    jmp .wait

message db 13, 10
        db 'Old-DOS booted!', 13, 10
        db 'BIOS boot sector is alive.', 13, 10
        db 'Next: load the kernel.', 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
