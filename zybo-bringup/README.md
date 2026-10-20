# zybo-bringup

Pico 2 drives four GPIO lines into the Zybo Z7-10; the FPGA shows them on the LEDs.
SW0 inverts them.

## Wiring

| Pico 2        | Zybo Pmod JE | LED |
|---------------|--------------|-----|
| pin 22 (GP17) | JE1          | LD0 |
| pin 25 (GP19) | JE2          | LD1 |
| pin 21 (GP16) | JE3          | LD2 |
| pin 24 (GP18) | JE4          | LD3 |
| pin 23 (GND)  | JE5 (GND)    |     |

Don't connect 3V3 between boards

## Pico

1. Open `pico/` in VS Code with the Raspberry Pi Pico extension.
2. Compile, then hold BOOTSEL, plug in, and copy `build/zybo_hello.uf2` to the drive.
3. Open the serial monitor. Type `0`–`f` to set the outputs, or `n` to toggle auto-increment.

## Zybo

1. Set jumper JP5 to JTAG.
2. In the Vivado Tcl console:
   Navigate to current folder: `cd ./zybo-bringup/zybo` then run: `source create_project.tcl`
3. Generate Bitstream → Hardware Manager → Auto Connect → Program Device.
4. Program doesn't stay with Power Cycle