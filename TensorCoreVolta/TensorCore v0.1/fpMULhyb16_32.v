module fpMULhyb16_32 (
    input [15:0] A, B, //fp16 number
    output [31:0] P //fp32 number
);
    wire sign_A = A[15];
    wire sign_B = B[15];
    wire [4:0] exp_A = A[14:10];
    wire [4:0] exp_B = B[14:10];
    wire [9:0] frac_A = A[9:0];
    wire [9:0] frac_B = B[9:0];
    
    //Hidden bits (implied 1)
    wire hidden_A = |exp_A; //0 if exp_A is all zeros (denormal), 1 otherwise
    wire hidden_B = |exp_B;
    
    //Exception/Special Cases
    wire A_is_zero = (~hidden_A) & (~|frac_A);
    wire B_is_zero = (~hidden_B) & (~|frac_B);
    wire A_is_inf = (&exp_A) & (~|frac_A);
    wire B_is_inf = (&exp_B) & (~|frac_B);
    wire A_is_nan = (&exp_A) & (|frac_A);
    wire B_is_nan = (&exp_B) & (|frac_B);
    
    //Result sign
    wire result_sign = sign_A ^ sign_B;
    
    //Result Mantissa Calc
    wire [10:0] full_mant_A = {hidden_A, frac_A};
    wire [10:0] full_mant_B = {hidden_B, frac_B};
    wire [21:0] product_mant = full_mant_A * full_mant_B;
    //Normalization
    wire normalize_shift = product_mant[21];
    wire [22:0] fp32_mantissa = normalize_shift ? {product_mant[20:0], 2'b00} : {product_mant[19:0], 3'b000};

    //Result Exponent Calc
    wire [6:0] exp_sum = {2'b0, exp_A} + {2'b0, exp_B} - 7'd15 + normalize_shift;
    wire [7:0] biased_exp = exp_sum + 8'd112;
    wire underflow = exp_sum[6] | (~|exp_sum[5:0]); //Underflow detected --> Negative result or 0
                                                    //Overflow is impossible since i/ps are in fp16
    
    //Result selection flags
    wire result_is_nan = A_is_nan | B_is_nan | (A_is_inf & B_is_zero) | (B_is_inf & A_is_zero);
    wire result_is_inf = (A_is_inf & ~B_is_zero) | (B_is_inf & ~A_is_zero);
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
                        final_exp = biased_exp;
                        final_frac = fp32_mantissa;
            end
        endcase
    end

    assign P = {result_sign, final_exp, final_frac};
endmodule
 