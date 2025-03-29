module fp8mulE5M2 (
    input [7:0] A, B, //fp8 input
    output [15:0] P //fp16 output
);
    wire sign_A = A[7];
    wire sign_B = B[7];
    wire [4:0] exp_a = A[6:2];
    wire [4:0] exp_b = B[6:2];
    wire [1:0] frac_A = A[1:0];
    wire [1:0] frac_B = B[1:0];

    //Hidden bits (implied 1)
    wire hidden_A = |exp_a; //0 if exp_a is all zeros (denormal), 1 otherwise
    wire hidden_B = |exp_b;

    //Exception/Special Cases
    wire A_is_zero = (~hidden_A) & (~|frac_A);
    wire B_is_zero = (~hidden_B) & (~|frac_B);
    wire A_is_inf = (&exp_a) & (~|frac_A);
    wire B_is_inf = (&exp_b) & (~|frac_B);
    wire A_is_nan = (&exp_a) & (|frac_A);
    wire B_is_nan = (&exp_b) & (|frac_B);

    //Result sign
    wire result_sign = sign_A ^ sign_B;

    //Result Mantissa Calc
    wire [2:0] full_mant_A = {hidden_A, frac_A};
    wire [2:0] full_mant_B = {hidden_B, frac_B};
    wire [5:0] product_mant = full_mant_A * full_mant_B;
    //Normalization
    wire normalize_shift = product_mant[5];
    wire [9:0] fp16_mantissa = normalize_shift ? {product_mant[4:0], 5'd0} : {product_mant[3:0], 6'd0};    
    //no rounding required --> there will never be rounding overflow

    //Product Exponent calc
    wire [6:0] exp_sum = {2'b0, exp_a} + {2'b0, exp_b} - 7'd15 + normalize_shift; //6bits cause {sign-bit, carry, number}
    wire underflow = exp_sum[6] | (~|exp_sum[5:0]); //underflow detected if sign-bit is 1 --> -ve exp (out of bounds) or exp=0
                                                    //overflow is impossible since i/ps are in fp8
    //Result selection flags
    wire result_is_nan = A_is_nan | B_is_nan | (A_is_inf & B_is_zero) | (B_is_inf & A_is_zero);
    wire result_is_inf = (A_is_inf & ~B_is_zero) | (B_is_inf & ~A_is_zero);
    wire result_is_zero = underflow | A_is_zero | B_is_zero;
    
    reg [4:0] final_exp;
    reg [9:0] final_frac;
    always @(*) begin
        case({result_is_nan, result_is_inf, result_is_zero})
            3'b100: begin
                        final_exp = 5'h1F;
                        final_frac = 10'h200;
            end
            3'b010: begin
                        final_exp = 5'h1F;
                        final_frac = 10'h000;
            end
            3'b001: begin
                        final_exp = 5'h00;
                        final_frac = 10'h000;
            end
            default: begin
                        final_exp = exp_sum[4:0];
                        final_frac = fp16_mantissa;
            end
        endcase
    end

    assign P = {result_sign, final_exp, final_frac};
endmodule
