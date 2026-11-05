// i2s_tx.v
// I2S transmit master (codec in slave mode), 24-bit samples in 32-bit slots.
// Runs in the MCLK domain at 256 fs:
//
//   BCLK  = MCLK / 4   = 64 fs
//   LRCLK = MCLK / 256 =    fs   (0 = left, 1 = right)


module i2s_tx (
    input  wire        clk,        // MCLK, 256 fs
    input  wire        rst,
    input  wire [23:0] tx_left,
    input  wire [23:0] tx_right,
    output reg         frame,
    output reg         bclk,
    output reg         lrclk,
    output reg         pbdat
);

    reg  [7:0]  cnt;
    wire [7:0]  nxt = cnt + 8'd1;
    reg  [23:0] l_lat, r_lat;

    // Slot n = c[6:2] (0..31), channel = c[7]
    //   n = 0     : 1-bit I2S delay
    //   n = 1..24 : word bit (24 - n), MSB first
    //   n > 24    : zero padding
    function tx_bit;
        input [7:0]  c;
        input [23:0] wl, wr;
        reg   [4:0]  n;
        reg   [23:0] w;
        begin
            n = c[6:2];
            w = c[7] ? wr : wl;
            if (n >= 5'd1 && n <= 5'd24) tx_bit = w[5'd24 - n];
            else                         tx_bit = 1'b0;
        end
    endfunction

    always @(posedge clk) begin
        frame <= 1'b0;
        if (rst) begin
            cnt   <= 8'd0;
            bclk  <= 1'b0;
            lrclk <= 1'b0;
            pbdat <= 1'b0;
            l_lat <= 24'd0;
            r_lat <= 24'd0;
        end else begin
            cnt   <= nxt;
            bclk  <= nxt[1];
            lrclk <= nxt[7];
            if (nxt == 8'd0) begin
                l_lat <= tx_left;
                r_lat <= tx_right;
                pbdat <= 1'b0;
                frame <= 1'b1;
            end else begin
                pbdat <= tx_bit(nxt, l_lat, r_lat);
            end
        end
    end

endmodule
