extern GetStdHandle
extern WriteConsoleA
extern ReadConsoleA
extern GetProcessHeap
extern HeapCreate


global input



    ; void = print(*String, numOfCharsToPrint, *numOfCharsPrinted)
    print:
        ; arg1 = rcx = ptr to string to print
        ; arg2 = rdx = number of chars to print
        ; arg3 = r8 = address to save number of chars written

        ; Lets first store the base pointer, rbp, then store rsp into rbp as a base point
        push rbp        ; save previous base point
        mov rbp, rsp    ; set base point


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
        mov r9, [rbp+4*8] ; r9 = *numOfCharsActuallyRead (32-bits)
        movzx r8, dword [r9] ; r8 = integer value of chars actually read
        mov rdx, [rbp+2*8] ; rdx = *inputBuffer
        ; compute rdx = inputBufferAddrses + number of chars read (byte offset) - 1
        add rdx, r8
        dec rdx ; rdx now holds the address of the last byte that was read

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


    ; MemoryStartAddress = memalloc(HANDLE heapMemoryHandle, DWORD flOptions, DWORD size)
    memalloc:

    



    ; HANDLE = getOrCreateHeapMemory(DWORD flOptions, DWORD initialSize, DWORD maxSize)
    getOrCreateHeapMemory:
        ; Obtains the handle to heap memory space based on the initial size. initialSize must be < maxSize, except if maxSize = 0.
        ; The heap memory space is either default, or if it is created, then it is growable (heapAlloc will allocate more heap memory space > maxSize if needed)

        ; if maxSize is zero, then the heap can grow in size, limited only by available memory space

        ; if maxSize is NOT zero, then heap size is fixed and cannot grow beyond the given value, additionally, the largest
        ; heap block size is 512kB for 32-bit and 1024kB for 64-bit processes. Attempts to allocate larger blocks fail even if maxSize is > 1024kB

        ; flOptions = see documentation for HeapCreate() for details. Just set as zero for now.
        ; initialSize = initial size of the heap in bytes
        ; maxSize = maximum size of the heap in bytes

        ; GetProcessHeap(no args) -- returns a handle to the default heap of the process. If the function fails, it returns NULL
        ; HeapCreate(args) -- reserves memory space defined by initial size. HeapAlloc or HeapReAlloc can be used to allocate space from the handle to the heap memory

        push rbp
        mov rbp, rsp

        ; save memalloc arguments
        mov [rbp+2*8], rcx
        mov [rbp+3*8], rdx
        mov [rbp+4*8], r8

        ; see if the process has a default heap
        mov rcx, 0
        sub rsp, 32
        call GetProcessHeap ; return value in RAX
        add rsp, 32

        cmp rax, 0

        ; if rax != 0, skip HeapCreate()
        jne skipHeapCreate
        
            ; restore register args
            mov rcx, [rbp+2*8]
            mov rdx, [rbp+3*8]
            mov r8, [rbp+4*8]
            
            sub rsp, 32
            call HeapCreate
            add rsp, 32

        skipHeapCreate:
        pop rbp

    ret

