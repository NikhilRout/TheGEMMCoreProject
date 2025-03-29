`include "fpADD32.v"
`include "bfloat16mul.v"

module TensorCoreAmpereBFloat16 (
    input [15:0] A[0:3][0:3], B[0:3][0:3],
    input [31:0] C[0:3][0:3],
    output [31:0] D[0:3][0:3]
);
    wire [31:0] P[0:3][0:3]; //mul of A x B

    genvar i, j, k;
    generate
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                wire [31:0] w[0:5];
                for(k = 0; k < 4; k = k + 1) begin 
                    bfloat16mul MUL(.A(A[i][k]), .B(B[k][j]), .P(w[k]));
                end
                fpADD32 U(.A(w[0]), .B(w[1]), .S(w[4]));
                fpADD32 D(.A(w[2]), .B(w[3]), .S(w[5]));
                fpADD32 PP(.A(w[4]), .B(w[5]), .S(P[i][j]));  
            end    
        end
    endgenerate

    genvar x, y;
    generate
        for(x = 0; x < 4; x = x + 1) begin
            for(y = 0; y < 4; y = y + 1) begin
                fpADD32 ADD(.A(C[x][y]), .B(P[x][y]), .S(D[x][y]));
            end
        end
    endgenerate
endmodule
