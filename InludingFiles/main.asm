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

        ; Read User Input
        mov rcx, inputBuffer
        mov rdx, input_len
        mov rdx, [rdx]
        mov r8, charsRead

        sub rsp, 32
        call input
        add rsp, 32

        ; Print User Input
        mov rcx, inputBuffer
        mov rdx, charsRead
        mov rdx, [rdx]
        mov r8, zero

        sub rsp, 32
        call print
        add rsp, 32


        mov rcx, zero
        sub rsp, 32
        call getSeconds   ; RAX contains seconds, and zero holds seconds
        add rsp, 32
        
        mov rdx, 0
        mov r10, 10
        idiv r10    ; compute rdx:rax / r10, rdx = remainder, rax = result

        shl rdx, 8
        add rax, rdx
        add rax, '00'   ; convert to string chars

        push rax    ; save UNICODE (string) into stack
        mov rcx, rsp  ; ptr to string value
        mov rdx, 3  ; num of chars to print
        mov r8, zero
        sub rsp, 32
        call print
        add rsp, 32
        add rsp, 8



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
