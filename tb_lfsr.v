`timescale 1ns/1ps
module tb_lfsr;
    reg clk = 0;
    reg reset;
    wire [7:0] random;

    lfsr uut (
        .clk(clk),
        .reset(reset),
        .random(random)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_lfsr);

        reset = 1; #10;
        reset = 0; // release reset

        repeat (30) begin
            #10;
            $display("Random: %b (%0d)", random, random);
        end

        $finish;
    end
endmodule
