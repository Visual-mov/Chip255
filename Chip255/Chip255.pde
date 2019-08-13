import processing.sound.*;

/* Chip255 v1.0
 *  Chip255 is an emulator / interpreter for the CHIP-8
 *  programming language. It provides a "panel" of sorts
 *  that allows you to view the current state of the machine.
 *
 *  Go to my website: visual-mov.com
 *
 *  Copywrite(c) Ryan Danver 2019
 */
 
// For debugging:
final boolean ENABLE_STEP = false;

final boolean DRAW_OVERLAY = true;
final int FRAME_RATE = 60;
final int CYCLES_PER_FRAME = 10;
final int SCALE = 15;

int WIDTH = 64;
int HEIGHT = 32;
boolean run;
PFont font;
Chip8 chip8;
void setup() {
  chip8 = new Chip8(this);
  font = createFont("ubuntu.light.ttf", 10);
  run = false;

  selectInput("Please select a rom file.", "loadRom");
  textFont(font);
  background(chip8.fground);
  noStroke();
  surface.setSize(WIDTH*SCALE, HEIGHT*SCALE + ((DRAW_OVERLAY) ? 250 : 0));
  frameRate(FRAME_RATE);

  chip8.loadFontset();
}
void draw() {
  if(!ENABLE_STEP) {
    for (int i = 0; i < CYCLES_PER_FRAME; i++) doCycle();
  }
  if (DRAW_OVERLAY) drawOverlay();
  chip8.updateTimers();
}

void keyPressed() {
  if(ENABLE_STEP) {
    if(keyCode == UP) doCycle();
  }
  chip8.pressed();
}
void keyReleased() { 
  chip8.released();
}

void loadRom(File f) {
  chip8.loadFile(f);
  run = true;
}
void doCycle() {
  if (run) {
    chip8.exOpcode();
    if (chip8.draw)
      chip8.renderPixels();
    chip8.draw = false;
  }
}
color backgroundPastel() {
  return color(random(150, 210), random(150, 210), random(150, 210));
}

void drawOverlay() {
  int sHeight = HEIGHT*SCALE;
  float xloc = width/15, yloc = sHeight + height/10;
  color textColor = 0;
  color bStroke = chip8.bground;
  char[] chars;

  short var = 0;
  String[] varNames = {"PC", "I", "DT", "ST", "SP"};

  // Drawing 16-bit varibles
  textSize(15);
  for (int i = 0; i < 2; i++) {
    fill(textColor);
    text(varNames[i], width/2 - 30, yloc+10);
    switch(i) {
    case 0: var = chip8.PC; break; 
    case 1: var = chip8.index; break;
    }
    drawBinaryString(width/2, yloc, binChars(var, 12), color(0), bStroke, 12);
    yloc+=20;
  }

  // Drawing 8-bit varibles
  yloc+=20;
  for (int i = 2; i < 5; i++) {
    fill(textColor);
    text(varNames[i], width/2 - 30, yloc+10);
    switch(i) {
    case 2: var = chip8.DTimer; break; 
    case 3: var = chip8.STimer; break; 
    case 4: var = chip8.SP; break;
    }
    drawBinaryString(width/2, yloc, binChars(var, 8), color(100, 255, 100), bStroke, 8);
    yloc+=20;
  }

  yloc = sHeight + height/10;
  // Drawing the Registers.
  fill(textColor);
  text("Registers", width/15-30, yloc - 20);
  textSize(11);
  for (int i = 0; i < chip8.V.length; i++) {
    chars = binChars(chip8.V[i], 8);
    fill(textColor);
    text("V[" + i + "]", xloc-30, yloc + 8);
    drawBinaryString(xloc, yloc, chars, color(255, 50, 50), bStroke, 8);
    yloc+=20;
    if (i >= chip8.V.length/2) {
      yloc = (i == chip8.V.length/2) ? sHeight + height/10 : yloc;
      xloc = width/5;
    } else xloc = width/15;
  }

  // Drawing the Stack.
  yloc = sHeight + height/10;
  fill(textColor);
  textSize(15);
  text("Stack", width/3-20, yloc - 20);
  textSize(11);
  for (int i = chip8.stack.length - 1; i >= 0; i--) {
    chars = binChars(chip8.stack[i], 12);
    fill(textColor);
    text(i, width/3-20, yloc + 8);
    drawBinaryString(width/3, yloc, chars, color(50, 50, 255), bStroke, 12);
    yloc+=10;
  }
}
void drawBinaryString(float x, float y, char[] binChars, color c, color s, int w) {
  stroke(s);
  for (int i = 0; i < w; i++) {
    if (binChars[i] == '1') fill(c);
    else fill(255);
    rect(x, y, 5, 10);
    x+=8;
  }
  noStroke();
}
char[] binChars(short n, int w) {
  return String.format("%"+w+"s", Integer.toString(n, 2)).replace(' ', '0').toCharArray();
}
