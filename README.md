# Chip255
![Chip255](image.png)

Chip255 is CHIP-8 interpreter/emulator written in the Processing programming language. This interpreter features a debug overlay to view the current state of the machine. This includes registers, the stack, and other variables such as the program counter and timers. For more information on CHIP-8, here's the [Wikipedia link](https://en.wikipedia.org/wiki/CHIP-8)

The CHIP-8 uses a hexidecimal keypad for input. Chip255 maps each key like so:
```
1 2 3 C  ->  1 2 3 4
4 5 6 D  ->  q w e r
7 8 9 E  ->  a s d f
A 0 B F  ->  z x c v
```

I will note that this interpreter is still in development. So therefor not every CHIP-8 rom will work. However, I have tested some. Here's a list of roms that I have personally tested.
* Tetris [Fran Dachille, 1991]
* Tic-Tac-Toe [David Winter]
* Breakout [Carmelo Cortez, 1979]
* Pong 2 [David Winter, 1997]
* Pong [Paul Vervalin, 1990]
* Coin Flipping [Carmelo Cortez, 1978]

## Example images:
![Pong](pong.png)
![Breakout](breakout.png)
