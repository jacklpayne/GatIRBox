- Implement saturation, rounding logic in convolution engine
- Unroll the MAC loop as allowed by HW resources

- Implement dry/wet in the cascade module

- Create basys3 wrapper for the cascade that loads SW levels into BRAM for the IR and displays sample values on 7seg

- Determine AXI (?) architecture/IP for externally loading IRs into BRAM

- Initializing/configuring the codec?