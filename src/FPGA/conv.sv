// Quick test convolution engine
// Takes streaming input, Q1.15
module conv #(
    parameter int IR_LENGTH = 16
)(
    input  logic               clk, rst,
    input  logic signed [15:0] ir [IR_LENGTH],
    input  logic signed [15:0] in_samp,
    output logic signed [15:0] out_samp
);
    logic signed [15:0] taps [IR_LENGTH];
    logic signed [31:0] acc;

    always_ff @(posedge clk) begin
        if (rst) taps <= '{default: '0};
        else     taps <= {in_samp, taps[0:IR_LENGTH-2]};
    end

    always_comb begin
        acc = '0;
        for (int i = 0; i < IR_LENGTH; i++)
            acc += taps[i] * ir[i];
    end

    assign out_samp = acc[30:15];

endmodule
