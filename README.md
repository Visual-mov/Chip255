# Chip255
<img src="image.png" alt="Chip255" width="400"/>

Chip255 is CHIP-8 interpreter/emulator written in the Processing programming language. This interpreter features a debug overlay to view the current state of the machine, which includes registers, the stack, and other variables such as the program counter and timers. For more information on CHIP-8, visit the [Wikipedia link](https://en.wikipedia.org/wiki/CHIP-8)

The CHIP-8 uses a hexadecimal keypad for input. Chip255 maps each key like so:
```
1 2 3 C  ->  1 2 3 4
4 5 6 D  ->  q w e r
7 8 9 E  ->  a s d f
A 0 B F  ->  z x c v
```

## Getting Started
Clone repo:
```
~$ git clone https://github.com/Visual-mov/Chip255
```
Open Chip255/Chip255/Chip255.pde in the Processing editor (Yes I know the path looks awful).
Then open a CHIP-8 ROM via the given prompt.

## Example images:
<img src="pong.png" alt="Pong" width="500"/>
<img src="breakout.png" alt="Breakout" width="500"/>
