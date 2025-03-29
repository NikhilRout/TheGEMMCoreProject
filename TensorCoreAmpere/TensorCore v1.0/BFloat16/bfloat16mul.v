module bfloat16mul (
    input [15:0] A, B, //fp16 number
    output [31:0] P //fp32 number
);
    wire sign_A = A[15];
    wire sign_B = B[15];
    wire [7:0] exp_a = A[14:7];
    wire [7:0] exp_b = B[14:7];
    wire [6:0] frac_A = A[6:0];
    wire [6:0] frac_B = B[6:0];
    
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
    wire [7:0] full_mant_A = {hidden_A, frac_A};
    wire [7:0] full_mant_B = {hidden_B, frac_B};
    wire [13:0] product_mant = full_mant_A * full_mant_B;
    //Normalization
    wire normalize_shift = product_mant[13];
    wire [22:0] fp32_mantissa = normalize_shift ? {product_mant[12:0], 10'd0} : {product_mant[11:0], 11'd0};
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
 
