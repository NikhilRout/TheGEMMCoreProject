module tf32mul (
    input [31:0] A, B, //fp32 number
    output [31:0] P //fp32 number
);
    wire sign_a = A[31];
    wire sign_b = B[31];
    wire [7:0] exp_a = A[30:23];
    wire [7:0] exp_b = B[30:23];
    wire [9:0] frac_A = A[22:13];
    wire [9:0] frac_B = B[22:13];
    
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
    wire result_sign = sign_a ^ sign_b;
    
    //Result Mantissa Calc
    wire [10:0] full_mant_A = {hidden_A, frac_A};
    wire [10:0] full_mant_B = {hidden_B, frac_B};
    wire [21:0] product_mant = full_mant_A * full_mant_B;
    //Normalization
    wire normalize_shift = product_mant[21];
    wire [22:0] fp32_mantissa = normalize_shift ? {product_mant[20:0], 2'b00} : {product_mant[19:0], 3'b000};
    //no rounding required --> there will never be rounding overflow

    //Product Exponent calc
    wire [9:0] exp_sum = {2'b0, exp_a} + {2'b0, exp_b} - 10'd127 + normalize_shift; //10bits cause {sign-bit, carry, number}
    wire underflow = exp_sum[9] | (~|exp_sum[8:0]); //underflow detected if sign-bit is 1 --> -ve exp (out of bounds) or exp=0
    wire overflow = ~(exp_sum[9]) & (exp_sum[8] | (&exp_sum[7:0])); //overflow detected if +ve exp and exp >= 255 

    //Result selection flags
    wire result_is_nan = A_is_nan | B_is_nan | (A_is_inf & B_is_zero) | (B_is_inf & A_is_zero);
    wire result_is_inf = overflow | (A_is_inf & ~B_is_zero) | (B_is_inf & ~A_is_zero);
    wire result_is_zero = underflow | A_is_zero | B_is_zero;
    
    reg [7:0] final_exp;
    reg [22:0] final_frac;

    always @(*) begin
        case({result_is_nan, result_is_inf, result_is_zero})
            3'b100: begin
                        final_exp = 8'hFF;
                        final_frac = 23'h400000;
            end
            3'b010: begin
                        final_exp = 8'hFF;
                        final_frac = 23'h000000;
            end
            3'b001: begin
                        final_exp = 8'h00;
                        final_frac = 23'h000000;
            end
            default: begin
                        final_exp = exp_sum[7:0];
                        final_frac = fp32_mantissa;
            end
        endcase
    end

    assign P = {result_sign, final_exp, final_frac};
endmodule
 