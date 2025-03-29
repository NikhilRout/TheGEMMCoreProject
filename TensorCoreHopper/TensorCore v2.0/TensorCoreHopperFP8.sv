`define E5M2
// `define E4M3
// (un)comment as required

`ifdef E5M2 
    `include "fp8mulE5M2.v"
`elsif E4M3
    `include "fp8mulE4M3.v"
`endif
`include "fp16add.v"

module TensorCoreHopperFP8 (
    input [7:0] A[0:3][0:3], B[0:3][0:3],
    input [15:0] C[0:3][0:3],
    output [15:0] D[0:3][0:3]
);
    wire [15:0] P[0:3][0:3]; //mul of A x B

    genvar i, j, k;
    generate
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                wire [15:0] w[0:5];
                for(k = 0; k < 4; k = k + 1) begin
                    `ifdef E5M2
                        fp8mulE5M2 MUL(.A(A[i][k]), .B(B[k][j]), .P(w[k]));
                    `elsif E4M3
                        fp8mulE4M3 MUL(.A(A[i][k]), .B(B[k][j]), .P(w[k]));
                    `endif
                end
                fp16add U(.A(w[0]), .B(w[1]), .S(w[4]));
                fp16add D(.A(w[2]), .B(w[3]), .S(w[5]));
                fp16add PP(.A(w[4]), .B(w[5]), .S(P[i][j]));  
            end    
        end
    endgenerate

    genvar x, y;
    generate
        for(x = 0; x < 4; x = x + 1) begin
            for(y = 0; y < 4; y = y + 1) begin
                fp16add ADD(.A(C[x][y]), .B(P[x][y]), .S(D[x][y]));
            end
        end
    endgenerate
endmodule

