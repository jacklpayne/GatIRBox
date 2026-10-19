// Cascade of convolution engine instances
// This will ultimately implement per-IR dry/wet
module conv_cascade #(
    parameter int W = 16,
    parameter int IR0_LENGTH = 16,
    parameter int IR1_LENGTH = 16,
    parameter int IR2_LENGTH = 16
)(
    input logic clk,  rst,
    input  logic signed [W-1:0] ir0 [IR0_LENGTH],
    input  logic signed [W-1:0] ir1 [IR1_LENGTH],
    input  logic signed [W-1:0] ir2 [IR2_LENGTH],
    input logic[W-1:0] in_samp,
    output logic[W-1:0] out_samp
);


logic[W-1:0] conv0_out;
conv conv0 (
    .clk(clk),
    .rst(rst),
    .ir(ir0),
    .in_samp(in_samp),
    .out_samp(conv0_out)
);

logic[W-1:0] conv1_out;
conv conv1 (
    .clk(clk),
    .rst(rst),
    .ir(ir0),
    .in_samp(conv0_out),
    .out_samp(conv1_out)
);

conv conv2 (
    .clk(clk),
    .rst(rst),
    .ir(ir0),
    .in_samp(conv1_out),
    .out_samp(out_samp)
);
endmodule
