import java.io.*;

class Chip8 {
  byte[] V;
  short index;
  short PC;
  byte DTimer, STimer, SP;
  short[] mem;
  short[] stack;
  byte[][] dmem;
  byte[] keypad;
  short[] fontset;
  boolean draw;
  SqrOsc osc;
  color bground;
  color fground;
  
  int BEEP_DELAY = 60;
  int BEEP_FREQ = 300;
  short PROG_START = 0x200;
  
  Chip8(PApplet parent) {
    V = new byte[16];
    for (int i=0; i < V.length; i++) V[i] = 0;
    SP = 0;
    index = 0;
    DTimer = 0;
    STimer = 0;
    PC = PROG_START;
    draw = false;
    mem = new short[4096];
    stack = new short[16];
    dmem = new byte[WIDTH][HEIGHT];
    keypad = new byte[16];
    
    // Chip-8 fontset
    fontset = new short[] {
      0xF0, 0x90, 0x90, 0x90, 0xF0, 
      0x20, 0x60, 0x20, 0x20, 0x70, 
      0xF0, 0x10, 0xF0, 0x80, 0xF0, 
      0xF0, 0x10, 0xF0, 0x10, 0xF0, 
      0x90, 0x90, 0xF0, 0x10, 0x10, 
      0xF0, 0x80, 0xF0, 0x10, 0xF0, 
      0xF0, 0x80, 0xF0, 0x90, 0xF0, 
      0xF0, 0x10, 0x20, 0x40, 0x40, 
      0xF0, 0x90, 0xF0, 0x90, 0xF0, 
      0xF0, 0x90, 0xF0, 0x10, 0xF0, 
      0xF0, 0x90, 0xF0, 0x90, 0x90, 
      0xE0, 0x90, 0xE0, 0x90, 0xE0, 
      0xF0, 0x80, 0x80, 0x80, 0xF0, 
      0xE0, 0x90, 0x90, 0x90, 0xE0, 
      0xF0, 0x80, 0xF0, 0x80, 0xF0, 
      0xF0, 0x80, 0xF0, 0x80, 0x80
    };
    
    bground = backgroundPastel();
    fground = 255;
    osc = new SqrOsc(parent);
    osc.freq(300);
  }
  void loadFontset() {
    for (int i = 0; i < 80; i++) {
      mem[i] = fontset[i];
    }
  }
  void loadFile(File f) {
    if(f == null) {
      throwError("Error loading file.");
      return;
    } else if(f.length() > mem.length) {
      throwError("File size too large.");
      return;
    }
    short[] data = new short[(int) (f.length())];
    try {
      DataInputStream d = new DataInputStream(new FileInputStream(f));
      int index = 0;
      while(d.available() > 0) data[index++] = (short) d.read();
      d.close();
    } catch(Exception e) {
      e.printStackTrace();
      println("Error reading ROM.");
    }
    for(int i = 0; i < data.length; i++) {
      mem[0x200 + i] = data[i];
    }
  }
  
  // Console debug functions:
  void printmem(int min, int max) {
    for (int i = min; i < max; i++) {
      println(hex(i) + " : 0x" + hex(mem[i]));
    }
  }
  void printState() {
    System.out.printf("OP: 0x%04x\nPC: 0x%04x\nDT: 0x%02x\nST: 0x%02x\n", (mem[PC] << 8 | mem[PC+1]), PC, DTimer, STimer);
    for (int i = 0; i < V.length; i++) {
      System.out.printf("V[%x]: ", i);
      System.out.printf("0x%02x ", V[i]);
    }
    for(int i =0 ; i < keypad.length; i++) {
      if(i % 4 == 0) print("\n");
      print(keypad[i] + " ");
    }
    println("\n");
  }

  void exOpcode() {
    if(PC+1 >= mem.length) {
      run = false;
      return;
    }
    short op = (short) (mem[PC] << 8 | mem[PC+1]);
    short nnn = (short) (op & 0x0FFF);
    byte x = (byte) ((op & 0x0F00) >> 8);
    byte y = (byte) ((op & 0x00F0) >> 4);
    byte kk = (byte) (op & 0x00FF);
    
    //printState();
    switch(op & 0xF000) {
    default: opError(op); break;
    case 0x0000:
      switch(op) {
      default: opError(op); break;
      
      // 00E0 - Clear Display
      case 0x00E0: 
        clearPixels(); 
        draw = true;
        break;
      
      // 00EE - Return
      case 0x00EE: PC = stack[--SP]; break;
      }
      break;
      
    // 1NNN - Flow: PC = NNN
    case 0x1000: PC = (short) (nnn - 2); break;
    
    // 2NNN - Call: NNN
    case 0x2000:
      stack[SP++] = PC;
      PC = (short) (nnn - 2);
      break;
      
    // 3XNN - Skip next instruction if: Vx = kk.
    case 0x3000: if (V[x] == kk) PC+=2; break;
    
    // 4XNN - Skip next instruction if: Vx != kk.
    case 0x4000: if (V[x] != kk) PC+=2; break;
    
    // 5XY0 - Skip next instruction if: Vx = Vy.
    case 0x5000: if (V[x] == V[y]) PC+=2; break;
    
    // 6XNN - Assign: Vx = kk
    case 0x6000: V[x] = kk; break;
    
    // 7XNN - Assign: Vx += kk
    case 0x7000: V[x] += kk; break;
    
    case 0x8000:
      switch(op & 0x000F) {
      default: opError(op); break;
      
      // 8XY0 - Assign: Vx = Vy
      case 0x0000: V[x] = V[y]; break;
      
      // 8XY1 - Assign: Vx |= Vy
      case 0x0001: V[x] |= V[y]; break;
      
      // 8XY2 - Assign: Vx &= Vy
      case 0x0002: V[x] &= V[y]; break;
      
      // 8XY3 - Assign: Vx ^= Vy
      case 0x0003: V[x] ^= V[y]; break;
      
      // 8XY4 - Assign: Vx += Vy , Vf = Carry
      case 0x0004:
        V[15] = ((short) V[x] + (short) V[y] > 0xFF) ? (byte) 1 : 0;
        V[x] += V[y];
        break;
        
      // 8XY5 - Assign: Vx -= Vy , Vf = NOT Borrow
      case 0x0005:
        V[15] = (V[y] > V[x]) ? (byte) 0 : 1;
        V[x] -= V[y];
        break;
        
      // 8XY6 - Assign: Vx >>= 1 , Vf = Least-sig bit of Vx
      case 0x0006:
        V[15] = (byte) (V[x] & 0x01);
        V[x] >>= 1;
        break;
      // 8XY7 - Assign: Vx = Vy - Vx , Vf = NOT Borrow
      case 0x0007:
        V[15] = (V[y] > V[x]) ? (byte) 1 : 0;
        V[x] = (byte) (V[y] - V[x]);
        break;
      // 8XYE - Assign: Vx <<= 1 , Vf = Most-sig bit of Vx
      case 0x000E:
        V[15] = (byte) ((V[x] >> 7) & 0x1);
        V[x] <<= 1;
        break;
      }
      break;
    // 9XY0 - Skip Next Instruction if: Vx != Vy
    case 0x9000: if (V[x] != V[y]) PC+=2; break;
    
    // ANNN - Flow: I == NNN
    case 0xA000: index = nnn; break;
    
    // BNNN - Flow: PC = NNN + V0
    case 0xB000: PC = (short) ((nnn + V[0]) - 2); break;
    
    // CXNN - Assign: Vx = randNum & kk
    case 0xC000: V[x] = (byte) ((byte) random(0xFF) & kk); break;
    
    // DXYN - Draw Sprite of N length at: (Vx, Vy)
    case 0xD000:
      V[15] = 0;
      int xloc = 0, yloc = 0;
      for (int i = index; i < index + (op & 0x000F); i++) {
        for (int j = 0; j < 8; j++) {
          byte curBit = (byte) ((mem[i] >> j) & 0x1);
          xloc = (V[x] + (7 - j)) % WIDTH;
          yloc = (V[y] + (i - index)) % HEIGHT;
          if((yloc <= HEIGHT && xloc <= WIDTH) && (yloc >= 0 && xloc >= 0)) {
            if(dmem[xloc][yloc] == 1 && curBit == 1) V[15] = 1;
            dmem[xloc][yloc] ^= curBit;
          }
        }
      }
      draw = true;
      break;
      
    case 0xE000:
      switch(kk) {
      default: opError(op); break;
      
      // EX9E - Skip Next Instruction if: key Vx == 1
      case (byte) 0x009E: if (keypad[V[x]] == 1) PC+=2; break;
      
      // EXA1 - Skip Next Instruction if: key Vx == 0
      case (byte) 0x00A1: if (keypad[V[x]] == 0) PC+=2; break;
      }
      break;
      
    case 0xF000:
      switch(kk) {
      default: opError(op); break;
      
      // FX07 - Assign: Vx = DT
      case 0x0007: V[x] = DTimer; break;
      
      // This is line 255! :D
      
      // FX0A - Key: Wait for key press, and store result in Vx
      case 0x000A:
        boolean pressed =  false;
        for(byte i = 0; i < keypad.length; i++) {
          if(keypad[i] == 1) {
            pressed = true;
            V[x] = i;
          }
        }
        if(!pressed) return;
        break;
      
      // FX15 - Assign: DT = Vx
      case 0x0015: DTimer = V[x]; break;
      
      // FX18 - Assign: ST = Vx
      case 0x0018: STimer = V[x]; break;
      
      // FX1E - Flow: I += Vx
      case 0x001E: index += V[x]; break;
      
      // FX29 - Flow: I = Address for sprite character for Vx
      case 0x0029: index = (short) (V[x] * 5); break;
      
      // FX33 - Assign: Stores binary-coded decimal of Vx in I, I+1, and I+2
      case 0x0033:
        mem[index] = (short) ((V[x]/100)%10);
        mem[index+1] = (short) ((V[x]/10)%10);
        mem[index+2] = (short) ((V[x]/1)%10);
        break;
        
      //  FX55 - Store: Store V0 to Vx in mem starting at I.
      case 0x0055:
        for(short i = 0; i <= x; i++) mem[index + i] = V[i];
        index = (short) (index + x);
        break;
        
      // FX65 - Assign: Store V0 to Vx from memory starting at I.
      case 0x0065:
        for(short i = 0; i <= x; i++) V[i] = (byte) mem[index + i];
        index = (short) (index + x);
        break;
      }
      break;
    }
    PC+=2;
  }

  void updateTimers() {
    if (DTimer > 0) DTimer--;
    if (STimer > 0) {
      STimer--;
      if (STimer == 0) beep();
    }
  }
  
  void opError(short op) { throwError(String.format("Unknown opcode \"0x%04x\" at address: 0x%04x\n", op, PC)); }
  
  void throwError(String err) {
    System.err.println(err);
    run = false;
    exit();
  }
  void beep() {
    osc.play();
    delay(BEEP_DELAY);
    osc.stop();
  }
  void pressed() {
    switch(key) {
    // Row 1
    case '1': keypad[1] = 1; break;
    case '2': keypad[2] = 1; break;
    case '3': keypad[3] = 1; break;
    case '4': keypad[0xC] = 1; break;
    
    // Row 2
    case 'q': keypad[4] = 1; break;
    case 'w': keypad[5] = 1; break;
    case 'e': keypad[6] = 1; break;
    case 'r': keypad[0xD] = 1; break;
    
    // Row 3
    case 'a': keypad[7] = 1; break;
    case 's': keypad[8] = 1; break;
    case 'd': keypad[9] = 1; break;
    case 'f': keypad[0xE] = 1; break;   
    
    // Row 4
    case 'z': keypad[0xA] = 1; break;
    case 'x': keypad[0] = 1; break;
    case 'c': keypad[0xB] = 1; break;
    case 'v': keypad[0xF] = 1; break;
    }
  }
  void released() { keypad = new byte[16]; }
  
  void renderPixels() {
    for(int y = 0; y < HEIGHT; y++) {
      for(int x = 0; x < WIDTH; x++) {
        fill((dmem[x][y] == 1) ? fground : bground);
        rect(x*SCALE, y*SCALE, SCALE, SCALE);
      }
    }
  }
  void clearPixels() { dmem = new byte[WIDTH][HEIGHT]; }
}
