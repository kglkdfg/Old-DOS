; Old-DOS BIOS EDD disk service (16-bit real mode)
;
; API:
;   disk_boot_drive: BIOS drive number captured from DL at kernel entry.
;   disk_init:       probe INT 13h extensions; CF=0 when EDD is available.
;   disk_read_lba:   input EAX=LBA (32-bit), CX=sector count (1..127),
;                    ES:BX=destination; CF=0 on success.
;
; The physical destination buffer must not cross a 64 KiB DMA boundary.
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
    call disk_get_params
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
    mov [disk_dap + 8], eax
    mov [disk_request_count], cx
    cmp byte [disk_capacity_valid], 1
    jne .capacity_unavailable
    mov edx, eax
    movzx ecx, cx
    add edx, ecx
    jc .bad
    cmp edx, [disk_total_sectors]
    ja .bad
.capacity_unavailable:
    test cx, cx
    jz .bad
    cmp cx, 127
    ja .bad

    ; Reject a destination that crosses a physical 64 KiB DMA boundary.
    ; EDD evaluates the linear buffer address, not BX in isolation.
    movzx edx, cx
    shl edx, 9
    mov ax, es
    movzx eax, ax
    shl eax, 4
    movzx ebx, bx
    add eax, ebx
    and eax, 0xFFFF
    add eax, edx
    cmp eax, 0x10000
    ja .bad

    mov [disk_dap + 2], cx
    mov [disk_dap + 4], bx
    mov [disk_dap + 6], es
    mov dword [disk_dap + 12], 0

    mov byte [disk_retry_count], DISK_RETRIES
.retry:
    mov ax, 0
    mov ds, ax
    mov ax, [disk_request_count]
    mov [disk_dap + 2], ax
    mov si, disk_dap
    mov ah, 0x42
    mov dl, [disk_boot_drive]
    int 0x13
    jnc .ok

    xor ah, ah
    mov dl, [disk_boot_drive]
    int 0x13
    xor ax, ax
    mov ds, ax
    dec byte [disk_retry_count]
    jnz .retry
    jmp .bad

.ok:
    xor ax, ax
    mov ds, ax
    mov ax, [disk_dap + 2]
    cmp ax, [disk_request_count]
    jne .bad
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
disk_request_count dw 0
disk_test_buffer times 512 db 0

; Query EDD drive parameters (INT 13h AH=48h).
; Capacity is accepted only for 512-byte sectors and a 32-bit sector count.
disk_get_params:
    pushad
    push ds
    push es
    xor ax, ax
    mov ds, ax
    mov byte [disk_capacity_valid], 0
    mov word [disk_params_buffer], 0x001E
    mov si, disk_params_buffer
    mov ah, 0x48
    mov dl, [disk_boot_drive]
    int 0x13
    jc .done
    cmp word [disk_params_buffer + 24], 512
    jne .done
    cmp dword [disk_params_buffer + 20], 0
    jne .done
    mov eax, [disk_params_buffer + 16]
    test eax, eax
    jz .done
    mov [disk_total_sectors], eax
    mov byte [disk_capacity_valid], 1
.done:
    pop es
    pop ds
    popad
    cmp byte [disk_capacity_valid], 1
    jne .unsupported
    clc
    ret
.unsupported:
    stc
    ret

; Scan and validate the four primary MBR partition entries.
; Output:
;   CF=0: MBR signature valid and table structurally valid.
;   CF=1: disk read failed, signature invalid, overflow, or overlap.
;   disk_partition_count: number of non-empty primary entries.
;   disk_partitions: four 12-byte records:
;       +0 type byte, +1 boot flag byte, +2 start LBA dword,
;       +6 sector count dword, +10 reserved word.
; Extended partition entries are reported as types only; logical
; partitions are not traversed by this routine.
disk_scan_mbr:
    pushad
    push ds
    push es

    xor ax, ax
    mov ds, ax
    mov es, ax
    xor eax, eax
    mov cx, 1
    mov bx, disk_mbr_buffer
    call disk_read_lba
    jc .invalid

    cmp word [disk_mbr_buffer + 510], 0xAA55
    jne .invalid

    mov byte [disk_partition_count], 0
    mov byte [disk_partition_invalid], 0
    mov si, disk_mbr_buffer + 446
    mov di, disk_partitions
    mov bp, 4

.entry:
    mov al, [si + 4]
    test al, al
    jz .next
    mov [di], al
    mov al, [si]
    cmp al, 0
    je .boot_ok
    cmp al, 0x80
    jne .invalid
.boot_ok:
    mov [di + 1], al
    mov eax, [si + 8]
    mov [di + 2], eax
    mov edx, [si + 12]
    mov [di + 6], edx

    test eax, eax
    jz .invalid
    test edx, edx
    jz .invalid
    add eax, edx
    jc .invalid
    cmp byte [disk_capacity_valid], 1
    jne .capacity_unchecked
    cmp eax, [disk_total_sectors]
    ja .invalid
.capacity_unchecked:

    ; Check overlap against every earlier accepted primary partition.
    push si
    push di
    push bp
    mov bx, disk_partitions
    mov cl, [disk_partition_count]
    xor ch, ch
.overlap_loop:
    jcxz .overlap_done
    mov eax, [di + 2]
    mov edx, [di + 6]
    add eax, edx                 ; current exclusive end
    mov edx, [bx + 2]            ; prior start
    cmp eax, edx
    jbe .no_overlap
    mov eax, [bx + 2]
    mov edx, [bx + 6]
    add eax, edx                 ; prior exclusive end
    mov edx, [di + 2]            ; current start
    cmp eax, edx
    ja .overlap_bad
.no_overlap:
    add bx, 12
    loop .overlap_loop
.overlap_done:
    pop bp
    pop di
    pop si
    mov word [di + 10], 0
    inc byte [disk_partition_count]
    add di, 12

.next:
    add si, 16
    dec bp
    jnz .entry

    pop es
    pop ds
    popad
    clc
    ret

.overlap_bad:
    pop bp
    pop di
    pop si
.invalid:
    mov byte [disk_partition_count], 0
    pop es
    pop ds
    popad
    stc
    ret

disk_partition_count db 0
disk_capacity_valid db 0
disk_total_sectors dd 0
align 4
disk_params_buffer times 30 db 0
disk_mbr_buffer times 512 db 0
disk_partitions times 4*12 db 0

align 4
disk_dap:
    db 0x10, 0
    dw 0
    dw 0
    dw 0
    dq 0
