nasm -g -F cv8 -f win64 test.asm -o test.obj
gcc -o test.exe test.obj -lkernel32 -m64 -nostartfiles -e _start
gdb test.exe
pause