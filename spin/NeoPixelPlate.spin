{{

This driver pushes data out to an 8x8 NeoPixel grid like the
Adafruit http://www.adafruit.com/products/1487.

The output from the last pixel of one plate can be connected
to the input of another plate. Thus this driver can handle
multiple plates.

The driver is designed to run at 80MHz. For instance:
  _clkmode        = xtal1 + pll16x
  _xinfreq        = 5_000_000

Parameters:
  The driver takes a pointer consecutive longs:
    long   p_command        ' Command trigger -- write non-zero value
    long   p_palette        ' Color palette (some commands) 
    long   p_buffer         ' Pointer to the pixel data buffer
    long   p_pin            ' The pin number to send data over
    long   p_pixPerRow      ' Number of pixels in a row on the plate
    long   p_numRows        ' Number of rows on the plate
    long   p_numPlates      ' Number of plates to update
    long   p_rowOffset      ' Memory offset between rows
    long   p_plateOffset[3] ' Up to four plates (change if you need more)

Memory Layout:
  The buffer used to update the display is a grid of pixel values. The buffer
  may be larger than the displays allowing the code to scroll around the
  larger image.

  A plate has a number of rows (p_numRows). There are 8 rows on the
  adafruit plate. A plate has a number of pixels per row (p_pixPerRow).
  Again, this is eight on the adafruit plate.

  Pixel data is read one after the other for the pixels on a row. When the
  driver comes to the end of a row it uses "p_rowOffset" to jump to the
  data in memory for the next row.

  There may be several plates driven by this driver. At the end of each
  plate the driver uses "p_plateOffset[]" to jump to the data memory
  for the next plate. 

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

Multiple Plate Layout:
  TODO discuss the init delta values

   ┌──┐
   │° │           ┌──┐(+1,0)┌──┐(+1,0)┌──┐(+1,0)┌──┐
   └─┬┘           │° ├─────│  ├─────│  ├─────│  │
      (0,+1)     └──┘      └──┘      └──┘      └──┘
   ┌──┐
   │  │
   └─┬┘           ┌──┐(+1,0)┌──┐      ┌──┐(+1,0)┌──┐
      (0,+1)     │° ├─────│  │      │° ├─────│  │
   ┌──┐           └──┘      └─┬┘      └──┘      └─┬┘
   │  │                 (0,+1)│         ┌─────────┘
   └─┬┘                                 (-1,+1)
      (0,+1)     ┌──┐      ┌──┐      ┌──┐      ┌──┐
   ┌──┐           │  │─────┤  │      │  ├─────│  │
   │  │           └──┘(-1,0)└──┘      └──┘(+1,0)└──┘
   └──┘
     
}}

var
    ' Param block for the driver COG
    '
    long   p_command        ' Command trigger -- write non-zero value
    long   p_palette        ' Color palette (some commands) 
    long   p_buffer         ' Pointer to the pixel data buffer
    long   p_pin            ' The pin number to send data over
    long   p_pixPerRow      ' Number of pixels in a row on the plate
    long   p_numRows        ' Number of rows on the plate
    long   p_numPlates      ' Number of plates to update
    long   p_rowOffset      ' Memory offset between rows
    long   p_plateOffset[3] ' Up to four plates (change if you need more)
    '
    ' For the memory-layout math assistance    
    '
    long   ix,iy
    '
    long   v1x,v1y  ' Plate-vector from plate 1 to 2 (or 0,0 if only one plate)
    long   v2x,v2y  ' Plate-vector from plate 2 to 3 (or 0,0 if only two plates) 
    long   v3x,v3y  ' Plate-vector from plate 3 to 4 (or 0,0 if only three plates)
    '
    ' Add more plate vectors (and p_plateOffsets) as needed     

pub init(_pn, _cols, _rows, _ix,_iy, _v1x,_v1y, _v2x,_v2y, _v3x,_v3y)
'' Start the NeoPixel driver cog
''  _pn : default pin number (driver can use multiple pins)

   p_pin := _pn
   p_pixPerRow := _cols
   p_numRows := _rows

   p_numPlates := 1

   ix := _ix
   iy := _iy

   ' The memory ptr ends up at (0,+_rows).
   ' Thus the offset in the deltaY calculation
   ' but not in the deltaX.

   if _v1x<>0 or _v1y<>0   
     v1x := _v1x * _cols
     v1y := (_v1y - 1) * _rows
     p_numPlates := 2

   if _v2x<>0 or _v2y<>0  
     v2x := _v2x * _cols
     v2y := (_v2y - 1) * _rows
     p_numPlates := 3

   if _v3x<>0 or _v3y<>0     
     v3x := _v3x * _cols
     v3y := (_v3y - 1) * _rows
     p_numPlates := 4
         
   p_command := 0
   return cognew(@NeoCOG,@p_command)

pub getAPIptr
'' Return self pointer -- pointer to register block
   return @p_command
   
DAT          
        org 0

NeoCOG   
        
top     rdlong  par_command,par wz       ' Has an update been triggered?
  if_z  jmp     #top                     ' No ... wait until

' Load all 10 params (command already loaded)
        mov     bitCnt,#par_palette      ' Start filling here (destination)
        mov     pixCnt,par               ' Load from here (source). Will pre-increment first in loop.        
        mov     c,#10                    ' 10 parameters to load
loadParams
        add     pixCnt,#4                ' Next address in shared memory         
        movd    incom,bitCnt             ' Indirect destination (table at the bottom)
        add     bitCnt,#1                ' Next pointer in memory 
incom   rdlong  0,pixCnt                 ' Read from shared memory into the params
        djnz    c,#loadParams            ' For all parameters

' Setup the I/O pin
        mov     pn,#1                    ' Pin number ...
        shl     pn,par_pin               ' ... to mask
        or      dira,pn                  ' Make sure we can write to it

' Initialize state machines
        mov     firstPix,#1              ' Start with first pixel in command 3
        mov     ptPtr,#par_plateOffset   ' First plate offset
        
nextPlate
        mov     rowCnt,par_numRows       ' Count of rows per plate

nextRow
        mov     pixCnt,par_pixPerRow     ' Each row ... this many pixels

nextPixel
        cmp     par_command,#2 wz        ' Move on if command ...
  if_nz jmp     #try3                    ' ... is not 2
        ' One byte palette lookup        
        rdbyte  c,par_buffer             ' Get the byte value
        add     par_buffer,#1            ' Next pixel value 
doLook  shl     c,#2                     ' * 4 bytes per entry
        add     c,par_palette            ' Offset into palette
        rdlong  val,c                    ' Get pixel value         
        jmp     #sendValue               ' Send the pixel

try3    cmp     par_command,#3 wz        ' Move on if command ...
  if_nz jmp     #do1                     ' ... is not 3
        ' Two pixels per byte palette lookup
        cmp     firstPix,#1 wz           ' Is this the first pixel?
  if_nz jmp     #secPix                  ' No ... go do the second
        mov     firstPix,#2              ' Next time use lower nibble  
        rdbyte  mulPixVal,par_buffer     ' Get the two-pixel value
        add     par_buffer,#1            ' Next two pixels
        mov     c,mulPixVal              ' Get upper ...
        shr     c,#4                     ' ... nibble        
        jmp     #doLook                  ' Lookup the palette color 
secPix
        mov     firstPix,#1              ' Next time load a byte        
        mov     c,mulPixVal              ' Get lower ...
        and     c,#$0F                   ' ... nibble        
        jmp     #doLook                  ' Lookup the palette color
  
do1     ' Full 24-byte pixel value
        rdlong  val,par_buffer           ' Get the next pixel value
        add     par_buffer,#4            ' Ready for next pixel in buffer         

sendValue        
        shl     val, #8                  ' Ignore top 8 bits (3 bytes only)
        mov     bitCnt,#24               ' 24 bits to move        

bitLoop
        shl     val, #1 wc               ' MSB goes first
  if_c  jmp     #doOne                   ' Go send one if it is a 1
        call    #sendZero                ' It is a zero ... send a 0
        jmp     #bottomLoop              ' Skip over sending a 1
        '
doOne   call    #sendOne

bottomLoop
        djnz    bitCnt,#bitLoop          ' Do all 24 bits in the pixel
        djnz    pixCnt,#nextPixel        ' Do all pixels on the row

        add     par_buffer,par_rowOffset ' Offset to next row in memory
        
        djnz    rowCnt,#nextRow          ' Do all rows

        movs    inplate,ptPtr            ' Source of offset
        add     ptPtr,#1                 ' Next offset for next plate
inplate add     par_buffer,0             ' Add the offset indirectly

        djnz    par_numPlates,#nextPlate ' Do all plates

        call    #sendDone                ' Latch in the LEDs  

done    mov     par_command,#0           ' Clear ...
        wrlong  par_command,par          ' ... the trigger
        jmp     #top                     ' Go back and wait               

' These timing values were tweaked with an oscope
'        
sendZero                 
        or      outa,pn                  ' Take the data line high
        mov     c,#$5                    ' wait 0.4us (400ns)
loop3   djnz    c,#loop3                 '
        andn    outa,pn                  ' Take the data line low
        mov     c,#$B                    ' wait 0.85us (850ns) 
loop4   djnz    c,#loop4                 '                              
sendZero_ret                             '
        ret                              ' Done
'
sendOne
        or      outa,pn                  ' Take the data line high
        mov     c,#$D                    ' wait 0.8us 
loop1   djnz    c,#loop1                 '                       
        andn    outa,pn                  ' Take the data line low
        mov     c,#$3                    ' wait 0.45us  36 ticks, 9 instructions
loop2   djnz    c,#loop2                 '
sendOne_ret                              '
        ret                              ' Done
'
sendDone
        andn    outa,pn                  ' Take the data line low
        mov     c,C_RES                  ' wait 60us
loop5   djnz    c,#loop5                 '
sendDone_ret                             '
        ret                              ' Done


' Fetched params
par_command      long 0          ' Command trigger -- write non-zero value
'
par_palette      long 0          ' Color palette (some commands) 
par_buffer       long 0          ' Pointer to the pixel data buffer
par_pin          long 0          ' The pin number to send data over
par_pixPerRow    long 0          ' Number of pixels in a row on the plate
par_numRows      long 0          ' Number of rows on the plate
par_numPlates    long 0          ' Number of plates to update
par_rowOffset    long 0          ' Memory offset between rows
par_plateOffset  long 0,0,0      ' Up to four plates (change if you need more)

' Misc
ptPtr            long 0          ' Plate-offset pointer
pn               long 0          ' Pin number bit mask
c                long 0          ' Counter used in delay
val              long 0          ' Shifting pixel value       
bitCnt           long 0          ' Counter for bit shifting
pixCnt           long 0          ' Counter for pixels on a row
rowCnt           long 0          ' Counter for rows on a plate
firstPix         long 0          ' 1 if first pixel, 2 if second
mulPixVal        long 0          ' Value kept for second pixel
'
C_RES            long $4B0       ' Wait count for latching the LEDs

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