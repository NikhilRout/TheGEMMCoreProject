module fp32mul (
    input [31:0] A, B,
    output [31:0] P
);
    wire sign_a = A[31];
    wire sign_b = B[31];
    wire [7:0] exp_a = A[30:23];
    wire [7:0] exp_b = B[30:23];
    wire [22:0] frac_a = A[22:0];
    wire [22:0] frac_b = B[22:0];
    
    //Hidden bits (implied 1)
    wire hidden_a = |exp_a; //0 if exp_a is all zeros (denormal), 1 otherwise
    wire hidden_b = |exp_b;  

    //Exceptions/Special Cases
    wire a_is_zero = (~hidden_a) & (~|frac_a); //(exp_a == 8'b0) && (frac_a == 23'b0);
    wire b_is_zero = (~hidden_b) & (~|frac_b);
    wire a_is_inf = (&exp_a) & (~|frac_a); //(exp_a == 8'hFF) && (frac_a == 23'b0);
    wire b_is_inf = (&exp_b) & (~|frac_b);
    wire a_is_nan = (&exp_a) & (|frac_a); //(exp_a == 8'hFF) && (frac_a == 23'b0);
    wire b_is_nan = (&exp_b) & (|frac_b);
    
    //Product Sign bit
    wire sign_p = sign_a ^ sign_b;
    
    //Product Mantissa calc
    wire [23:0] full_frac_a = {hidden_a, frac_a};
    wire [23:0] full_frac_b = {hidden_b, frac_b};
    wire [47:0] frac_mul = full_frac_a * full_frac_b;
    //Normalization
    wire frac_mul_msb = frac_mul[47];
    wire [47:0] normalized_frac = frac_mul_msb ? frac_mul : frac_mul << 1;
    //Round to Nearest, Ties to Even (RNE)
    wire [22:0] rounded_frac = normalized_frac[46:24] + (normalized_frac[23] & (|normalized_frac[22:0] | normalized_frac[24]));
    
    //Product Exponent calc
    wire [9:0] exp_sum = {2'b0, exp_a} + {2'b0, exp_b} - 10'd127 + frac_mul_msb; //10bits cause {sign-bit, carry, number}
    wire underflow = exp_sum[9] | (~|exp_sum[8:0]); //underflow detected if sign-bit is 1 --> -ve exp (out of bounds) or exp=0
    wire overflow = !exp_sum[9] & (exp_sum[8] | (&exp_sum[7:0])); //overflow detected if +ve exp and exp >= 255 
    wire [7:0] exp_final = overflow ? 8'hFF : (underflow ? 8'h00 : exp_sum[7:0]);
    //Handle rounding overflow
    wire round_overflow = (&normalized_frac[46:24]) & normalized_frac[23];
    wire [7:0] exp_with_round = exp_final + round_overflow;
    
    //Result selection based on exceptions/special cases
    wire result_is_nan = a_is_nan | b_is_nan | (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);
    wire result_is_inf = overflow | (a_is_inf & ~b_is_zero) | (b_is_inf & ~a_is_zero);
    wire result_is_zero = underflow | a_is_zero | b_is_zero;

    //Final results to be selected
    wire [7:0] exp_p = result_is_nan ? 8'hFF : 
                  result_is_inf ? 8'hFF : 
                  result_is_zero ? 8'h00 : 
                  exp_with_round;
    wire [22:0] frac_p = result_is_nan ? 23'h400000 :  // Canonical NaN
                   result_is_inf ? 23'h000000 : 
                   result_is_zero ? 23'h000000 : 
                   rounded_frac;

    //Final Product               
    assign P = {sign_p, exp_p, frac_p};
endmodule
