; NOTE: Labels inside macros should be pre-fixed by '%%' such that the labels become local to the macro
; This allows the macro to be called multiple times, preventing the program from using the label from the first macro invocation.
; Example:
; instead of doing
; test:
; you do
; %%test:
; this makes a local label that is not accidentally re-used when the macro is invoked again later.

%macro getOutputHandle 0
    ; Gets console write handle, automatically storing result in RCX
    ; This macro will destroy the value previously stored in RCX

    push rax    ; save rax value

    sub rsp, 32     ; allocate shadow space
    mov rcx, -11    ; handle for output/writing
    call GetStdHandle

    add rsp, 32     ; remove shadow space

    mov rcx, rax    ; store result in rcx

    pop rax         ; restore rax value

%endmacro

%macro getInputHandle 0
    ; Gets console read handle, automatically storing result in RCX
    ; This macro will destroy the value previously stored in RCX

    push rax    ; save rax value
    sub rsp, 8 ; test

    sub rsp, 32     ; allocate shadow space
    mov rcx, -10    ; handle for input/reading
    call GetStdHandle

    add rsp, 32     ; remove shadow space
    add rsp, 8 ; test

    mov rcx, rax    ; store result in rcx

    pop rax         ; restore rax value

%endmacro

%macro print 3
    ; This takes in 3 arguments: print(stringPtr, numberOfCharsToWrite, addressToSaveCharsWritten).
    ; This macro prints the first N chars from the first argument to the console, where N = pointer to number of chars to print.
    ; The third argument is the address where the number of chars actually written gets stored.
    
    ; save registers that will be modified
    push rax
    push rcx
    push rdx
    push r8
    push r9

    ; invoke macro to get handle for writing to console:
    getOutputHandle ; arg1 = stores handle in rcx

    mov rdx, %1 ; arg2 = ptr to string
    mov r8, %2  ; get second argument
    mov r8, [r8] ; arg3 = integer = number of chars to write
    mov r9, %3  ; arg4 = address to store number of written chars

    sub rsp, 32 ; allocate shadow space
    push qword 0 ; arg5 = null (0)

    call WriteConsoleA

    add rsp, 8 ; remove arg5
    add rsp, 32 ; remove shadow space

    ; restore saved registers
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax

%endmacro

%macro getInput 3
    ; This takes in 3 arguments: print(inputBufferAddress, bufferLengthPtr, addressToSaveCharsRead).
    ; This macro reads and saves the first N chars from the console into the first argument address, where N = *(bufferLengthPtr)
    ; The third argument is the address where the number of chars actually read gets stored.
    ; Reading stops when the user presses the enter key
    ; NOTE: The ReadConsoleA can actually read the newline input from the user, but if the input buffer is already full from character inputs, then the newline cannot be read.
    ; This macro checks to see if the newline has been read, and if it has, it is REMOVED.

    ; save registers that will be modified
    push rax
    push rcx
    push rdx
    push r8
    push r9

    ; set rcx = arg1 = read console handle
    getInputHandle ; get input handle, automatically stored in rcx

    mov rdx, %1 ; arg2 = ptr to input buffer space
    mov r8, %2 ; arg3 = ptr to length of input buffer
    mov r9, %3 ; arg 4 = ptr to store chars actually read

    sub rsp, 32 ; allocate shadow space
    sub rsp, 8 
    mov [rsp], 0
    ; push qword 0 ; arg5 = null

    call ReadConsoleA

    ; check if newline has been read:
    ; To check, look at [strPtr + 1*charsRead] and if it equals ASCII value of \n, then replace it with 0
    mov rcx, %3   ; rcx = ptr to number of chars read
    mov rcx, [rcx]  ; get actual number of chars read (dereference ptr) 
    
    ; rdx = ptr to start of input buffer + number of bytes actually read (should point to last read byte)
    ; compute rdx = address of [%1 + rcx - 1]
    mov rdx, %1
    add rdx, rcx
    dec rdx

    ; when the enter key is pressed, two chars are passed into the console, '\r\n'. Lets check for both and remove them

    cmp byte [rdx], 13 ; check if the last byte = \r
    ; if last byte != \r, it could still equal \n
    ; if the last byte = \r, do not check for \n
    jne %%skip1
    mov byte [rdx], 0

    ; decrement the chars read by 1 since \r was removed
    mov rcx, %3
    mov rdx, [rcx]
    dec rdx
    mov [rcx], rdx

    jmp %%skip2
    %%skip1:
    cmp byte [rdx], 10 ; check if the last byte = \n
    ; if the last byte = \n, remove the \n and its preceeding \r
    jne %%skip2
    mov byte [rdx], 0
    dec rdx
    mov byte [rdx], 0

    ; decrement the chars read by 2 since \r was removed
    mov rcx, %3
    mov rdx, [rcx]
    dec rdx
    dec rdx
    mov [rcx], rdx
    %%skip2:

    add rsp, 8 ; remove arg5
    add rsp, 32 ; remove shadow space

    ; restore saved registers
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax

%endmacro

%macro openFile 1
    ; This macro opens an EXISTING file with the name input as the argument. It opens the file with all possible access rights, 
    ; allowing shared read access with default security attributes. This uses normal file attributes to open the file. The value in RAX
    ; is destroyed by this macro. If the value is needed, save RAX prior to the macro call.
    push rcx
    push rdx
    push r8
    push r9

    mov rcx, %1 ; set arg1 as file name
    mov rdx, 0x10000000 ; set arg2 as all possible access rights
    mov r8, 0x00000001 ; set arg3 to allow shared process read access
    mov r9, 0   ; arg4 -> set security to default

    ; set arg7 as null
    push qword 0

    ; set arg6 as normal file attributes
    push qword 0x80

    ; set arg5 as OPEN_EXISTING
    push qword 3

    ; allocate shadow space
    sub rsp, 32

    call CreateFileA

    add rsp, 32 ; remove shadow space
    add rsp, 24 ; remove args 5 to 7

    pop r9
    pop r8
    pop rdx
    pop rcx

%endmacro

%macro strcat 2
    ; concat(stringPtr1, stringPtr2, totalBytesOfConcatenatedString)
    ; This macro takes in 2 string pointers and the total length of the string. The string is concatenated using the stack...?



%endmacro

; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; REPLACE LARGE MACROS WITH FUNCTIONS INSTEAD. LARGE MACROS ARE NOT GOOD FOR FILE SIZE AND INSTRUCTION CACHING (i guess).
; ALSO LOOK INTO lodsb and stosb INSTRUCTIONS -- these can be used to quickly parse strings (in registers RSI and AL ?)
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

section .text

extern GetStdHandle
extern WriteConsoleA
extern ReadConsoleA
extern CreateFileA
extern WriteFile

global _start

_start:

    ; getOutputHandle ; gets output handle, storing it in rax
    print msg, msg_len, zero ; print msg_len chars from msg, storing the number of chars printing at address 0
    getInput inputBuffer, bufferLength, charsRead
    print formatTest, formatTest_len, zero
    print inputBuffer, charsRead, zero
    print formatTest2, formatTest2_len, zero

    openFile fileName   ; open the file, RAX = file handle





writeToFile:
    mov rcx, rax   ; rax holds the output of the CreateFileA function, which is the file handle
    mov rdx, inputBuffer    ; address of string holding user input
    mov r8, charsRead
    mov r8, [r8]    ; write the same number of bytes as the number of chars read
    mov r9, zero    ; temp variable for number of bytes written

    push qword 0    ; arg5 = null
    sub rsp, 32     ; allocate shadow space

    call WriteFile

    add rsp, 32     ; remove shadow space
    add rsp, 8      ; remove arg 5

end:

section .data
    zero dq 0   ; temporary/garbage variable
    
    fileName db 'test.txt', 0   ; file name must be null terminated
    
    msg db 'Hello World!', 10, 0    ; 10 = '\n
    msg_len dd $ - msg - 1 ; get msg length - 1, we do -1 because last byte is a null terminator
    
    formatTest db 'Your Input:', 10, 39, 0 ; 10 -> \n, 39 -> '
    formatTest_len dd $ - formatTest - 1

    formatTest2 db 39, 10, 0
    formatTest2_len dd $ - formatTest2 - 1

    inputBuffer times 33 db 0  ; define 33 consecutive bytes with values of 0
    bufferLength equ $ - inputBuffer - 1    ; get length of input buffer - null terminator
    charsRead dq 0