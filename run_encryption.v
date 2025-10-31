`timescale 1ns/1ps

// ------------------------------------
// 1. HELPER MODULES (Needed by your LFSR)
// ------------------------------------
module xor2 (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a ^ b;
endmodule

module dff ( // Dlf-flip-flop with reset and seed
    input  wire clk,
    input  wire reset,
    input  wire d,
    input  wire seed,
    output reg  q
);
    always @(posedge clk) begin
        if (reset) begin
            q <= seed; // Load the seed on reset
        end else begin
            q <= d;    // Normal operation
        end
    end
endmodule

// ------------------------------------
// 2. YOUR LFSR MODULE
// ------------------------------------
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

// ------------------------------------
// 3. THE CIPHER MODULE (XOR)
// ------------------------------------
module stream_cipher (
    input  wire [7:0] data_in,
    input  wire [7:0] key_in,
    output wire [7:0] data_out
);
    assign data_out = data_in ^ key_in;
endmodule

// ------------------------------------
// 4. THE TOP-LEVEL ENCRYPTOR
// ------------------------------------
module message_encryptor (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] plaintext_in,
    output wire [7:0] ciphertext_out
);
    wire [7:0] keystream;

    lfsr u_prng (
        .clk(clk),
        .reset(reset),
        .random(keystream)
    );
    stream_cipher u_cipher (
        .data_in(plaintext_in),
        .key_in(keystream),
        .data_out(ciphertext_out)
    );
endmodule

// ------------------------------------
// 5. YOUR TESTBENCH (NOW SENDS "hello world !")
// ------------------------------------
module tb_encryptor;
    // Testbench signals
    reg         clk;
    reg         reset;
    reg  [7:0]  tb_plaintext;
    wire [7:0]  tb_ciphertext;
    wire [7:0]  tb_decrypted_text;

    // 1. Instantiate the ENCRYPTOR
    message_encryptor u_encryptor (
        .clk(clk),
        .reset(reset),
        .plaintext_in(tb_plaintext),
        .ciphertext_out(tb_ciphertext)
    );

    // 2. Instantiate the DECRYPTOR
    message_encryptor u_decryptor (
        .clk(clk),
        .reset(reset),
        .plaintext_in(tb_ciphertext),
        .ciphertext_out(tb_decrypted_text)
    );

    // 3. Generate the Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100MHz clock)
    end

    // Store the new message
    reg [7:0] message [0:12]; // 13 characters
    integer i; // Loop counter

    // 4. Provide the Stimulus (the test)
    initial begin
        // --- Load the message ---
        message[0]  = 8'h68; // "h"
        message[1]  = 8'h65; // "e"
        message[2]  = 8'h6C; // "l"
        message[3]  = 8'h6C; // "l"
        message[4]  = 8'h6F; // "o"
        message[5]  = 8'h20; // " "
        message[6]  = 8'h77; // "w"
        message[7]  = 8'h6F; // "o"
        message[8]  = 8'h72; // "r"
        message[9]  = 8'h6C; // "l"
        message[10] = 8'h64; // "d"
        message[11] = 8'h20; // " "
        message[12] = 8'h21; // "!"

        // --- Setup ---
        $display("Time  | Plaintext | Ciphertext | Decrypted");
        $display("--------------------------------------------");
        reset = 1;        // Start in reset
        tb_plaintext = 0;
        @(negedge clk);
        reset = 0;        // Release reset
        @(negedge clk);

        // --- Send the message using a loop ---
        for (i = 0; i < 13; i = i + 1) begin
            tb_plaintext = message[i];
            @(negedge clk);
            $display("%3dns | 0x%h (%c) |   0x%h    |  0x%h (%c)", $time, 
                     tb_plaintext, tb_plaintext, tb_ciphertext, tb_decrypted_text, tb_decrypted_text);
        end

        // --- Send one last dummy byte ---
        tb_plaintext = 8'h00;
        @(negedge clk);
        $display("%3dns | 0x%h (%c) |   0x%h    |  0x%h (%c)", $time, 
                 tb_plaintext, tb_plaintext, tb_ciphertext, tb_decrypted_text, tb_decrypted_text);

        $display("\nSimulation Finished.");
        $finish; // End the simulation
    end
endmodule