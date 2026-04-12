// ============================================================
// Module: alu_top
// OP: 00=ADD, 01=SUB, 10=MUL(Booth R2 signed C2), 11=DIV(Restoring unsigned)
// ============================================================
module alu_top (
    input  wire        CLK,
    input  wire        RST,
    input  wire        START,
    input  wire [1:0]  OP,
    input  wire [7:0]  A,
    input  wire [7:0]  B,
    output reg  [15:0] RESULT,
    output reg  [7:0]  REMAINDER,
    output reg         CARRY_OUT,
    output reg         OVERFLOW,
    output wire        DONE,
    output wire        DIV_ZERO
);
    wire        LOADX, LOADY;
    wire        EN_SUM, EN_SUB, EN_MULT, EN_DIV;
    wire        mul_done, div_done;

    reg [7:0] regX, regY;
    always @(posedge CLK) begin
        if (RST) begin
            regX <= 8'd0;
            regY <= 8'd0;
        end else begin
            if (LOADX) regX <= A;
            if (LOADY) regY <= B;
        end
    end

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

    reg mul_active;
    reg div_active;
    always @(posedge CLK) begin
        if (RST) begin
            RESULT     <= 16'd0;
            REMAINDER  <= 8'd0;
            CARRY_OUT  <= 1'b0;
            OVERFLOW   <= 1'b0;
            mul_active <= 1'b0;
            div_active <= 1'b0;
        end else begin
            CARRY_OUT <= 1'b0;
            OVERFLOW  <= 1'b0;

            if (EN_SUM) begin
                RESULT     <= {{8{sum_result[7]}}, sum_result};
                REMAINDER  <= 8'd0;
                mul_active <= 1'b0;
                div_active <= 1'b0;
            end

            if (EN_SUB) begin
                RESULT     <= {{8{sub_result[7]}}, sub_result};
                REMAINDER  <= 8'd0;
                mul_active <= 1'b0;
                div_active <= 1'b0;
            end

            if (EN_MULT) begin
                mul_active <= 1'b1;
                div_active <= 1'b0;
            end

            if (EN_DIV) begin
                div_active <= 1'b1;
                mul_active <= 1'b0;
            end

            if (mul_active && mul_done) begin
                RESULT     <= mul_result;
                REMAINDER  <= 8'd0;
                mul_active <= 1'b0;
            end

            if (div_active && div_done) begin
                RESULT     <= {8'd0, div_cat};
                REMAINDER  <= div_rest;
                div_active <= 1'b0;
            end
        end
    end
endmodule