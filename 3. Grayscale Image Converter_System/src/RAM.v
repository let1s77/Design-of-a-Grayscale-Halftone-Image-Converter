module RAM (
    input             CLK,
    input             REN,
    input             WEN,
    input      [17:0] A,
    input      [7:0]  D,
    output reg [7:0]  Q
);

reg [7:0] mem [((1<<18) - 1) : 0];
//reg [17:0] A_temp;
//reg [8:0]  D_temp;

always @(posedge CLK) begin
    if (REN)
        Q <= mem[A];
    else
        Q <= 'd0;
        //Q <= 'dz;
end

always @(posedge CLK) begin
    if (WEN) begin
        mem[A] <= D;
    end
end
//always @(*) begin
//    if (WEN)
//        mem[A] = D;
//end
endmodule
