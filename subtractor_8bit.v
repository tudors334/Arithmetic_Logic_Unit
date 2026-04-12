// ============================================================
// Module: subtractor_8bit
// Description: 8-bit Subtractor A - B
//              Implemented as A + (~B) + 1  
// Inputs : A[7:0], B[7:0]
// Outputs: DIFF[7:0], Borrow, Overflow
// ============================================================
module subtractor_8bit (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [7:0] DIFF,
    output wire       Borrow,
    output wire       Overflow
);
    wire [7:0] B_inv;
    wire       Cout;

    assign B_inv = ~B; 

    // A + (~B) + 1  
    adder_8bit sub_adder (
        .A       (A),
        .B       (B_inv),
        .Cin     (1'b1),
        .SUM     (DIFF),
        .Cout    (Cout),
        .Overflow(Overflow)
    );

    assign Borrow = ~Cout;
endmodule
