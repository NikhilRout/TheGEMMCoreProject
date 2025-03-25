module TensorCoreVolta (
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
                    fp16mul MUL(.A(A[i][k]), .B(B[k][j]), .P(w[k]));
                end
                fp32add U(.A(w[0]), .B(w[1]), .S(w[4]));
                fp32add D(.A(w[2]), .B(w[3]), .S(w[5]));
                fp32add PP(.A(w[4]), .B(w[5]), .S(P[i][j]));  
            end    
        end
    endgenerate

    genvar x, y;
    generate
        for(x = 0; x < 4; x = x + 1) begin
            for(y = 0; y < 4; y = y + 1) begin
                fp32add ADD(.A(C[x][y]), .B(P[x][y]), .S(D[x][y]));
            end
        end
    endgenerate
endmodule

/*
    wire [31:0] w00_00, w01_10, w02_20, w03_30, w00_U, w00_D;
    fp16mul P00_00(.A(A[0][0]), .B[0][0], .P(w00_00));
    fp16mul P01_10(.A(A[0][1]), .B[1][0], .P(w01_10));
    fp16mul P02_20(.A(A[0][2]), .B[2][0], .P(w02_20));
    fp16mul P03_30(.A(A[0][3]), .B[3][0], .P(w03_30));
    fp32add D00_U(.A(w00_00), .B(w01_10), .S(w00_U));
    fp32add D00_D(.A(w02_20), .B(w03_30), .S(w00_D));
    fp32add D00(.A(w00_U), .B(w00_D), .S(P[0][0]));
*/