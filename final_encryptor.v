`timescale 1ns/1ps

// -------------------------------------------------------
// 1. XOR Gate
// -------------------------------------------------------
module xor2 (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a ^ b;
endmodule

// -------------------------------------------------------
// 2. D Flip-Flop With Seed
// -------------------------------------------------------
module dff(
    input  wire clk,
    input  wire reset,
    input  wire d,
    input  wire seed,
    output reg  q
);
    always @(posedge clk) begin
        if (reset)
            q <= seed;   // load seed
        else
            q <= d;      // shift
    end
endmodule

// -------------------------------------------------------
// 3. LFSR (8-bit Pseudo Random Number Generator)
// -------------------------------------------------------
module lfsr(
    input  wire clk,
    input  wire reset,
    output wire [7:0] random
);
    wire [7:0] q;
    wire feedback;

    // taps: 7,5,4,3 (max-length LFSR)
    wire t1, t2, t3;
    xor2 x1(.a(q[7]), .b(q[5]), .y(t1));
    xor2 x2(.a(q[4]), .b(q[3]), .y(t2));
    xor2 x3(.a(t1),   .b(t2),   .y(feedback));

    wire [7:0] seed = 8'hA3;

    dff f0(.clk(clk), .reset(reset), .d(feedback), .seed(seed[0]), .q(q[0]));
    dff f1(.clk(clk), .reset(reset), .d(q[0]),     .seed(seed[1]), .q(q[1]));
    dff f2(.clk(clk), .reset(reset), .d(q[1]),     .seed(seed[2]), .q(q[2]));
    dff f3(.clk(clk), .reset(reset), .d(q[2]),     .seed(seed[3]), .q(q[3]));
    dff f4(.clk(clk), .reset(reset), .d(q[3]),     .seed(seed[4]), .q(q[4]));
    dff f5(.clk(clk), .reset(reset), .d(q[4]),     .seed(seed[5]), .q(q[5]));
    dff f6(.clk(clk), .reset(reset), .d(q[5]),     .seed(seed[6]), .q(q[6]));
    dff f7(.clk(clk), .reset(reset), .d(q[6]),     .seed(seed[7]), .q(q[7]));

    assign random = q;
endmodule

// -------------------------------------------------------
// 4. XOR STREAM CIPHER
// -------------------------------------------------------
module stream_cipher(
    input  wire [7:0] data_in,
    input  wire [7:0] key_in,
    output wire [7:0] data_out
);
    assign data_out = data_in ^ key_in;
endmodule

// -------------------------------------------------------
// 5. FULL ENCRYPTOR / DECRYPTOR MODULE
// -------------------------------------------------------
module message_encryptor(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] plaintext_in,
    output wire [7:0] ciphertext_out,
    output wire [7:0] keystream_out
);
    wire [7:0] key;

    lfsr u1(
        .clk(clk),
        .reset(reset),
        .random(key)
    );

    assign keystream_out = key;

    stream_cipher u2(
        .data_in(plaintext_in),
        .key_in(key),
        .data_out(ciphertext_out)
    );
endmodule

// -------------------------------------------------------
// 6. TESTBENCH (Prints Random Number + Encryption)
// -------------------------------------------------------
module tb_encryptor;

    reg clk;
    reg reset;
    reg [7:0] tb_plaintext;

    wire [7:0] tb_ciphertext;
    wire [7:0] tb_decrypted_text;

    wire [7:0] ks_encrypt;  
    wire [7:0] ks_decrypt;

    // Encryptor
    message_encryptor ENC(
        .clk(clk),
        .reset(reset),
        .plaintext_in(tb_plaintext),
        .ciphertext_out(tb_ciphertext),
        .keystream_out(ks_encrypt)
    );

    // Decryptor
    message_encryptor DEC(
        .clk(clk),
        .reset(reset),
        .plaintext_in(tb_ciphertext),
        .ciphertext_out(tb_decrypted_text),
        .keystream_out(ks_decrypt)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Message storage
    reg [7:0] message [0:18];
    integer i;

    initial begin
        $dumpfile("encryptor.vcd");
        $dumpvars(0, tb_encryptor);

        // "hello world!!!"
        message[0]  = 8'h44; // "h"
        message[1]  = 8'h69; // "e"
        message[2]  = 8'h67; // "l"
        message[3]  = 8'h69; // "l"
        message[4]  = 8'h74; // "o"
        message[5]  = 8'h61; // " "
        message[6]  = 8'h6C; // "w"
        message[7]  = 8'h20; // "o"
        message[8]  = 8'h45; // "r"
        message[9]  = 8'h6C; // "l"
        message[10] = 8'h65; // "d"
        message[11] = 8'h63; // " "
        message[12] = 8'h74; // "!"
        message[13] = 8'h72; // "!"
        message[14] = 8'h6F; // "!"
        message[15] = 8'h6E; // "!"
        message[16] = 8'h69; // "!"
        message[17] = 8'h63; // "!"
        message[18] = 8'h73; // "!"

        reset = 1;
        tb_plaintext = 8'h00;
        @(negedge clk);
        reset = 0;

        $display("Time | PT | KS | CT | DEC");
        $display("----------------------------------------------");

        for (i = 0; i < 19; i = i + 1) begin
            tb_plaintext = message[i];
            @(negedge clk);

            $display("%3dns | %02h (%c) | %02h | %02h | %02h (%c)",
                $time,
                tb_plaintext, tb_plaintext,
                ks_encrypt,
                tb_ciphertext,
                tb_decrypted_text, tb_decrypted_text
            );
        end

        $finish;
    end
endmodule
