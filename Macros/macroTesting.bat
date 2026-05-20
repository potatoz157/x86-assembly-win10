nasm -g -F cv8 -f win64 macroTesting.asm -o macroTesting.obj
gcc -o macroTesting.exe macroTesting.obj -lkernel32 -m64 -nostartfiles -e _start
gdb macroTesting.exe
pause