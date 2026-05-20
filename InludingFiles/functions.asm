extern GetStdHandle
extern WriteConsoleA
extern ReadConsoleA
extern GetSystemTime

global print
global getMillis
global getSeconds
global input
global splitInt


%macro getAndSetTimeData 0
        push rbp
        mov rbp, rsp
        push rax
        mov [rbp+2*8], rcx  ; store rcx inside shadow 1

        call GetSystemTime
        pop rax
        ; now rsp + 0 -> holds a pointer to system time info
        mov rcx, [rbp+2*8]
        ; movzx rax, word [rcx+2*6]  ; extract seconds
        movzx rax, word [rcx+rax]  ; extract seconds
        mov [rcx], rax

        pop rbp ; restore base pointer
%endmacro
    ; Before Function:
    ; save any regs
    ; pass arguments into regs and stack; pass args in stack in reverse order
    ; save shadow space; 32 bytes -- for 4 args
    ; call function

    ; Inside Function:
    ; save current rbp register
    ; copy current rsp into rbp
    ; allocate space for local variables using sub rsp, N
    ; save any regs
    ; right before returning:
        ; store function result in rax
        ; restore stack to state at beginning of function
        ; restore previous rbp value
        ; return from function

    ; void = print(*String, numOfCharsToPrint, *numOfCharsPrinted)
    print:
        ; arg1 = rcx = ptr to string to print
        ; arg2 = rdx = number of chars to print
        ; arg3 = r8 = address to save number of chars written

        ; rsp -> return value
        ; rsp + 8 -> shadow space 1
        ; rsp + 16 -> shadow space 2
        ; rsp + 24 -> shadow space 3
        ; rsp + 32 -> shadow space 4
        ; ... any additional function args
        ; ... saved registers prior to function call

        ; Lets first store the base pointer, rbp, then store rsp into rbp as a base point
        push rbp        ; save previous base point
        mov rbp, rsp    ; set base point
        ; rsp, rbp -> old rbp
        ; rsp + 8 -> return value
        ; rsp + 16 -> shadow space 1
        ; rsp + 24 -> shadow space 2
        ; rsp + 32 -> shadow space 3
        ; rsp + 40 -> shadow space 4

        ; we do not need any locals

        ; lets save this functions arguments into the shadow space:
        mov [rbp+2*8], rcx ; store arg1 (rcx) -> shadow space 1
        mov [rbp+3*8], rdx ; arg2 -> shadow 2
        mov [rbp+4*8], r8 ; arg3 -> shadow 3


        ; get the console output handle
        sub rsp, 32     ; allocate shadow space
        mov rcx, -11    ; handle for output/writing
        call GetStdHandle
        add rsp, 32     ; remove shadow space
        mov rcx, rax    ; store result in rcx

        ; setup arguments for printing to console
        ; arg1 = output handle (already set)
        mov rdx, [rbp+2*8] ; set arg2 value (ptr to string)
        mov r8, [rbp+3*8]  ; set arg3 value (num of chars to print)
        mov r9, [rbp+4*8]  ; set arg4 value (ptr to place to store num of chars written)
        push qword 0    ; set arg5 = null/0

        sub rsp, 32 ; allocate shadow space
        call WriteConsoleA
        add rsp, 32 ; remove shadow space
        add rsp, 8 ; remove arg5 

        pop rbp

    ret


    ; void = input(*inputBuffer, numOfCharsToRead, *numOfCharsActuallyRead)
    input:
        ; Before anything, do initial setup 
        push rbp
        mov rbp, rsp    ; save rbp and current rsp

        ; save input() function's arguments into shadow space
        mov [rbp+2*8], rcx  ; shadow1 = *inputBuffer
        mov [rbp+3*8], rdx  ; shadow2 = numOfCharsToRead
        mov [rbp+4*8], r8   ; shadow3 = *numOfCharsActuallyRead

        ; Start by getting console handle for reading input
        sub rsp, 32     ; allocate shadow space
        mov rcx, -10    ; handle for input/reading
        call GetStdHandle
        add rsp, 32     ; remove shadow space

        mov rcx, rax    ; setup arg1 (console read handle)
    
        ; Now setup remaining arguments to read from console
        mov rdx, [rbp+2*8]  ; arg2 = *inputBuffer
        mov r8, [rbp+3*8]   ; arg3 = numOfCharsToRead
        mov r9, [rbp+4*8]   ; arg4 = *numOfCharsActuallyRead

        sub rsp, 32 ; allocate shadow space
        call ReadConsoleA
        add rsp, 32  ; remove shadow space


        ; Now we have the user input, lets clean it up
        ; If the user input < numOfCharsToRead - 2, then the last 2 chars = \r\n (the 'enter' key)
        ; If the user input < numOfCharsToRead - 1, then the last char = \r
        ; If the user input >= numOfCharsToRead, then the last char != \n or \r 
        ; Note: actualCharsRead includes \r and \n

        ; Lets perform the trim to remove the \n and \r
        mov r9, [rbp+4*8] ; r9 = *numOfCharsActuallyRead
        mov r8, qword [r9] ; r8 = integer value of chars actually read
        mov rdx, [rbp+2*8] ; rdx = *inputBuffer
        ; compute rdx = inputBufferAddrses + number of chars read (byte offset) - 1
        add rdx, r8
        dec rdx ; rdx now holds the address of the last byte that was read

        ; movzx rcx, byte [rdx+r8] ; rcx = last byte in the input buffer

        ; ALSO CHECK IF STRING IS EMPTY!!!!!


        ; check if string ends with \n, if so remove \n and the byte before it (\r)
        ; if the string does not end with \n, check for \r
        cmp byte [rdx], 10 ; 10 = \n
        jne skipN
            ; replace \n byte with NULL
            mov byte [rdx], 0
            ; reduce actual number of chars read by 1
            dec r8
            ; replace \r byte with NULL
            dec rdx
            mov byte [rdx], 0
            ; update actual number of chars read
            dec r8
            mov [r9], r8 
            jmp finishTrim
        skipN:
        cmp byte [rdx], 13 ; 13 = \r
        jne finishTrim   ; if the last byte != \r, skip the remove code
            ; replace \r byte with NULL
            mov byte [rdx], 0

            ; reduce actual number of chars read by 1
            dec r8
            mov [r9], r8 
        finishTrim:

        pop rbp

    ret




    ; void = splitInt(int num, int N, *resultBuffer)
    splitInt:
    ; This function takes the input integer 'num', splits it into the first 'N' digits, storing
    ; each digit as a single byte at the result buffer address. The lowest digit is stored first.
    ; Lowest digit is stored at the highest address, highest digit at lowest address.

        push rbp
        mov rbp, rsp
        ; rcx = number
        ; rdx = N
        ; r8 = *resultBuffer

        ; save variables into the shadow space
        mov [rbp+2*8], rcx
        mov [rbp+3*8], rdx
        mov [rbp+4*8], rdx

        mov r9, 10
        mov r10, rdx    ; let r10 = N
        mov rax, rcx    ; let rax = number
        ; sub rsp, r10    ; make N bytes of space in stack

        add r8, r10 ; r8+N --> store the digits in reverse order, lowest digit at highest address
        dec r8

        .loop:
            mov rdx, 0  ; reset rdx
            idiv r9     ; perform rdx:rax / 10 -> rax = result, rdx = remainder
            ; rdx now holds the lowest digit from rax
            add rdx, '0'
            mov [r8], dl    ; dl = lowesst 8-bits of rdx
            dec r8
            dec r10
            cmp r10, 0
            jne .loop

        



        pop rbp
    ret






    ; WORD timeValue = getTime(*locationToStoreTimeValue)
    getSeconds:
        mov rax, 12  ; 2*6
        getAndSetTimeData
    ret
    ; getMillis:
    ;     mov rax, 14  ; 2*7
    ;     getAndSetTimeData
    ;     ret
        


    ; -------------------------------------------------------------------------------------------------------------------------------------- ;
    ; Find out how to make private functions -- make it so that getAndSetTimeData is NOT accessible even when doing %include "functions.asm" ;
    ; -------------------------------------------------------------------------------------------------------------------------------------- ;

    ; called by the get'Time' functions, like getSeconds and getMillis

    

    