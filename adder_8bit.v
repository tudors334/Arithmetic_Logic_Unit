// adder_8bit: adunator ripple-carry pe 8 biti.
// Intrari: A, B, Cin. Iesiri: SUM, Cout, Overflow.
module adder_8bit (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire       Cin,
    output wire [7:0] SUM,
    output wire       Cout,
    output wire       Overflow
);
    wire [8:0] carry; // carry[0] = Cin, carry[8] = Cout

    assign carry[0] = Cin;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : fa_chain
            full_adder fa (
                .a   (A[i]),
                .b   (B[i]),
                .cin (carry[i]),
                .sum (SUM[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    assign Cout     = carry[8];
    assign Overflow = carry[7] ^ carry[8];
endmodule
