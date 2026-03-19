SDL_CFLAGS = `pkg-config --cflags sdl3`
SDL_LDFLAGS = `pkg-config --libs sdl3`
CC = gcc

SDL_TARGET = build/clear
SDL_SRC = clear.c

SIM_BUILD_DIR ?= build/sim
SIM_TOP ?= test
SIM_RTL ?= rtl/display/test.sv
SIM_TB ?= dv/unit/test_tb.sv
SIM_NAME ?= $(SIM_TOP)
SIM_TARGET ?= $(SIM_BUILD_DIR)/$(SIM_NAME)

.PHONY: all clear sim run-sim sim-print clean

all: clear

clear: $(SDL_TARGET)

$(SDL_TARGET): $(SDL_SRC)
	$(CC) $(SDL_CFLAGS) -o $(SDL_TARGET) $(SDL_SRC) $(SDL_LDFLAGS)

sim: $(SIM_TARGET)

$(SIM_TARGET): $(SIM_RTL) $(SIM_TB)
	mkdir -p $(SIM_BUILD_DIR)
	source /opt/oss-cad-suite/environment && iverilog -g2012 -s $(SIM_TOP) -o $(SIM_TARGET) $(SIM_RTL) $(SIM_TB)

run-sim: $(SIM_TARGET)
	source /opt/oss-cad-suite/environment && vvp $(SIM_TARGET)

sim-print:
	@echo "SIM_TOP=$(SIM_TOP)"
	@echo "SIM_RTL=$(SIM_RTL)"
	@echo "SIM_TB=$(SIM_TB)"
	@echo "SIM_TARGET=$(SIM_TARGET)"

clean:
	rm -f $(SDL_TARGET) $(SIM_TARGET)