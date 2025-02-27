module CUDACoreFP32 (
    input clk, rst,
    input [31:0] a, b,
    output reg [31:0] mac_op
);
    wire [31:0] mul, acc;
    fp32mul M0(.A(a), .B(b), .P(mul));
    fp32add A0(.A(mul), .B(mac_op), .S(acc));

    always @(posedge clk or posedge rst) begin
        if(rst)
            mac_op <= 32'd0;
        else
            mac_op <= acc;
    end
endmodule
