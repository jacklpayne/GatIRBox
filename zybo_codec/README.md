# zybo_codec

Zybo Z7-10 bring-up for the on-board SSM2603 codec

FPGA configures the codec over I2C, then plays a 375 Hz square wave
(-12 dBFS, 48 kHz) out the headphone jack while SW0 is on.

## Build

Set JP5 to JTAG, then from this folder:

```
vivado -mode batch -source build.tcl
```

Program `build/zybo_codec_top.bit` from Hardware Manager. Turn the headphone volume down (so loud) and flip SW0 up.
