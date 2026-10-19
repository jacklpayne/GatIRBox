// Quick test convolution engine
// Takes streaming input, parameterized W(idth)
module conv #(
    parameter int W = 16,
    parameter int IR_LENGTH = 16
)(
    input  logic                clk, rst,
    input  logic                en,
    input  logic signed [W-1:0] ir [IR_LENGTH],
    input  logic signed [W-1:0] in_samp,
    output logic signed [W-1:0] out_samp
);
    logic signed [W-1:0]     taps [IR_LENGTH];
    logic signed [(W*2)-1:0] acc;

    always_ff @(posedge clk) begin
        if (rst)     taps <= '{default: '0};
        else if (en) taps <= {in_samp, taps[0:IR_LENGTH-2]};
    end

    always_comb begin
        acc = '0;
        for (int i = 0; i < IR_LENGTH; i++)
            acc += taps[i] * ir[i];
        acc += (1 <<< (W-2)); // round before >>15
    end

    assign out_samp = acc[(W*2)-2:W-1];

endmodule