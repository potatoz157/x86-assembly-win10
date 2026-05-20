nasm -f win64 -g test.asm -o test.obj
gcc -o test.exe test.obj -lkernel32 -m64 -nostartfiles -e _start
gdb test.exe
pause
