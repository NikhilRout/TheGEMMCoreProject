module fp16mul (
    input [15:0] A, B,  // FP16 numbers
    output [31:0] P     // FP32 number
);
    wire sign_A = A[15];
    wire sign_B = B[15];
    wire [4:0] exp_A = A[14:10];
    wire [4:0] exp_B = B[14:10];
    wire [9:0] frac_A = A[9:0];
    wire [9:0] frac_B = B[9:0];

    wire result_sign = sign_A ^ sign_B;

    wire [11:0] mant_A = {1'b1, frac_A, 1'b0};
    wire [11:0] mant_B = {1'b1, frac_B, 1'b0};
    wire [23:0] product_mant = mant_A * mant_B;

    wire normalize_shift = product_mant[23];
    wire [22:0] fp32_mantissa = normalize_shift ? product_mant[22:0] : {product_mant[21:0], 1'b0};
    wire [7:0] result_exp = exp_A + exp_B + 8'd97 + normalize_shift;

    assign P = {result_sign, result_exp, fp32_mantissa};
endmodule

/*
module fp16mul (
    input [15:0] A, B,  // FP16 numbers
    output [31:0] P     // FP32 number
);
    // Extract sign, exponent, and significand
    wire sign_a, sign_b;
    wire [4:0] exp_a, exp_b;
    wire [10:0] sig_a, sig_b;  // Include implicit bit

    assign sign_a = A[15];
    assign sign_b = B[15];
    assign exp_a  = A[14:10];
    assign exp_b  = B[14:10];
    assign sig_a  = (exp_a == 0) ? {1'b0, A[9:0]} : {1'b1, A[9:0]};
    assign sig_b  = (exp_b == 0) ? {1'b0, B[9:0]} : {1'b1, B[9:0]};

    // Compute product
    wire [21:0] sig_prod = sig_a * sig_b;

    // Compute exponent sum with correct biasing
    wire [7:0] exp_sum = exp_a + exp_b + 8'd97;  // Convert FP16 bias 15 to FP32 bias 127

    // Normalization
    wire [7:0] exp_norm;
    wire [22:0] sig_norm;

    assign {exp_norm, sig_norm} = sig_prod[21] ? {exp_sum + 1'b1, sig_prod[21:0]} : {exp_sum, sig_prod[20:0]};

    // Assign outputs
    assign P[31] = sign_a ^ sign_b;  // Final sign
    assign P[30:23] = exp_norm;       // Final exponent
    assign P[22:0] = sig_norm;        // Final significand

endmodule
*/


/*
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
    wire [5:0] exp_sum, exp_norm; //cause 30(max)+30 = 60 -> 6bit rep
    assign exp_sum = A[14:10] + B[14:10]; //result has exp bias of 30
    //normalization of exp
    assign exp_norm = sig_prod[21] ? exp_sum + 1'b1 : exp_sum;
    //make bias 127 by adding 97
    assign P[30:23] = exp_norm + 7'b1100001;
endmodule
*/