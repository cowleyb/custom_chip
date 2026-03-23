
# TODO

| 24/03/26
- [ x ] complete makefile for command
- [  ] renamde cpp varialbes so they dont lok like typescrip
- [ x ] understand top->eval and latest change
- [ ] raster frontend generate x, y, valid, framestart, framedone for full 240x240 scan
- [ ] mem fetch read the 80x80 cellstate BRAM, not a counter, add 3x address expansion so each cell covers a 3x3 block
- [ ] shade stage map cell state to rgb with palette/lut first
- [ ] commando add start/busy/done, source base, mode, palette select
- [ ] prove 1 lane first verify one scalar pixel pipeline e2e before SIMD
- [ ] wiedn to SIMD replicate lane 4 or 8 wide? use shared y, lane local x+i, contiguous reads, and tail masks
- [ ] scanout -feed either a line buffer or pixel stream into spi scanout with clean handshake

# Stuff

Dont forget to not blow the fpga space



