# GatIRBox

**Status: Pre-alpha — still developing and linking submodules.**

GatIRBox is an open-source, FPGA-based guitar amplifier modeler and impulse-response (IR) loader. Its goal is to let musicians load multiple IRs from an SD card and apply them to a live guitar signal using low-latency FPGA convolution.

## Completed Work

- **FPGA DSP:** Parameterized convolution RTL (`conv.sv`), a draft three-stage cascade (`conv_cascade.sv`), and a Basys3 test wrapper.
- **OLED and controls:** SSD1309 SPI driver and a demo that reads one potentiometer and displays its value as a percentage.
- **SD-card reading:** Experimental FatFs code for mounting a card, listing files, reading a `.wav` file, and sending data over UART.
- **MCU–FPGA bring-up:** Pico 2 GPIO output and Zybo Z7-10 FPGA input/LED logic, with a SystemVerilog testbench and board constraints.
- **Design documentation:** An FPGA architecture draft and subsystem task lists.

These components are currently independent. The three-stage convolution path, IR loading into FPGA memory, and complete audio signal chain aren't done yet.

## Project Architecture

The intended system separates **control and file management** (RP2350 MCU) from **audio processing** (FPGA):

```text
SD card (.wav) ──> RP2350 MCU ──> FPGA IR memory / controls
                       ^                    |
             Pots / buttons / encoder       v
                       |              FPGA convolution
                       └──> SPI OLED

Guitar in ──> CS4270 ADC ──> FPGA DSP ──> CS4270 DAC ──> Guitar out
```

- **MCU:** Reads IR files, manages user input and display, and will transfer IR data and mix settings to the FPGA.
- **FPGA:** Will perform real-time convolution with up to three cascaded IRs and per-stage wet/dry mixing.
- **Audio codec:** The planned CS4270 converts between analog guitar audio and digital samples.

The intended final hardware uses an RP2350, Lattice iCE40 HX8K FPGA, 128×64 OLED, three potentiometers, three buttons, and one rotary encoder. The design targets 24-bit/96 kHz audio. See the [FPGA architecture draft](docs/FPGA%20architecture%20draft.png).

## Repository Structure

```text
src/FPGA/       Convolution RTL, cascade draft, and test wrapper
src/MCU/OLED/   SSD1309 driver and potentiometer display demo
src/MCU/SD_READER/  SD-card/FatFs experiments
zybo-bringup/   Pico-to-Zybo GPIO communication experiment
 docs/          Architecture diagram
```

## Next Steps

Integrate SD-card reading and OLED controls; implement MCU-to-FPGA IR transfers; complete and verify the convolution cascade; connect the audio codec; and test the full signal path before developing the final PCB.

## Known Bugs / Issues

TODO!! (does the fact that submodules are independant count as bug?)

## Team

Evan Gehler · Ethan Mitchell · Alex Ospina · Jack Payne
