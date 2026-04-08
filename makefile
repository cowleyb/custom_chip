######################################################################
#
# DESCRIPTION: Make Verilator model and run coverage
#
# This calls the object directory makefile.  That allows the objects to
# be placed in the "current directory" which simplifies the Makefile.
#
# This file is placed under the Creative Commons Public Domain, for
# any use, without warranty, 2020 by Wilson Snyder.
# SPDX-License-Identifier: CC0-1.0
#
######################################################################

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

# This example started with the Verilator example files.
# Please see those examples for commented sources, here:
# https://github.com/verilator/verilator/tree/master/examples

######################################################################
# Set up variables

GENHTML = genhtml
TOP_MODULE ?= top
SIM_MAIN ?= sw/sdl/spi_monitor_main.cpp
RTL_SOURCES ?= $(shell find rtl -type f \( -name '*.sv' -o -name '*.v' \) | sort)
SIM_BINARY := obj_dir/V$(TOP_MODULE)
TEST_BENCH ?=
TEST_RTL ?= $(RTL_SOURCES)
TEST_BIN := build/$(basename $(notdir $(TEST_BENCH)))

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

VERILATOR_FLAGS =
# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
#VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += --x-assign 0
# Warn abount lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wall
# Make waveforms
#VERILATOR_FLAGS += --trace
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert
# Generate coverage analysis
VERILATOR_FLAGS += --coverage
# Run make to compile model, with as many CPUs as are free
VERILATOR_FLAGS += --build -j
# Run Verilator in debug mode
#VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt

SDL_CFLAGS := $(shell pkg-config --cflags sdl3)
SDL_LIBS   := $(shell pkg-config --libs sdl3)
ifneq ($(strip $(SDL_CFLAGS)),)
VERILATOR_FLAGS += -CFLAGS "$(SDL_CFLAGS)"
endif
ifneq ($(strip $(SDL_LIBS)),)
VERILATOR_FLAGS += -LDFLAGS "$(SDL_LIBS)"
endif

# Input files for Verilator
VERILATOR_INPUT = -f input.vc --top-module $(TOP_MODULE) $(RTL_SOURCES) $(SIM_MAIN)

######################################################################

# Create annotated source
VERILATOR_COV_FLAGS += --annotate logs/annotated
# A single coverage hit is considered good enough
VERILATOR_COV_FLAGS += --annotate-min 1
# Create LCOV info
VERILATOR_COV_FLAGS += --write-info logs/coverage.info
# Input file from Verilator
VERILATOR_COV_FLAGS += logs/coverage.dat

######################################################################
default: sim

.PHONY: default sim run sim-build sim-run coverage test list-tests unit system \
        run-test show-config genhtml clean mostlyclean distclean maintainer-clean

sim: sim-build sim-run coverage

run: sim

sim-build:
	@echo
	@echo "-- VERILATE ----------------"

	$(VERILATOR) --version
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)

sim-run:
	@echo
	@echo "-- RUN ---------------------"
	@rm -rf logs
	@mkdir -p logs
	$(SIM_BINARY)

coverage:
	@echo
	@echo "-- COVERAGE ----------------"
	@rm -rf logs/annotated
	$(VERILATOR_COVERAGE) $(VERILATOR_COV_FLAGS)

	@echo
	@echo "-- DONE --------------------"

test:
	@echo "Hardware test entry points:"
	@echo "  make unit TEST_BENCH=dv/unit/<name>_tb.sv"
	@echo "  make system TEST_BENCH=dv/system/<name>_tb.sv"
	@echo "Optional overrides:"
	@echo "  TEST_RTL='rtl/path/foo.sv rtl/path/bar.sv'"
	@echo
	@$(MAKE) --no-print-directory list-tests

list-tests:
	@echo
	@echo "-- AVAILABLE TESTBENCHES ---"
	@if find dv/unit dv/system -maxdepth 2 -type f -name '*_tb.sv' | sort | grep -q .; then \
		find dv/unit dv/system -maxdepth 2 -type f -name '*_tb.sv' | sort; \
	else \
		echo "No *_tb.sv files found under dv/unit or dv/system."; \
	fi

unit: run-test

system: run-test

run-test:
	@if [ -z "$(TEST_BENCH)" ]; then \
		echo "Usage: make unit TEST_BENCH=dv/unit/<name>_tb.sv [TEST_RTL='rtl/...']"; \
		echo "   or: make system TEST_BENCH=dv/system/<name>_tb.sv [TEST_RTL='rtl/...']"; \
		exit 1; \
	fi
	@echo
	@echo "-- TEST --------------------"
	@mkdir -p build
	iverilog -g2012 -o $(TEST_BIN) $(TEST_BENCH) $(TEST_RTL)
	vvp $(TEST_BIN)


######################################################################
# Other targets

show-config:
	$(VERILATOR) -V

genhtml:
	@echo "-- GENHTML --------------------"
	@echo "-- Note not installed by default, so not in default rule"
	$(GENHTML) logs/coverage.info --output-directory logs/html

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf build obj_dir logs *.log *.dmp *.vpd core
