// tb_top.sv - self-checking testbench
// Vivado: Run Simulation -> Run Behavioral Simulation (results print in the Tcl console)
`timescale 1ns/1ps

module tb_top;
    logic       sysclk = 0;
    logic       sw0 = 0;
    logic [3:0] pico_in = '0;
    logic [3:0] led;

    top dut (.sysclk(sysclk), .sw0(sw0), .pico_in(pico_in), .led(led));

    always #4 sysclk = ~sysclk;   // 125 MHz

    int errors = 0;

    initial begin
        for (int inv = 0; inv < 2; inv++) begin
            sw0 = inv;
            for (int v = 0; v < 16; v++) begin
                pico_in = v[3:0];
                #50;   // a few clocks for the synchronizer
                if (led !== (inv ? ~v[3:0] : v[3:0])) begin
                    $display("FAIL: sw0=%0d in=%b led=%b", inv, pico_in, led);
                    errors++;
                end
            end
        end
        $display("%s (%0d errors)", errors == 0 ? "ALL TESTS PASSED" : "TESTS FAILED", errors);
        $finish;
    end
endmodule
