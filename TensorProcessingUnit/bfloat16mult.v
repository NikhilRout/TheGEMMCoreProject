module bfloat16mult (
    input [15:0] A, B, //bfloat16 numbers
    output [15:0] P //bfloat16 number
);
    wire sign_a = A[15];
    wire sign_b = B[15];
    wire [7:0] exp_a = A[14:7];
    wire [7:0] exp_b = B[14:7];
    wire [6:0] frac_a = A[6:0];
    wire [6:0] frac_b = B[6:0];
    
    //Hidden bits (implied 1)
    wire hidden_a = |exp_a; //0 if exp_a is all zeros (denormal), 1 otherwise
    wire hidden_b = |exp_b;
    
    //Exception/Special Cases
    wire a_is_zero = (~hidden_a) & (~|frac_a);
    wire b_is_zero = (~hidden_b) & (~|frac_b);
    wire a_is_inf = (&exp_a) & (~|frac_a);
    wire b_is_inf = (&exp_b) & (~|frac_b);
    wire a_is_nan = (&exp_a) & (|frac_a);
    wire b_is_nan = (&exp_b) & (|frac_b);
    
    //Result sign
    wire result_sign = sign_a ^ sign_b;
    
    //Result Mantissa Calc
    wire [7:0] full_mant_a = {hidden_a, frac_a};
    wire [7:0] full_mant_b = {hidden_b, frac_b};
    wire [15:0] frac_mul = full_mant_a * full_mant_b; //8x8 --> 16 bits
    //Normalization
    wire normalize_shift = frac_mul[15];
    wire [15:0] normalized_frac = normalize_shift ? frac_mul : frac_mul << 1;
    //Round to Nearest, Ties to Even (RNE)
    wire [6:0] rounded_frac = normalized_frac[14:8] + (normalized_frac[7] & (|normalized_frac[6:0] | normalized_frac[8]));

    //Product Exponent calc
    wire [9:0] exp_sum = {2'b0, exp_a} + {2'b0, exp_b} - 10'd127 + normalize_shift; //10bits cause {sign-bit, carry, number}
    wire underflow = exp_sum[9] | (~|exp_sum[8:0]); //underflow detected if sign-bit is 1 --> -ve exp (out of bounds) or exp=0
    wire overflow = ~(exp_sum[9]) & (exp_sum[8] | (&exp_sum[7:0])); //overflow detected if +ve exp and exp >= 255 

    //Result selection flags
    wire result_is_nan = a_is_nan | b_is_nan | (a_is_inf & b_is_zero) | (b_is_inf & a_is_zero);
    wire result_is_inf = overflow | (a_is_inf & ~b_is_zero) | (b_is_inf & ~a_is_zero);
    wire result_is_zero = underflow | a_is_zero | b_is_zero;
    
    reg [7:0] final_exp;
    reg [22:0] final_frac;

    always @(*) begin
        case({result_is_nan, result_is_inf, result_is_zero})
            3'b100: begin
                        final_exp = 8'hFF;
                        final_frac = 7'h40;
            end
            3'b010: begin
                        final_exp = 8'hFF;
                        final_frac = 7'h00;
            end
            3'b001: begin
                        final_exp = 8'h00;
                        final_frac = 7'h00;
            end
            default: begin
                        final_exp = exp_sum[7:0];
                        final_frac = rounded_frac;
            end
        endcase
    end

    assign P = {result_sign, final_exp, final_frac};
endmodule
 
