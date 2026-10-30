MP3 PWM-based Game of Life variant
==================================

This version does not use PNG previews or red.txt/green.txt/blue.txt palette
files. Instead, color_fade.sv reuses the six-stage brightness ramp approach
from Project_2.sv:

  Red -> Yellow -> Green -> Cyan -> Blue -> Magenta -> Red

The ramp is updated every 10,000 clock cycles. Each stage has 200 brightness
updates and six stages take 12,000,000 cycles, or 1 second at 12 MHz.

Important WS2812B distinction:
- Project_2's pwm.sv creates binary PWM waveforms to drive ordinary LED pins.
- A WS2812B matrix expects a timed SERIAL data stream with 8-bit color values
  per channel (GRB order). Each WS2812B pixel does its own PWM internally.
- Accordingly, color_fade.sv reuses the old brightness-fading logic, and
  top.sv scales those brightness values to 8-bit channel bytes. The ws2812
  driver serializes each pixel's 24-bit data.
- All living Game of Life cells have the same current hue; dead cells are black.
  This is the assignment's suggested color-cycling living-cell variant. It is
  not a spatially varying spiral like the optional Python palette example.

Files:
  top.sv              Top-level design, includes the submodules.
  life_core.sv        Game of Life rules and wraparound boundaries.
  color_fade.sv       Six-stage RGB brightness controller.
  ws2812_driver.sv    WS2812B serial protocol driver.
  seed.memh           Initial grid used on the FPGA.
  blinker.memh        Testbench seed for ordinary blinker.
  wrap_blinker.memh   Testbench seed for wraparound blinker.
  life_tb.sv          Icarus testbench for the Game of Life core.

Build uses the provided Makefile, without changing it. The top-level output
is named _31b to match the existing ../common/iceBlinkPico.pcf signal on
package pin 18. Verify the matrix DIN wire is physically connected to that
header signal. If not, use the existing PCF name for the pin you actually use.

Run the Life testbench from this directory:
  iverilog -g2012 -s life_tb -o life_tb life_tb.sv
  vvp life_tb
  gtkwave life.vcd

The FPGA build must also find seed.memh in the working directory when running
Yosys/nextpnr from the existing course Makefile.

Optional fast simulation of the color fade controller:
  iverilog -g2012 -s color_fade_tb -o color_fade_tb color_fade_tb.sv
  vvp color_fade_tb
  gtkwave color_fade.vcd

Timing note (after the nextpnr timing report):
  top.sv converts the fade brightness from 0..1200 to 0..255 with a fixed-point
  multiply-and-shift, not a general division. The 8-bit colors are latched at
  frame boundaries before they are sent to ws2812_driver.sv. This removes the
  divider from the path into the serializer shift register, which the supplied
  timing report identified as the limiting path. Re-run make build and check
  the new achieved clock frequency; this environment did not run nextpnr.
