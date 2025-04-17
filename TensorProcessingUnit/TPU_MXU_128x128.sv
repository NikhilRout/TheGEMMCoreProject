//128x128 bfloat16 Matrix Multiplication Unit (MXU)

`include "bfloat16mult.v"
`include "bfloat16add.v"

module TPU_MXU_128x128 (
    input clk, rst,
    input [15:0] row_inp[0:127],
    input [15:0] col_inp[0:127],
    output [15:0] mat_out[0:2][0:2]
);
    //Internal wires for horizontal and vertical connections in the systolic array
    wire [15:0] r_wires[0:127][0:127];
    wire [15:0] c_wires[0:127][0:127];
    
    genvar i, j;
    generate
        for (i = 0; i < 128; i = i + 1) begin: row
            for (j = 0; j < 128; j = j + 1) begin: col
                if (i == 0 && j == 0) begin
                    PE pe_inst(
                        .clk(clk),
                        .rst(rst),
                        .M(row_inp[i]),
                        .N(col_inp[j]),
                        .P(r_wires[i][j]),
                        .Q(c_wires[i][j]),
                        .R(mat_out[i][j])
                    );
                end
                else if (i == 0) begin
                    PE pe_inst(
                        .clk(clk),
                        .rst(rst),
                        .M(r_wires[i][j-1]),
                        .N(col_inp[j]),
                        .P(r_wires[i][j]),
                        .Q(c_wires[i][j]),
                        .R(mat_out[i][j])
                    );
                end
                else if (j == 0) begin
                    PE pe_inst(
                        .clk(clk),
                        .rst(rst),
                        .M(row_inp[i]),
                        .N(c_wires[i-1][j]),
                        .P(r_wires[i][j]),
                        .Q(c_wires[i][j]),
                        .R(mat_out[i][j])
                    );
                end
                else begin
                    PE pe_inst(
                        .clk(clk),
                        .rst(rst),
                        .M(r_wires[i][j-1]),
                        .N(c_wires[i-1][j]),
                        .P(r_wires[i][j]),
                        .Q(c_wires[i][j]),
                        .R(mat_out[i][j])
                    );
                end
                
                //Special cases for edge PEs with unused outputs
                if (i == 127) begin
                    assign c_wires[i][j] = 16'b0;
                end
                if (j == 127) begin
                    assign r_wires[i][j] = 16'b0;
                end
            end
        end
    endgenerate
endmodule

module PE (
    input clk, rst,
    input [15:0] M, N,
    output reg [15:0] P, Q,
    output reg [15:0] R
);
    wire [15:0] temp_mul, mac_result;
    bfloat16mult M0(.A(M), .B(N), .P(temp_mul));
    bfloat16add A0(.A(R), .B(temp_mul), .S(mac_result));
    always @(posedge clk) begin
        if (rst) 
            {P, Q, R} <= 0;
        else begin
            P = M;
            Q = N;
            R = mac_result;
        end
    end
endmodule
