CON
  _clkmode        = xtal1 + pll16x
  _xinfreq        = 5_000_000

{{

I used the following 8x8 NeoPixel grid from AdaFruit:
https://www.adafruit.com/products/1487

Propeller Demo Board                                                 

             7404         330Ω
     P0  ──────────────── NeoPixel DIN
  +5 In  ──────────┐
    GND  ───────┐  │
                 │  │
                 │  │
2A Wall Wart     │  │
                 │  │
     +5  ────────┼──┻─────────┳─ NeoPixel +5
                 │     1000µF  
    GND  ────────┻────────────┻─ NeoPixel GND   

In my case the NeoPixels are powered by 5V. They require the
Data in (DIN) signal to be close to 5V. The propeller GPIO
output is only 3.3V. I used a 7404 Hex Inverter chip to boost
the output up to 5V. I used two of the inverters on the the
chip back to back to re-invert the signal to match the propeller
output value. If you only want to use one of the inverters then
you can invert the propeller output in the code.

}}

OBJ    
    SEQ    : "PixelSequencer" 
    
PUB Main : i     
                
  PauseMSec(1000)

  SEQ.playSequence(@basics)   

  repeat 

PRI PauseMSec(Duration)
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)


DAT

basics
  byte $04,$00,$00,$0a,$00,$00,$00,$00,$00,$00,$0f,$00,$00,$0f,$00,$00
  byte $0f,$00,$00,$00,$02,$00,$00,$0d,$00,$00,$00,$02,$01,$02,$03,$01
  byte $02,$03,$01,$02,$03,$01,$02,$03,$01,$02,$03,$01,$01,$02,$03,$01
  byte $02,$03,$01,$02,$03,$01,$02,$03,$01,$02,$03,$01,$01,$02,$03,$01
  byte $02,$03,$01,$02,$03,$01,$02,$03,$01,$02,$03,$01,$01,$02,$03,$01
  byte $02,$03,$01,$02,$03,$01,$02,$03,$01,$02,$03,$01,$f4,$01,$00,$0b
  byte $00,$00,$00,$02,$03,$01,$02,$03,$01,$02,$03,$01,$01,$02,$03,$01
  byte $02,$03,$01,$02,$03,$01,$02,$03,$01,$02,$03,$01,$01,$02,$03,$01
  byte $02,$03,$01,$02,$03,$01,$02,$03,$01,$02,$03,$01,$01,$02,$03,$01
  byte $02,$03,$01,$02,$03,$01,$02,$03,$01,$02,$03,$01,$01,$02,$03,$01
  byte $02,$03,$01,$02,$f4,$01,$00,$0b,$00,$00,$00,$0e,$04,$00,$00,$0d
  byte $00,$00,$00,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$00,$00
  byte $00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00
  byte $00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00
  byte $00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$03
  byte $03,$03,$03,$03,$fa,$00,$00,$0b,$00,$00,$00,$02,$00,$00,$00,$00
  byte $00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$00,$00,$03,$00,$00
  byte $00,$00,$03,$00,$00,$03,$00,$00,$00,$00,$03,$00,$00,$03,$00,$00
  byte $00,$00,$03,$00,$00,$03,$00,$00,$00,$00,$03,$00,$00,$03,$03,$03
  byte $03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fa,$00,$00,$0b
  byte $00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  byte $00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$00,$03,$00
  byte $00,$03,$00,$00,$00,$00,$03,$00,$00,$03,$00,$00,$00,$00,$03,$03
  byte $03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  byte $00,$00,$00,$00,$fa,$00,$00,$0b,$00,$00,$00,$02,$00,$00,$00,$00
  byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  byte $00,$00,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$00,$03
  byte $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fa,$00,$00,$0b
  byte $00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  byte $00,$00,$00,$00,$00,$00,$03,$03,$03,$03,$00,$00,$00,$00,$03,$00
  byte $00,$03,$00,$00,$00,$00,$03,$00,$00,$03,$00,$00,$00,$00,$03,$03
  byte $03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  byte $00,$00,$00,$00,$fa,$00,$00,$0b,$00,$00,$00,$02,$00,$00,$00,$00
  byte $00,$00,$00,$00,$00,$03,$03,$03,$03,$03,$03,$00,$00,$03,$00,$00
  byte $00,$00,$03,$00,$00,$03,$00,$00,$00,$00,$03,$00,$00,$03,$00,$00
  byte $00,$00,$03,$00,$00,$03,$00,$00,$00,$00,$03,$00,$00,$03,$03,$03
  byte $03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fa,$00,$00,$0b
  byte $00,$00,$00,$0e,$00,$00,$00,$02,$03,$03,$03,$03,$03,$03,$03,$03
  byte $03,$00,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$00,$03
  byte $03,$00,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$00,$03
  byte $03,$00,$00,$00,$00,$00,$00,$03,$03,$00,$00,$00,$00,$00,$00,$03
  byte $03,$03,$03,$03,$03,$03,$03,$03,$fa,$00,$00,$0b,$00,$00,$00,$0c
  byte $ff,$ff,$ff,$ff


CON
{{   
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                TERMS OF USE: MIT License                                │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this     │
│software and associated documentation files (the "Software"), to deal in the Software    │
│without restriction, including without limitation the rights to use, copy, modify, merge,│
│publish, distribute, sublicense, and/or sell copies of the Software, and to permit       │
│persons to whom the Software is furnished to do so, subject to the following conditions: │
│                                                                                         │
│The above copyright notice and this permission notice shall be included in all copies or │
│substantial portions of the Software.                                                    │
│                                                                                         │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESSED OR IMPLIED,    │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR │
│PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE│
│FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR     │
│OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER   │
│DEALINGS IN THE SOFTWARE.                                                                │
└─────────────────────────────────────────────────────────────────────────────────────────┘
}}           