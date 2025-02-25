module fp16mul (
    input [15:0] A, B, //fp16 numbers
    output [31:0] P //fp32 number
);
    //prod sign
    assign P[31] = A[15] ^ B[15];

    //significand calc
    wire [21:0] sig_prod;
    assign sig_prod = {1'b1, A[9:0]} * {1'b1, B[9:0]}; //1'b1 hidden bit
    //normalization of significand
    assign P[22:0] = sig_prod[21] ? sig_prod[21:0] : sig_prod[20:0]; //no req for rounding

    //exponent calc
    wire [5:0] exp_prod; //cause 30(max)+30 = 60 -> 6bit rep
    assign exp_prod = A[14:10] + B[14:10]; //result has exp bias of 30
    //normalization of exp
    assign exp_prod = sig_prod[21] ? exp_prod + 1'b1 : exp_prod;
    //make bias 127 by adding 97
    assign P[30:23] = exp_prod + 7'b1100001;
endmodule