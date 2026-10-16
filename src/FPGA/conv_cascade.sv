// Cascade of convolution engine instances
// This will ultimately implement per-IR dry/wet
module conv_cascade #(
    parameter int IR0_LENGTH = 16,
    parameter int IR1_LENGTH = 16,
    parameter int IR2_LENGTH = 16
)(
    input logic clk,  rst,
    input  logic signed [15:0] ir0 [IR0_LENGTH],
    input  logic signed [15:0] ir1 [IR1_LENGTH],
    input  logic signed [15:0] ir2 [IR2_LENGTH],
    input logic[15:0] in_samp,
    output logic[15:0] out_samp
);


endmodule
