# Repository Structure

## Top-Level Folders

### `rtl/`

Register-transfer level source.

This is the synthesizable hardware.
Put the actual chip logic here:

- pixel generators
- execution units
- memory controllers
- display drivers
- top-level SoC wiring

Rule of thumb: if it is meant to become FPGA hardware, it belongs in `rtl/`.

### `dv/`

Design verification.

This is the test side of the hardware project.
Put non-synthesizable verification code here:

- testbenches
- assertions
- scoreboards
- regression tests
- waveform helpers

Rule of thumb: if it exists to test hardware rather than become hardware, it belongs in `dv/`.

### `docs/`

Project documentation.

Use this for architecture notes, bring-up notes, diagrams, interface contracts, and milestone reports.

### `scripts/`

Automation helpers.
Use this for:

- build scripts
- simulation scripts
- synthesis scripts
- test runners
- utility shell scripts

### `build/`

Generated outputs.
This is for things created by tools, not hand-written source code:

- compiled binaries
- simulator outputs
- generated logs
- waveform dumps
- Verilator build output

### `logs/`, `obj_dir/`, `output`

Additional generated output locations used during experiments and tool runs.

These directories are not hand-authored source and should not be treated as design inputs.

