// top.sv - Pico GPIO -> Zybo Z7 LEDs
//
// The Pico drives four GPIO lines into Pmod JE1..JE4. The FPGA shows them on
// LD0..LD3, inverted when SW0 is up.

module top (
    input  logic       sysclk,    // 125 MHz
    input  logic       sw0,       // up = invert
    input  logic [3:0] pico_in,   // JE1..JE4
    output logic [3:0] led        // LD0..LD3
);
    // The Pico pins change with no relation to clock
    // pass through two flip-flops before used (metastability guard).
    (* ASYNC_REG = "TRUE" *) logic [3:0] in_meta, in_sync;
    (* ASYNC_REG = "TRUE" *) logic       sw_meta, sw_sync;

    always_ff @(posedge sysclk) begin
        in_meta <= pico_in;  in_sync <= in_meta;
        sw_meta <= sw0;      sw_sync <= sw_meta;
        led     <= sw_sync ? ~in_sync : in_sync;
    end
endmodule
