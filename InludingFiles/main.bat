nasm -f win64 -g main.asm -o main.obj
gcc -o main.exe main.obj -lkernel32 -m64 -nostartfiles -e _start
gdb main.exe
pause
