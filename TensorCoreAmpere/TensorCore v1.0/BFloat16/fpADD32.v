module fpADD32 (
    input [31:0] A, B, //fp32 numbers
    output [31:0] S //fp32 number
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
    wire a_is_zero = (~hidden_a) & (~|frac_a); //(exp_a == 8'd0) && (frac_a == 23'd0);
    wire b_is_zero = (~hidden_b) & (~|frac_b);
    wire a_is_inf = (&exp_a) & (~|frac_a); //(exp_a == 8'hFF) && (frac_a == 23'd0);
    wire b_is_inf = (&exp_b) & (~|frac_b);
    wire a_is_nan = (&exp_a) & (|frac_a); //(exp_a == 8'hFF) && (frac_a != 23'd0);
    wire b_is_nan = (&exp_b) & (|frac_b);
    
    //Result selection flags
    wire result_is_nan = a_is_nan | b_is_nan | (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);
    wire result_is_inf = (a_is_inf & ~b_is_zero) | (b_is_inf & ~a_is_zero);
    wire result_is_zero = a_is_zero & b_is_zero;
    
    reg sign_s;
    reg [7:0] exp_diff, exp_s, exp_ss;
    reg [22:0] mantissa_ss;
    reg [23:0] mantissa_a, mantissa_b;
    reg [24:0] mantissa_s;

    always @(*) begin
        mantissa_a = {hidden_a, frac_a};
        mantissa_b = {hidden_b, frac_b};

        //Align mantissas based on exponents
        if (exp_a >= exp_b) begin
            exp_diff = exp_a - exp_b;
            mantissa_b = mantissa_b >> exp_diff;
            exp_s = exp_a;
        end else begin
            exp_diff = exp_b - exp_a;
            mantissa_a = mantissa_a >> exp_diff;
            exp_s = exp_b;
        end

        //Perform addition or subtraction based on sign
        if (sign_a ~^ sign_b) begin
            mantissa_s = mantissa_a + mantissa_b;
            sign_s = sign_a;
        end else begin
            if (mantissa_a > mantissa_b) begin
                mantissa_s = mantissa_a - mantissa_b;
                sign_s = sign_a;
            end else begin
                mantissa_s = mantissa_b - mantissa_a;
                sign_s = sign_b;
            end            
        end

        //Normalization
        if (mantissa_s[24]) begin
            exp_s = exp_s + 1'b1;
            mantissa_s = mantissa_s >> 1;
        end

        //Final result selction
        case({result_is_nan, result_is_inf, result_is_zero})
            3'b100: begin
                        exp_ss = 8'hFF;
                        mantissa_ss = 23'h400000;
            end
            3'b010: begin
                        exp_ss = 8'hFF;
                        mantissa_ss = 23'h000000;
            end
            3'b001: begin
                        exp_ss = 8'h00;
                        mantissa_ss = 23'h000000;
            end
            default: begin
                        exp_ss = exp_s;
                        mantissa_ss = mantissa_s[22:0];
            end
        endcase
    end

    assign S = {sign_s, exp_ss, mantissa_ss};
endmodule

/*
    wire [7:0] exp_ss = result_is_nan ? 8'hFF :
                    result_is_inf ? 8'hFF :
                    result_is_zero ? 8'h00 :
                    exp_s;
    wire [22:0] mantissa_ss = result_is_nan ? 23'h400000 :
                    result_is_inf ? 23'h000000 :
                    result_is_zero ? 23'h000000 :
                    mantissa_s [22:0];
*/

/*
module fpADD32 (
    input [31:0] A, B, //fp32 numbers
    output [31:0] S //fp32 number
);

    reg A_sign, B_sign, S_sign;
    reg [7:0] A_exp, B_exp, S_exp, exp_diff;
    reg [23:0] A_mantissa, B_mantissa;
    reg [24:0] sum_mantissa;
    reg [4:0] zeros;
    
    always @(*) begin
        A_sign = A[31];
        B_sign = B[31];
        A_exp = (A[30:23] == 0) ? 8'b00000001 : A[30:23];
        B_exp = (B[30:23] == 0) ? 8'b00000001 : B[30:23];
        A_mantissa = (A[30:23] == 0) ? {1'b0, A[22:0]} : {1'b1, A[22:0]};
        B_mantissa = (B[30:23] == 0) ? {1'b0, B[22:0]} : {1'b1, B[22:0]};
        
        //Align mantissas based on exponents
        if (A_exp > B_exp) begin
            exp_diff = A_exp - B_exp;
            B_mantissa = B_mantissa >> exp_diff;
            S_exp = A_exp;
            S_sign = A_sign;
        end else begin
            exp_diff = B_exp - A_exp;
            A_mantissa = A_mantissa >> exp_diff;
            S_exp = B_exp;
            S_sign = B_sign;
        end

        //Perform addition or subtraction based on sign
        if (A_sign == B_sign) begin
            sum_mantissa = A_mantissa + B_mantissa;
            S_sign = A_sign;
        end else begin
            if (A_mantissa > B_mantissa) begin
                sum_mantissa = A_mantissa - B_mantissa;
                S_sign = A_sign;
            end else begin
                sum_mantissa = B_mantissa - A_mantissa;
                S_sign = B_sign;
            end
        end

        if (sum_mantissa[24]) begin
            S_exp = S_exp + 1'b1;
            sum_mantissa = sum_mantissa >> 1;
        end else begin
            casez (sum_mantissa[23:0])
                24'b1???????????????????????: zeros = 5'd0;
                24'b01??????????????????????: zeros = 5'd1;
                24'b001?????????????????????: zeros = 5'd2;
                24'b0001????????????????????: zeros = 5'd3;
                24'b00001???????????????????: zeros = 5'd4;
                24'b000001??????????????????: zeros = 5'd5;
                24'b0000001?????????????????: zeros = 5'd6;
                24'b00000001????????????????: zeros = 5'd7;
                24'b000000001???????????????: zeros = 5'd8;
                24'b0000000001??????????????: zeros = 5'd9;
                24'b00000000001?????????????: zeros = 5'd10;
                24'b000000000001????????????: zeros = 5'd11;
                24'b0000000000001???????????: zeros = 5'd12;
                24'b00000000000001??????????: zeros = 5'd13;
                24'b000000000000001?????????: zeros = 5'd14;
                24'b0000000000000001????????: zeros = 5'd15;
                24'b00000000000000001???????: zeros = 5'd16;
                24'b000000000000000001??????: zeros = 5'd17;
                24'b0000000000000000001?????: zeros = 5'd18;
                24'b00000000000000000001????: zeros = 5'd19;
                24'b000000000000000000001???: zeros = 5'd20;
                24'b0000000000000000000001??: zeros = 5'd21;
                24'b00000000000000000000001?: zeros = 5'd22;
                24'b000000000000000000000001: zeros = 5'd23;
                24'b000000000000000000000000: zeros = 5'd24;
            endcase
            S_exp = S_exp - zeros;
            sum_mantissa = sum_mantissa >> zeros;
        end
    end

    assign S[31] = S_sign;
    assign S[30:23] = S_exp;
    assign S[22:0] = sum_mantissa[22:0];
endmodule

module fpADD32 (
    input [31:0] A, B, //fp32 numbers
    output [31:0] S //fp32 number
);
    // Extract fields
    wire sign_a = A[31];
    wire sign_b = B[31];
    wire [7:0] exp_a = A[30:23];
    wire [7:0] exp_b = B[30:23];
    wire [22:0] frac_a = A[22:0];
    wire [22:0] frac_b = B[22:0];
    
    // Hidden bits (implied 1)
    wire hidden_a = |exp_a; // 0 if exp_a is all zeros (denormal), 1 otherwise
    wire hidden_b = |exp_b;
    
    // Exceptions/Special Cases
    wire a_is_zero = (~hidden_a) & (~|frac_a);
    wire b_is_zero = (~hidden_b) & (~|frac_b);
    wire a_is_inf = (&exp_a) & (~|frac_a);
    wire b_is_inf = (&exp_b) & (~|frac_b);
    wire a_is_nan = (&exp_a) & (|frac_a);
    wire b_is_nan = (&exp_b) & (|frac_b);
    
    // Determine effective operation (add/subtract)
    wire effective_subtraction = sign_a ^ sign_b;
    
    // Full mantissas including hidden bit
    wire [23:0] full_frac_a = {hidden_a, frac_a};
    wire [23:0] full_frac_b = {hidden_b, frac_b};
    
    // Exponent comparison and alignment
    wire [7:0] exp_diff_a_b = (exp_a > exp_b) ? (exp_a - exp_b) : 8'b0;
    wire [7:0] exp_diff_b_a = (exp_b > exp_a) ? (exp_b - exp_a) : 8'b0;
    wire use_a = (exp_a > exp_b) | ((exp_a == exp_b) & (full_frac_a >= full_frac_b));
    wire [7:0] larger_exp = use_a ? exp_a : exp_b;
    
    // Align mantissas - shift the smaller number's mantissa right
    wire [23:0] aligned_frac_a = use_a ? full_frac_a : (full_frac_a >> exp_diff_b_a);
    wire [23:0] aligned_frac_b = use_a ? (full_frac_b >> exp_diff_a_b) : full_frac_b;
    // Addition/subtraction of mantissas
    wire [24:0] add_result = aligned_frac_a + aligned_frac_b;
    wire [24:0] sub_result = use_a ? 
                            {1'b0, aligned_frac_a} - {1'b0, aligned_frac_b} : 
                            {1'b0, aligned_frac_b} - {1'b0, aligned_frac_a};
    wire [24:0] sum_mantissa = effective_subtraction ? sub_result : add_result;

    // Result sign
    wire sign_result = effective_subtraction ? 
                     (use_a ? sign_a : sign_b) : 
                     sign_a;

    // Leading zero detection for normalization
    wire [4:0] leading_zeros;
    leading_zero_detector lzd(.mantissa(sum_mantissa[23:0]), .zeros(leading_zeros));
    // Normalization
    wire overflow = sum_mantissa[24];
    wire [7:0] norm_shift = overflow ? 8'd1 : leading_zeros;
    wire [24:0] normalized_mantissa = overflow ? 
                                    sum_mantissa[24:0] >> 1 : 
                                    {sum_mantissa[23:0], 1'b0} << leading_zeros;
    
    // Exponent adjustment
    wire [8:0] exp_adjust = {1'b0, larger_exp} + (overflow ? 9'd1 : -{{4{1'b0}}, leading_zeros});
    wire underflow = exp_adjust[8] | (~|exp_adjust[7:0]); // Negative or zero
    wire [7:0] adjusted_exp = underflow ? 8'h00 : exp_adjust[7:0];
    // Check for overflow in exponent
    wire exp_overflow = !exp_adjust[8] & (&exp_adjust[7:0]); // Postive and >= 255

    // Special cases result handling
    wire result_is_nan = a_is_nan | b_is_nan | 
                      (a_is_inf & b_is_inf & effective_subtraction);
    wire result_is_inf = (a_is_inf & ~(b_is_inf & effective_subtraction)) | 
                      (b_is_inf & ~(a_is_inf & effective_subtraction)) |
                      exp_overflow;
    wire result_is_zero = (a_is_zero & b_is_zero) | 
                       (~|normalized_mantissa[23:0] & ~overflow);
    
    // Final results
    wire [7:0] exp_final = result_is_nan ? 8'hFF : 
                        result_is_inf ? 8'hFF : 
                        result_is_zero ? 8'h00 : 
                        adjusted_exp;
    wire [22:0] frac_final = result_is_nan ? 23'h400000 : // Canonical NaN
                          result_is_inf ? 23'h000000 : 
                          result_is_zero ? 23'h000000 : 
                          normalized_mantissa[22:0];
    
    // Final output
    assign S = {sign_result, exp_final, frac_final};
endmodule

// Leading Zero Detector for 24-bit input
module leading_zero_detector (
    input [23:0] mantissa,
    output reg [4:0] zeros
);
    always @(*) begin
        casez (mantissa)
            24'b1???????????????????????: zeros = 5'd0;
            24'b01??????????????????????: zeros = 5'd1;
            24'b001?????????????????????: zeros = 5'd2;
            24'b0001????????????????????: zeros = 5'd3;
            24'b00001???????????????????: zeros = 5'd4;
            24'b000001??????????????????: zeros = 5'd5;
            24'b0000001?????????????????: zeros = 5'd6;
            24'b00000001????????????????: zeros = 5'd7;
            24'b000000001???????????????: zeros = 5'd8;
            24'b0000000001??????????????: zeros = 5'd9;
            24'b00000000001?????????????: zeros = 5'd10;
            24'b000000000001????????????: zeros = 5'd11;
            24'b0000000000001???????????: zeros = 5'd12;
            24'b00000000000001??????????: zeros = 5'd13;
            24'b000000000000001?????????: zeros = 5'd14;
            24'b0000000000000001????????: zeros = 5'd15;
            24'b00000000000000001???????: zeros = 5'd16;
            24'b000000000000000001??????: zeros = 5'd17;
            24'b0000000000000000001?????: zeros = 5'd18;
            24'b00000000000000000001????: zeros = 5'd19;
            24'b000000000000000000001???: zeros = 5'd20;
            24'b0000000000000000000001??: zeros = 5'd21;
            24'b00000000000000000000001?: zeros = 5'd22;
            24'b000000000000000000000001: zeros = 5'd23;
            24'b000000000000000000000000: zeros = 5'd24;
        endcase
    end
endmodule
*/
