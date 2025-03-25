module fp64mul (
    input [63:0] A, B,
    output [63:0] P
);
    wire sign_a = A[63];
    wire sign_b = B[63];
    wire [10:0] exp_a = A[62:52];
    wire [10:0] exp_b = B[62:52];
    wire [51:0] frac_a = A[51:0];
    wire [51:0] frac_b = B[51:0];
    
    //Hidden bits (implied 1)
    wire hidden_a = |exp_a; //0 if exp_a is all zeros (denormal), 1 otherwise
    wire hidden_b = |exp_b;  

    //Exceptions/Special Cases
    wire a_is_zero = (~hidden_a) & (~|frac_a); //(exp_a == 11'b0) && (frac_a == 52'b0);
    wire b_is_zero = (~hidden_b) & (~|frac_b);
    wire a_is_inf = (&exp_a) & (~|frac_a); //(exp_a == 11'h7FF) && (frac_a == 52'b0);
    wire b_is_inf = (&exp_b) & (~|frac_b);
    wire a_is_nan = (&exp_a) & (|frac_a); //(exp_a == 11'h7FF) && (frac_a != 52'b0);
    wire b_is_nan = (&exp_b) & (|frac_b);
    
    //Product Sign bit
    wire sign_p = sign_a ^ sign_b;
    
    //Product Mantissa calc
    wire [52:0] full_frac_a = {hidden_a, frac_a};
    wire [52:0] full_frac_b = {hidden_b, frac_b};
    wire [105:0] frac_mul = full_frac_a * full_frac_b;
    //Normalization
    wire frac_mul_msb = frac_mul[105];
    wire [105:0] normalized_frac = frac_mul_msb ? frac_mul : frac_mul << 1;
    //Round to Nearest, Ties to Even (RNE)
    wire [51:0] rounded_frac = normalized_frac[104:53] + (normalized_frac[52] & (|normalized_frac[51:0] | normalized_frac[53]));
    
    //Product Exponent calc
    wire [12:0] exp_sum = {2'b0, exp_a} + {2'b0, exp_b} - 13'd1023 + frac_mul_msb; //13bits cause {sign-bit, carry, number}
    wire underflow = exp_sum[12] | (~|exp_sum[11:0]); //underflow detected if sign-bit is 1 --> -ve exp (out of bounds) or exp=0
    wire overflow = !exp_sum[12] & (exp_sum[11] | (&exp_sum[10:0])); //overflow detected if +ve exp and exp >= 2047 
    wire [10:0] exp_final = overflow ? 11'h7FF : (underflow ? 11'h000 : exp_sum[10:0]);
    //Handle rounding overflow
    wire round_overflow = (&normalized_frac[104:53]) & normalized_frac[52];
    wire [10:0] exp_with_round = exp_final + round_overflow;
    
    //Result selection based on exceptions/special cases
    wire result_is_nan = a_is_nan | b_is_nan | (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);
    wire result_is_inf = overflow | (a_is_inf & ~b_is_zero) | (b_is_inf & ~a_is_zero);
    wire result_is_zero = underflow | a_is_zero | b_is_zero;

    //Final results to be selected
    wire [10:0] exp_p = result_is_nan ? 11'h7FF : 
                   result_is_inf ? 11'h7FF : 
                   result_is_zero ? 11'h000 : 
                   exp_with_round;
    wire [51:0] frac_p = result_is_nan ? 52'h8000000000000 :  // Canonical NaN
                    result_is_inf ? 52'h0000000000000 : 
                    result_is_zero ? 52'h0000000000000 : 
                    rounded_frac;

    //Final Product               
    assign P = {sign_p, exp_p, frac_p};
endmodule
