
%include "functions.asm"

extern HeapAlloc


global _start

section .text


_start:
    
    mov rcx, msg
    mov rdx, msg_len
    mov r8, charsPrinted

    sub rsp, 32
    call print
    add rsp, 32


    mov rcx, inputBuffer
    mov rdx, bufferLength
    mov r8, charsRead

    sub rsp, 32
    call input
    add rsp, 32


    mov rcx, inputBuffer
    mov rdx, charsRead
    mov rdx, [rdx]
    mov r8, charsPrinted

    sub rsp, 32
    call print
    add rsp, 32



    mov rcx, 0
    mov rdx, 128000
    mov r8, 512000

    sub rsp, 32
    call getOrCreateHeapMemory
    add rsp, 32





    ; allocate X bytes of heap memory for dynamic storage
    mov rcx, rax    ; rax holds the handle, obtained from getOrCreateHeapMemory
    mov rdx, 0x00000008 ; flag to zero out allocated memory region
    mov r8, 124000

    sub rsp, 32
    call HeapAlloc  ; rax now holds a pointer to the allocated heap memory space
    add rsp, 32




    ; this block is so that the .exe waits at the end of the program instead of instantly closing
    mov rcx, inputBuffer
    mov rdx, bufferLength
    mov r8, charsRead

    sub rsp, 32
    call input
    add rsp, 32





section .data
msg: db "Hello World", 10, 0
msg_len equ $ - msg - 1
charsPrinted: dd 0
inputBuffer: times 17 db 0
bufferLength equ $ - inputBuffer - 1
charsRead dd 0