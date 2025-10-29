`timescale 1ns/1ps
module lfsr(
    input clk,
    input reset,
    output [7:0] random
);
    wire [7:0] q;
    wire feedback;
    wire xor1, xor2_out, xor3_out;

    // XOR feedback taps (bits 7,5,4,3)
    xor2 x1(.a(q[7]), .b(q[5]), .y(xor1));
    xor2 x2(.a(xor1), .b(q[4]), .y(xor2_out));
    xor2 x3(.a(xor2_out), .b(q[3]), .y(feedback));

    // Seed bits for initial non-zero value
    wire [7:0] seed = 8'b10101010;

    // D flip-flops with seed inputs
    dff f0(.clk(clk), .reset(reset), .d(feedback), .seed(seed[0]), .q(q[0]));
    dff f1(.clk(clk), .reset(reset), .d(q[0]), .seed(seed[1]), .q(q[1]));
    dff f2(.clk(clk), .reset(reset), .d(q[1]), .seed(seed[2]), .q(q[2]));
    dff f3(.clk(clk), .reset(reset), .d(q[2]), .seed(seed[3]), .q(q[3]));
    dff f4(.clk(clk), .reset(reset), .d(q[3]), .seed(seed[4]), .q(q[4]));
    dff f5(.clk(clk), .reset(reset), .d(q[4]), .seed(seed[5]), .q(q[5]));
    dff f6(.clk(clk), .reset(reset), .d(q[5]), .seed(seed[6]), .q(q[6]));
    dff f7(.clk(clk), .reset(reset), .d(q[6]), .seed(seed[7]), .q(q[7]));

    assign random = q;
endmodule
