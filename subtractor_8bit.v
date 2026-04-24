// subtractor_8bit: scazator pe 8 biti (A - B).
// Implementat ca A + (~B) + 1 (complement fata de 2).
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
