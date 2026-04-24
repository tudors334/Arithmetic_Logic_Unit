// alu_top = "ambalajul" ALU-ului: incarca A/B in registre si alege blocul potrivit.
// OP:
//   00 -> ADD (C2 signed)
//   01 -> SUB (C2 signed)
//   10 -> MUL (Booth radix-2, signed)
//   11 -> DIV (Restoring, unsigned)
module alu_top (
    input  wire        CLK,
    input  wire        RST,
    input  wire        START,
    input  wire [1:0]  OP,
    input  wire [7:0]  A,
    input  wire [7:0]  B,
    output wire [15:0] RESULT,
    output wire [7:0]  REMAINDER,
    output wire        CARRY_OUT,
    output wire        OVERFLOW,
    output wire        DONE,
    output wire        DIV_ZERO
);
    wire        LOADX, LOADY;
    wire        EN_SUM, EN_SUB, EN_MULT, EN_DIV;
    wire        mul_done, div_done;

    wire [7:0] regX;
    wire [7:0] regY;
    reg_en #(.W(8)) reg_x (
        .CLK(CLK), .RST(RST), .EN(LOADX),
        .D(A), .Q(regX)
    );
    reg_en #(.W(8)) reg_y (
        .CLK(CLK), .RST(RST), .EN(LOADY),
        .D(B), .Q(regY)
    );

    control_unit cu (
        .CLK    (CLK),     .RST    (RST),
        .START  (START),   .OP     (OP),
        .MUL_RES(mul_done),.DIV_RES(div_done),
        .LOADX  (LOADX),   .LOADY  (LOADY),
        .EN_SUM (EN_SUM),  .EN_SUB (EN_SUB),
        .EN_MULT(EN_MULT), .EN_DIV (EN_DIV),
        .DONE   (DONE)
    );

    wire [7:0] sum_result;
    wire       sum_cout, sum_ov;
    adder_8bit adder_inst (
        .A(regX), .B(regY), .Cin(1'b0),
        .SUM(sum_result), .Cout(sum_cout), .Overflow(sum_ov)
    );

    wire [7:0] sub_result;
    wire       sub_borrow, sub_ov;
    subtractor_8bit sub_inst (
        .A(regX), .B(regY),
        .DIFF(sub_result), .Borrow(sub_borrow), .Overflow(sub_ov)
    );

    wire [15:0] mul_result;
    booth_multiplier mul_inst (
        .CLK(CLK), .RST(RST), .EN(EN_MULT),
        .A(regX), .B(regY),
        .RESULT(mul_result), .DONE(mul_done)
    );

    wire [7:0] div_cat, div_rest;
    restoring_divider_v2 div_inst (
        .CLK(CLK), .RST(RST), .EN(EN_DIV),
        .A(regX), .B(regY),
        .CAT(div_cat), .REST(div_rest),
        .DONE(div_done), .DIV_ZERO(DIV_ZERO)
    );

    wire [15:0] result_q;
    wire [7:0]  remainder_q;
    wire        mul_active_q;
    wire        div_active_q;

    wire [15:0] result_next;
    wire [7:0]  remainder_next;
    wire        mul_active_next;
    wire        div_active_next;

    assign result_next =
        EN_SUM ? {{8{sum_result[7]}}, sum_result} :
        EN_SUB ? {{8{sub_result[7]}}, sub_result} :
        (mul_active_q && mul_done) ? mul_result :
        (div_active_q && div_done) ? {8'd0, div_cat} :
        result_q;

    assign remainder_next =
        (EN_SUM || EN_SUB) ? 8'd0 :
        (div_active_q && div_done) ? div_rest :
        remainder_q;

    assign mul_active_next =
        (EN_SUM || EN_SUB) ? 1'b0 :
        EN_MULT ? 1'b1 :
        EN_DIV ? 1'b0 :
        (mul_active_q && mul_done) ? 1'b0 :
        mul_active_q;

    assign div_active_next =
        (EN_SUM || EN_SUB) ? 1'b0 :
        EN_DIV ? 1'b1 :
        EN_MULT ? 1'b0 :
        (div_active_q && div_done) ? 1'b0 :
        div_active_q;

    reg_en #(.W(16)) result_reg (
        .CLK(CLK), .RST(RST), .EN(1'b1),
        .D(result_next), .Q(result_q)
    );
    reg_en #(.W(8)) remainder_reg (
        .CLK(CLK), .RST(RST), .EN(1'b1),
        .D(remainder_next), .Q(remainder_q)
    );
    reg_en #(.W(1)) mul_active_reg (
        .CLK(CLK), .RST(RST), .EN(1'b1),
        .D(mul_active_next), .Q(mul_active_q)
    );
    reg_en #(.W(1)) div_active_reg (
        .CLK(CLK), .RST(RST), .EN(1'b1),
        .D(div_active_next), .Q(div_active_q)
    );

    assign RESULT    = result_q;
    assign REMAINDER = remainder_q;
    assign CARRY_OUT = 1'b0;
    assign OVERFLOW  = 1'b0;
endmodule