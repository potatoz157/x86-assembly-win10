%include "functions.asm"

section .text
    global _start

    _start:
        push rbp
        mov rbp, rsp

        ; Print Hello World!
        mov rcx, msg
        mov rdx, msg_len
        mov rdx, [rdx]
        mov r8, zero

        sub rsp, 32
        call print
        add rsp, 32


        mov rcx, 12345678
        mov rdx, 14
        mov r8, inputBuffer
        sub rsp, 32
        call splitInt
        add rsp, 32

        ; read the split integer
        mov rcx, inputBuffer
        mov rax, [rcx]
        ; convert to UNICODE
        ; add rax, '00000'
        mov [rcx], rax

        ; print split values as UNICODE
        mov rcx, inputBuffer
        mov rdx, 14
        mov r8, zero

        sub rsp, 32
        call print
        add rsp, 32


        pop rbp
    end:

section .data
zero dq 0   ; define temporary memory space
systemTime dq 0 ; will hold a pointer to system time struct

; define string data for program start
msg db "Hello World!", 10, 0
msg_len dq $ - msg - 1

; define buffer + length for taking user input
inputBuffer times 33 db 0
input_len dq $ - inputBuffer - 1
charsRead dq 0
