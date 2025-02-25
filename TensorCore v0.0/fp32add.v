//no support for overflow/NaN

module fp32add (
    input [31:0] A, B, // fp32 numbers
    output [31:0] S // fp32 number
);

    reg A_sign, B_sign, S_sign;
    reg [7:0] A_exp, B_exp, S_exp, exp_diff;
    reg [23:0] A_mantissa, B_mantissa;
    reg [24:0] sum_mantissa;
    integer i;
    
    always @(*) begin
        A_sign = A[31];
        B_sign = B[31];
        A_exp = (A[30:23] == 0) ? 8'b00000001 : A[30:23];
        B_exp = (B[30:23] == 0) ? 8'b00000001 : B[30:23];
        A_mantissa = (A[30:23] == 0) ? {1'b0, A[22:0]} : {1'b1, A[22:0]};
        B_mantissa = (B[30:23] == 0) ? {1'b0, B[22:0]} : {1'b1, B[22:0]};
        
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
        if (sum_mantissa[24]) begin
            S_exp = S_exp + 1'b1;
            sum_mantissa = sum_mantissa >> 1;
        end else begin
            for (i = 0; i < 23 && !sum_mantissa[23]; i = i + 1) begin
                S_exp = S_exp - 1'b1;
                sum_mantissa = sum_mantissa << 1;
            end
        end
    end

    // Assign final result
    assign S[31] = S_sign;
    assign S[30:23] = S_exp;
    assign S[22:0] = sum_mantissa[22:0];
endmodule

/* old normalization that works in sim
        // Normalize result
        if (sum_mantissa[24]) begin
            S_exp = S_exp + 1'b1;
            sum_mantissa = sum_mantissa >> 1;
        end else begin
            while (!sum_mantissa[23] & (S_exp > 0)) begin
                S_exp = S_exp - 1'b1;
                sum_mantissa = sum_mantissa << 1;
            end
        end //else sum_mantissa[23] = 1'b1 so do nothing
*/


/*
module fp32add (
    input [31:0] A, B, //fp32 numbers
    output [31:0] S //fp32 number
);

    wire [7:0] augend_exp, shift, sum_exp;
    wire [23:0] augend_sig, addend_sig, sum_sig; 
    wire carry;

    //augend addend calc
    assign augend_exp = (A[30:23] >= B[30:23]) ? A[30:23] : B[30:23];
    assign shift = (A[30:23] >= B[30:23]) ? (A[30:23] - B[30:23]) : (B[30:23] - A[30:23]);
    assign augend_sig[23] = 1'b1; //hidden bit
    assign augend_sig[22:0] = (A[30:23] >= B[30:23]) ? A[22:0] : B[22:0];
    assign addend_sig[23] = 1'b1;
    assign addend_sig[22:0] = (A[30:23] >= B[30:23]) ? B[22:0] : A[22:0];
    assign addend_sig = addend_sig >> shift;

    //sum calc
    assign {carry, sum_sig} = (A[31] ^ B[31]) ? (augend_sig + addend_sig) : (augend_sig - addend_sig);
    assign S[22:0] = carry ? (sum_sig >> 1) : sum_sig;
    assign S[30:23] = carry ? (augend_exp + 1'b1) : augend_exp;
    assign S[31] = (A[31] ^ B[31]) ? (!(augend_sig >= addend_sig)) : A[31];
endmodule
*/
