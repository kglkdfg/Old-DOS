; Old-DOS tiny 16-bit real-mode kernel and command shell
; Loaded by boot/boot.asm at physical address 0x8000.

BITS 16
ORG 0x8000

LINE_SIZE equ 128

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    ; Set 80x25 color text mode.
    mov ax, 0x0003
    int 0x10

    mov si, banner
    call print_string
    call newline

shell:
    mov si, prompt
    call print_string
    call read_line
    call uppercase_line

    cmp byte [line_buffer], 0
    je shell

    mov si, line_buffer
    mov di, cmd_help
    call compare_string
    jnc .help

    mov si, line_buffer
    mov di, cmd_cls
    call compare_string
    jnc .cls

    mov si, line_buffer
    mov di, cmd_ver
    call compare_string
    jnc .ver

    mov si, line_buffer
    mov di, cmd_reboot
    call compare_string
    jnc .reboot

    ; ECHO accepts either "ECHO" or "ECHO text".
    mov si, line_buffer
    mov di, cmd_echo
    call compare_prefix
    jc .unknown
    cmp byte [si], 0
    je .echo
    cmp byte [si], ' '
    jne .unknown

.echo:
    inc si
.skip_echo_spaces:
    cmp byte [si], ' '
    jne .print_echo
    inc si
    jmp .skip_echo_spaces
.print_echo:
    call print_string
    call newline
    jmp shell

.help:
    mov si, help_text
    call print_string
    jmp shell

.cls:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    mov bh, 0
    mov dx, 0
    int 0x10
    jmp shell

.ver:
    mov si, version_text
    call print_string
    jmp shell

.reboot:
    int 0x19
    jmp $

.unknown:
    mov si, unknown_text
    call print_string
    jmp shell

; Print a zero-terminated string at DS:SI.
print_string:
    lodsb
    test al, al
    jz .done
    call put_char
    jmp print_string
.done:
    ret

; Print character in AL using BIOS teletype.
put_char:
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    ret

newline:
    mov al, 13
    call put_char
    mov al, 10
    call put_char
    ret

; Read one line from the keyboard into line_buffer.
read_line:
    mov di, line_buffer
    xor cx, cx
.read_key:
    xor ah, ah
    int 0x16
    cmp al, 13
    je .enter
    cmp al, 8
    je .backspace
    cmp al, 32
    jb .read_key
    cmp cx, LINE_SIZE-1
    jae .read_key
    stosb
    inc cx
    call put_char
    jmp .read_key
.backspace:
    cmp cx, 0
    je .read_key
    dec di
    dec cx
    mov al, 8
    call put_char
    mov al, ' '
    call put_char
    mov al, 8
    call put_char
    jmp .read_key
.enter:
    mov byte [di], 0
    call newline
    ret

; Convert the command line to uppercase for case-insensitive commands.
uppercase_line:
    mov si, line_buffer
.next:
    mov al, [si]
    test al, al
    jz .done
    cmp al, 'a'
    jb .advance
    cmp al, 'z'
    ja .advance
    sub byte [si], 32
.advance:
    inc si
    jmp .next
.done:
    ret

; Compare zero-terminated DS:SI and DS:DI.
; Returns CF=0 when equal, CF=1 otherwise.
compare_string:
.loop:
    mov al, [si]
    cmp al, [di]
    jne .different
    test al, al
    jz .same
    inc si
    inc di
    jmp .loop
.same:
    clc
    ret
.different:
    stc
    ret

; Compare command prefix DS:DI. SI is left pointing after the prefix.
; Returns CF=0 on match, CF=1 otherwise.
compare_prefix:
.loop:
    mov al, [di]
    test al, al
    jz .same
    cmp al, [si]
    jne .different
    inc si
    inc di
    jmp .loop
.same:
    clc
    ret
.different:
    stc
    ret

banner db 'Old-DOS 0.1 - 16-bit real mode', 13, 10
       db 'Type HELP to see available commands.', 13, 10, 0
prompt db 'A:\> ', 0
cmd_help db 'HELP', 0
cmd_cls db 'CLS', 0
cmd_ver db 'VER', 0
cmd_reboot db 'REBOOT', 0
cmd_echo db 'ECHO', 0
help_text db 'Commands:', 13, 10
          db '  HELP   Show this help', 13, 10
          db '  CLS    Clear the screen', 13, 10
          db '  VER    Show OS version', 13, 10
          db '  ECHO   Print text', 13, 10
          db '  REBOOT Restart the machine', 13, 10, 0
version_text db 'Old-DOS version 0.1 (BIOS, 16-bit real mode)', 13, 10, 0
unknown_text db 'Bad command. Type HELP.', 13, 10, 0
line_buffer times LINE_SIZE db 0
