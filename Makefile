build:
	rgbasm -L -o main.o main.asm
	rgblink -o snake.gb main.o
	rgbfix -v -p 0xFF snake.gb
