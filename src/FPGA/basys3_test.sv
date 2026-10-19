// Test wrapper for conv, targeting Basys3 I have on hand
module b3_top (
    input  logic        clk,    // 100 MHz
    input  logic        rst,    // reset
    input  logic [15:0] sw,     // unused
    output logic [15:0] led,    // out_samp
    output logic [6:0]  seg,    // active-low, seg[0] = CA
    output logic [3:0]  an     // active-low
);

    localparam int W        = 16;
    localparam int IR_LEN   = 16;
    localparam int TICK_DIV = 100_000_000; // 1 Hz

    // 1 Hz tick for enabling conv and updating ramp
    logic [$clog2(TICK_DIV)-1:0] div_cnt = '0;
    logic                        tick;

    always_ff @(posedge clk) begin
        if (rst || tick) div_cnt <= '0;
        else             div_cnt <= div_cnt + 1;
    end

    assign tick = (div_cnt == TICK_DIV-1);

    // IR dialed by switches
    logic signed [W-1:0] test_ir [IR_LEN];
    always_comb begin
        for (int i = 0; i < IR_LEN; i++) begin
            test_ir[i] = sw[i] ? 16'sh7FFF : '0;
        end
    end

    // ramp generator
    logic signed [W-1:0] tri_samp = '0;
    always_ff @(posedge clk) begin
        if (rst)
            tri_samp <= '0;
        else if (tick)
            tri_samp <= (tri_samp == 16'sd3) ? '0 : tri_samp + 1;
    end

    // Convolution
    logic signed [W-1:0] out_samp;

    conv #(
        .W(W),
        .IR_LENGTH(IR_LEN)
    ) u_conv (
        .clk(clk),
        .rst(rst),
        .en(tick),
        .ir(test_ir),
        .in_samp(tri_samp),
        .out_samp(out_samp)
    );

    assign led = out_samp;

    // 7seg display
    // 100 MHz / 2^18 = ~381 Hz full refresh
    logic [17:0] refresh_cnt = '0;

    always_ff @(posedge clk) refresh_cnt <= refresh_cnt + 1;

    function automatic logic [6:0] hex2seg(input logic [3:0] h);
        case (h)
            4'h0: return 7'b1000000;
            4'h1: return 7'b1111001;
            4'h2: return 7'b0100100;
            4'h3: return 7'b0110000;
            4'h4: return 7'b0011001;
            4'h5: return 7'b0010010;
            4'h6: return 7'b0000010;
            4'h7: return 7'b1111000;
            4'h8: return 7'b0000000;
            4'h9: return 7'b0010000;
            4'hA: return 7'b0001000;
            4'hB: return 7'b0000011;
            4'hC: return 7'b0100111;
            4'hD: return 7'b0100001;
            4'hE: return 7'b0000110;
            default: return 7'b0001110; // F
        endcase
    endfunction

    always_comb begin
        if (refresh_cnt[17]) begin
            an  = 4'b0111;                  // leftmost digit: input
            seg = hex2seg(tri_samp[3:0]);
        end else begin
            an  = 4'b1110;                  // rightmost digit: output
            seg = hex2seg(out_samp[3:0]);
        end
    end
endmodule
