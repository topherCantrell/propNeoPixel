{{

The driver is designed to run at 80MHz. For instance:
  _clkmode        = xtal1 + pll16x
  _xinfreq        = 5_000_000

Parameters:
  The driver takes a pointer to four consecutive longs:
    long   command    ' Command trigger -- write non-zero value
    long   buffer     ' Pointer to the pixel data buffer
    long   pixPerRow  ' Number of pixels in a row
    long   numRows    ' Number of rows
    long   rowOffset  ' Memory offset between rows
    long   palette    ' Color palette (some commands)
    long   pin        ' The pin number to send data over

Commands:
  1 - The buffer is a list of RGB words
  2 - The buffer is a list of one-byte palette references
  3 - The buffer is a list of one-byte (2 pixels per byte) palette
      references. The MSB is the 1st pixel. The LSB is the 2nd pixel.  

Palette:
  The color palette is a list of (potentially) 256 longs. Each entry
  is an RGB word. With command 2 the driver reads a single byte per
  pixel. The byte is an offset into the palette table that holds
  the RGB long. The palette can be as short as you like. Just be sure
  to cover all the values you are going to use in the pixel data.

  With command 3 the driver reads two pixel values from a single byte.
  Each nibble is an offset into the palette (0..15). This allows the
  display to be completely drawn with only 32 bytes of pixel data.     

RGB Longs:
  $00_GG_RR_BB
  Where "GG", "RR", and "BB" are the intensities for green, red, and blue.
  The upper byte is ignored (four bytes makes the math easier)
  
Row Offset:
  TODO

Multiple Strips: 
  You can use the same driver COG to update multiple NeoPixel strips
  by changing the "pin" between update requests. Or you can spin up
  separate driver COGs for each strip. Each COG would have its own
  set of four parameter longs.

}}

var
   long params

pub start(paramBlock)
'' Start the NeoPixel driver cog
   params := paramBlock
   return cognew(@NeoCOG,paramBlock)
   
DAT          
        org 0

NeoCOG   
        mov     comPtr,par        ' This is the "trigger" address
        '
        mov     bufPtr,par        ' This is the ...
        add     bufPtr,#4         ' ... buffer address
        '
        mov     perRowPtr,par     ' This is the ...
        add     perRowPtr,#8      ' ... pixels per row
        '
        mov     numRowPtr,par     ' This is the ...
        add     numRowPtr,#12     ' ... number of rows
        '
        mov     rowOffPtr,par     ' This is the ...
        add     rowOffPtr,#16     ' ... memory offset between rows
        '
        mov     palPtr,par        ' This is the ...
        add     palPtr,#20        ' ... palette address
        '        
        mov     pinPtr,par        ' This is the ...
        add     pinPtr,#24        ' ... data pin number                 

top     rdlong  com,comPtr wz     ' Has an update been triggered?
  if_z  jmp     #top              ' No ... wait until

        rdlong  c,pinPtr          ' Which pin for this update
        mov     pn,#1             ' Pin number ...
        shl     pn,c              ' ... to mask
        or      dira,pn           ' Make sure we can write to it

        rdlong  pPtr,bufPtr       ' Where the pixels come from

        rdlong  pal,palPtr        ' Color palette
        rdlong  perRow,perRowPtr  ' Pixels per row
        rdlong  numRows,numRowPtr ' Number of rows        
        rdlong  rowOff,rowOffPtr  ' Memory offset between rows

        mov     firstPix,#1       ' Start with first pixel in command 3

nextRow
        mov     pixCnt, perRow    ' Each row ... this many pixels

nextPixel
        cmp     com,#2 wz         ' Move on if command ...
  if_nz jmp     #try3             ' ... is not 2
        ' One byte palette lookup        
        rdbyte  c,pPtr            ' Get the byte value
        add     pPtr,#1           ' Next pixel value 
doLook  shl     c,#2              ' * 4 bytes per entry
        add     c,pal             ' Offset into palette
        rdlong  val,c             ' Get pixel value         
        jmp     #sendValue        ' Send the pixel

try3    cmp     com,#3 wz         ' Move on if command ...
  if_nz jmp     #do1              ' ... is not 3
        ' Two pixels per byte palette lookup
        cmp     firstPix,#1 wz    ' Is this the first pixel?
  if_nz jmp     #secPix           ' No ... go do the second
        mov     firstPix,#2       ' Next time use lower nibble  
        rdbyte  mulPixVal,pPtr    ' Get the two-pixel value
        add     pPtr,#1           ' Next two pixels
        mov     c,mulPixVal       ' Get upper ...
        shr     c,#4              ' ... nibble        
        jmp     #doLook           ' Lookup the palette color 
secPix
        mov     firstPix,#1       ' Next time load a byte        
        mov     c,mulPixVal       ' Get lower ...
        and     c,#$0F            ' ... nibble        
        jmp     #doLook           ' Lookup the palette color
  
do1     ' Full 24-byte pixel value
        rdlong  val,pPtr          ' Get the next pixel value
        add     pPtr,#4           ' Ready for next pixel in buffer         

sendValue        
        shl     val, #8           ' Ignore top 8 bits (3 bytes only)
        mov     bitCnt,#24        ' 24 bits to move        

bitLoop
        shl     val, #1 wc        ' MSB goes first
  if_c  jmp     #doOne            ' Go send one if it is a 1
        call    #sendZero         ' It is a zero ... send a 0
        jmp     #bottomLoop       ' Skip over sending a 1
        '
doOne   call    #sendOne

bottomLoop
        djnz    bitCnt,#bitLoop   ' Do all 24 bits in the pixel
        djnz    pixCnt,#nextPixel ' Do all pixels on the row

        add     pPtr,rowOff       ' Offset to next row in memory
        
        djnz    numRows,#nextRow  ' Do all rows

        call    #sendDone         ' Latch in the LEDs  

        jmp     #done             ' Clear the trigger               
        
sendZero                 
        or      outa,pn           ' Take the data line high
        mov     c,#$5             ' wait 0.4us (400ns)
loop3   djnz    c,#loop3          '
        andn    outa,pn           ' Take the data line low
        mov     c,#$B             ' wait 0.85us (850ns) 
loop4   djnz    c,#loop4          '                              
sendZero_ret                      '
        ret                       ' Done

sendOne
        or      outa,pn           ' Take the data line high
        mov     c,#$D             ' wait 0.8us 
loop1   djnz    c,#loop1          '                       
        andn    outa,pn           ' Take the data line low
        mov     c,#$3             ' wait 0.45us  36 ticks, 9 instructions
loop2   djnz    c,#loop2          '
sendOne_ret                       '
        ret                       ' Done

sendDone
        andn    outa,pn           ' Take the data line low
        mov     c,C_RES           ' wait 60us
loop5   djnz    c,#loop5          '
sendDone_ret                      '
        ret                       '

done    mov     com,#0            ' Clear ...
        wrlong  com,comPtr        ' ... the trigger
        jmp     #top              ' Go back and wait

C_RES          long $4B0          ' Wait count for latching the LEDs

comPtr         long 0             ' Parameter pointers
bufPtr         long 0             '
perRowPtr      long 0             '
numRowPtr      long 0             '
rowOffPtr      long 0             '
palPtr         long 0             '
pinPtr         long 0             '

com            long 0             ' Requested command
pPtr           long 0             ' Moving pointer to pixel data  
pn             long 0             ' Pin number bit mask
c              long 0             ' Counter used in delay
val            long 0             ' Shifting pixel value
pal            long 0             ' Address of palette 

perRow         long 0             ' Pixels per row count
numRows        long 0             ' Number of rows count
rowOff         long 0             ' Memory offset between rows

bitCnt         long 0             ' Counter for bit shifting
pixCnt         long 0             ' Counter for pixels on a row

firstPix       long 0             ' 1 if first pixel, 2 if second
mulPixVal      long 0             ' Value kept for second pixel

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