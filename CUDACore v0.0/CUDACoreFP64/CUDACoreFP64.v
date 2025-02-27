module CUDACoreFP64 (
    input clk, rst,
    input [63:0] a, b,
    output reg [63:0] mac_op
);
    wire [63:0] mul, acc;
    fp64mul M0(.A(a), .B(b), .P(mul));
    fp64add A0(.A(mul), .B(mac_op), .S(acc));

    always @(posedge clk or posedge rst) begin
        if(rst)
            mac_op <= 64'd0;
        else
            mac_op <= acc;
    end
endmodule
