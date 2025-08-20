 // memory siz: 512*512 * 24-bit

module ROM(
    input             CLK,
    input             REN,
    input      [17:0] A,
    output reg [23:0] Q
);

reg [23:0] mem [((1<<18) - 1) : 0];

always @(posedge CLK) begin
    if (REN)
        Q <= mem[A];
    else
        Q <= 'd0;
        //Q <= 'dz;
end

endmodule
