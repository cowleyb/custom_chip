
# TODO

| 26/03/26
- [ x ] complete makefile for command
- [  ] renamde cpp varialbes so they dont lok like typescrip
- [ x ] understand top->eval and latest change
- [ x ] raster frontend generate x, y, valid, framestart, framedone for full 240x240 scan
- [ ] mem fetch read the 80x80 cellstate BRAM, not a counter, add 3x address expansion so each cell covers a 3x3 block
- [ ] shade stage map cell state to rgb with palette/lut first
- [ ] commando add start/busy/done, source base, mode, palette select
- [ ] prove 1 lane first verify one scalar pixel pipeline e2e before SIMD
- [ ] wiedn to SIMD replicate lane 4 or 8 wide? use shared y, lane local x+i, contiguous reads, and tail masks
- [ ] scanout -feed either a line buffer or pixel stream into spi scanout with clean handshake
- [ ] come up with standard word size etc 
- [ ] test accuratly with interface and proper cycle delays instead of putting #1

# Spec

Logic units(LUT4)	8640
Registers(FF)	6480
ShadowSRAM SSRAM(bits)	17280
Block SRAM BSRAM(bits)	468K
Number of B-SRAM	26
User flash(bits)	608K
PSRAM(bits)	64M
18 x 18 Multiplier	20
SPI FLASH	32M-bit
Number of PLL	2
Display interface	HDMI interface, SPI screen interface and RGB screen interface
Debugger	Onboard BL702 chip provides USB-JTAG and USB-UART functions for GW1NR-9
IO	• support 4mA、8mA、16mA、24mA other driving capabilities
• Provides independent Bus Keeper, pull-up/pull-down resistors, and Open Drain output options for each I/O
Connector	TF card slot, 2x24P 2.54mm Header pads
Button	2 programmable buttons for users
LED	Onboard 6 programmable LEDs

# Stuff

renderer triggers mem fetch from BRAM which then sends the data to the fixed shader for now.
perhaps a line buffer could be added towards the end
then create a SPI scanout

Dont forget to not blow the fpga space

## Image 

RGB is typically 24 bits, 8 bit red, 8 bit green and 8 bit blue 
Because BRAM unit is limited memory 18k per unit I store the image data in RGB 565 
RGB 565 - 5 bits red, 6 bits green, 5 bits blue. A total of 16 bits. 
Total size of image is 80x80*16= 102.4k
Approximatly 6-8 block wills be used to store this image.
I can maybe move to using the PSRAM in the future which is 64M bits instead. Good for the full size image/frame/line buffers


## Convention

Convention for FGPAs seems to be to use synchronous resets, instead of asynchronous

Synchronous reset - reset only takes effect on clock edge
```
always_ff @(posedge clk) begin
    if (rst) q <= 0;
    else     q <= d;
end
```

Asynchronous reset - reset takes effect immediatly regardless of clock
```
always_ff @(posedge clk or posedge rst) begin
    if (rst) q <= 0;
    else     q <= d;
end
```

Convention seems to be use active low resets
rst - active high 
rst_n - active low
