//no support for overflow/NaN

module fp64add (
    input [63:0] A, B, // fp64 numbers
    output [63:0] S // fp64 number
);

    reg A_sign, B_sign, S_sign;
    reg [10:0] A_exp, B_exp, S_exp, exp_diff;
    reg [52:0] A_mantissa, B_mantissa;
    reg [53:0] sum_mantissa;
    integer i;
    
    always @(*) begin
        A_sign = A[63];
        B_sign = B[63];
        A_exp = (A[62:52] == 0) ? 11'b00000000001 : A[62:52];
        B_exp = (B[62:52] == 0) ? 11'b00000000001 : B[62:52];
        A_mantissa = (A[62:52] == 0) ? {1'b0, A[51:0]} : {1'b1, A[51:0]};
        B_mantissa = (B[62:52] == 0) ? {1'b0, B[51:0]} : {1'b1, B[51:0]};
        
        // Align mantissas based on exponents
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

        // Perform addition or subtraction based on sign
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

        // Normalize result using a for loop to ensure bounded iterations
        if (sum_mantissa[53]) begin
            S_exp = S_exp + 1'b1;
            sum_mantissa = sum_mantissa >> 1;
        end else begin
            for (i = 0; i < 52 && !sum_mantissa[52]; i = i + 1) begin
                S_exp = S_exp - 1'b1;
                sum_mantissa = sum_mantissa << 1;
            end
        end
    end

    assign S[63] = S_sign;
    assign S[62:52] = S_exp;
    assign S[51:0] = sum_mantissa[51:0];
endmodule
