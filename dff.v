module dff(
    input clk,
    input reset,
    input d,
    input seed,          // <-- new input for seeding
    output reg q
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= seed;   // initialize from seed
        else
            q <= d;
    end
endmodule
