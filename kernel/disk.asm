; Old-DOS BIOS EDD disk service (16-bit real mode)
;
; API:
;   disk_boot_drive: BIOS drive number captured from DL at kernel entry.
;   disk_init:       probe INT 13h extensions; CF=0 when EDD is available.
;   disk_read_lba:   input EAX=LBA (32-bit), CX=sector count (1..127),
;                    ES:BX=destination; CF=0 on success.
;
; The destination buffer must not cross a 64 KiB offset boundary.
; This module is read-only. Writes and CHS fallback are not implemented here.

DISK_RETRIES equ 3

disk_init:
    pushad
    push ds
    push es

    mov byte [disk_edd_supported], 0
    mov bx, 0x55AA
    mov ah, 0x41
    mov dl, [disk_boot_drive]
    int 0x13
    jc .done
    cmp bx, 0xAA55
    jne .done
    test cx, 1
    jz .done
    mov byte [disk_edd_supported], 1

.done:
    pop es
    pop ds
    popad
    cmp byte [disk_edd_supported], 1
    jne .unsupported
    clc
    ret
.unsupported:
    stc
    ret

; Read sectors through the BIOS Enhanced Disk Drive packet interface.
disk_read_lba:
    pushad
    push ds
    push es

    cmp byte [disk_edd_supported], 1
    jne .bad
    test cx, cx
    jz .bad
    cmp cx, 127
    ja .bad

    ; Reject a destination that crosses the 64 KiB offset boundary.
    movzx edx, cx
    shl edx, 9
    movzx eax, bx
    add eax, edx
    cmp eax, 0x10000
    ja .bad

    mov [disk_dap + 2], cx
    mov [disk_dap + 4], bx
    mov [disk_dap + 6], es
    mov [disk_dap + 8], eax ; overwritten below with the caller's LBA
    ; Recover the caller's LBA from the saved EAX on the stack.
    ; PUSHAD layout at [ESP+28] is the original EAX.
    mov eax, [ss:esp + 28]
    mov [disk_dap + 8], eax
    mov dword [disk_dap + 12], 0

    mov byte [disk_retry_count], DISK_RETRIES
.retry:
    mov word [disk_dap + 2], cx
    mov si, disk_dap
    mov ah, 0x42
    mov dl, [disk_boot_drive]
    int 0x13
    jnc .ok

    xor ah, ah
    mov dl, [disk_boot_drive]
    int 0x13
    dec byte [disk_retry_count]
    jnz .retry
    jmp .bad

.ok:
    pop es
    pop ds
    popad
    clc
    ret

.bad:
    pop es
    pop ds
    popad
    stc
    ret

disk_boot_drive db 0
disk_edd_supported db 0
disk_retry_count db 0
align 4
disk_dap:
    db 0x10, 0
    dw 0
    dw 0
    dw 0
    dq 0
