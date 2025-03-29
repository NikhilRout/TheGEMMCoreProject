module fp16add (
    input [15:0] A, B, //fp16 numbers
    output [15:0] S //fp16 number
);
    wire sign_a = A[15];
    wire sign_b = B[15];
    wire [4:0] exp_a = A[14:10];
    wire [4:0] exp_b = B[14:10];
    wire [9:0] frac_a = A[9:0];
    wire [9:0] frac_b = B[9:0];

    //Hidden bits (implied 1)
    wire hidden_a = |exp_a; //0 if exp_a is all zeros (denormal), 1 otherwise
    wire hidden_b = |exp_b;

    //Exceptions/Special Cases
    wire a_is_zero = (~hidden_a) & (~|frac_a); //(exp_a == 5'd0) && (frac_a == 10'd0);
    wire b_is_zero = (~hidden_b) & (~|frac_b);
    wire a_is_inf = (&exp_a) & (~|frac_a); //(exp_a == 5'h1F) && (frac_a == 10'd0);
    wire b_is_inf = (&exp_b) & (~|frac_b);
    wire a_is_nan = (&exp_a) & (|frac_a); //(exp_a == 5'h1F) && (frac_a != 10'd0);
    wire b_is_nan = (&exp_b) & (|frac_b);
    
    //Result selection flags
    wire result_is_nan = a_is_nan | b_is_nan | (a_is_inf & b_is_zero) | (a_is_zero & b_is_inf);
    wire result_is_inf = (a_is_inf & ~b_is_zero) | (b_is_inf & ~a_is_zero);
    wire result_is_zero = a_is_zero & b_is_zero;
    
    reg sign_s;
    reg [4:0] exp_diff, exp_s, exp_ss;
    reg [9:0] mantissa_ss;
    reg [10:0] mantissa_a, mantissa_b;
    reg [11:0] mantissa_s;

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
        if (mantissa_s[11]) begin
            exp_s = exp_s + 1'b1;
            mantissa_s = mantissa_s >> 1;
        end

        //Final result selction
        case({result_is_nan, result_is_inf, result_is_zero})
            3'b100: begin
                        exp_ss = 5'h1F;
                        mantissa_ss = 10'h200;
            end
            3'b010: begin
                        exp_ss = 5'h1F;
                        mantissa_ss = 10'h000;
            end
            3'b001: begin
                        exp_ss = 5'h00;
                        mantissa_ss = 10'h000;
            end
            default: begin
                        exp_ss = exp_s;
                        mantissa_ss = mantissa_s[9:0];
            end
        endcase
    end

    assign S = {sign_s, exp_ss, mantissa_ss};
endmodule
