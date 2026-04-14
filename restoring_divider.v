// ============================================================
// Module: restoring_divider_v2
// Description: 8-bit unsigned Restoring Division
// Uses subtractor_8bit (trial) and adder_8bit (restore).
//
// Two phases per bit:
//   Phase 0: shift left {R, Q_reg} by 1
//   Phase 1: trial subtract R-D; if no borrow keep & Q[0]=1
//                              ; if borrow restore & Q[0]=0
// ============================================================
module restoring_divider_v2 (
    input  wire        CLK,
    input  wire        RST,
    input  wire        EN,
    input  wire [7:0]  A,           // dividend
    input  wire [7:0]  B,           // divisor
    output wire [7:0]  CAT,
    output wire [7:0]  REST,
    output wire        DONE,
    output wire        DIV_ZERO
);
    wire [7:0]  Q_reg;
    wire [7:0]  R_reg;
    wire [3:0]  count;
    wire        phase;
    wire        running;

    // ---- Trial subtraction: R_reg - B ----
    wire [7:0] trial_diff;
    wire       trial_borrow, trial_ov;
    subtractor_8bit trial_sub (
        .A(R_reg), .B(B),
        .DIFF(trial_diff), .Borrow(trial_borrow), .Overflow(trial_ov)
    );

    // ---- Restore: trial_diff + B ----
    wire [7:0] restore_sum;
    wire       restore_cout, restore_ov;
    adder_8bit restore_add (
        .A(trial_diff), .B(B), .Cin(1'b0),
        .SUM(restore_sum), .Cout(restore_cout), .Overflow(restore_ov)
    );

    wire start      = EN && !running;
    wire start_div0 = start && (B == 8'd0);
    wire start_ok   = start && (B != 8'd0);

    wire step   = running && (count < 4'd8);
    wire phase0 = step && (phase == 1'b0);
    wire phase1 = step && (phase == 1'b1);
    wire finish = running && (count >= 4'd8);

    wire [7:0] Q_next;
    wire [7:0] R_next;
    wire [3:0] count_next;
    wire       phase_next;
    wire       running_next;
    wire [7:0] cat_next;
    wire [7:0] rest_next;
    wire       done_next;
    wire       div_zero_next;

    wire q_bit0 = !trial_borrow;
    wire [7:0] r_after_sub = !trial_borrow ? trial_diff : restore_sum;

    assign Q_next = start_ok ? A :
                    (phase0 ? {Q_reg[6:0], 1'b0} :
                     (phase1 ? {Q_reg[7:1], q_bit0} : Q_reg));

    assign R_next = start_ok ? 8'd0 :
                    (phase0 ? {R_reg[6:0], Q_reg[7]} :
                     (phase1 ? r_after_sub : R_reg));

    assign count_next = start ? 4'd0 :
                        (phase1 ? (count + 4'd1) : count);

    assign phase_next = start ? 1'b0 :
                        (phase0 ? 1'b1 :
                         (phase1 ? 1'b0 : phase));

    assign running_next = start_ok ? 1'b1 :
                          (finish ? 1'b0 : running);

    assign cat_next = start_div0 ? 8'hFF :
                      (finish ? Q_reg : CAT);

    assign rest_next = start_div0 ? 8'hFF :
                       (finish ? R_reg : REST);

    assign done_next = (start_div0 || finish) ? 1'b1 : 1'b0;

    assign div_zero_next = start_div0 ? 1'b1 :
                           (start_ok ? 1'b0 : DIV_ZERO);

    reg_en #(.W(8))  reg_q      (.CLK(CLK), .RST(RST), .EN(1'b1), .D(Q_next),       .Q(Q_reg));
    reg_en #(.W(8))  reg_r      (.CLK(CLK), .RST(RST), .EN(1'b1), .D(R_next),       .Q(R_reg));
    reg_en #(.W(4))  reg_count  (.CLK(CLK), .RST(RST), .EN(1'b1), .D(count_next),  .Q(count));
    reg_en #(.W(1))  reg_phase  (.CLK(CLK), .RST(RST), .EN(1'b1), .D(phase_next),  .Q(phase));
    reg_en #(.W(1))  reg_run    (.CLK(CLK), .RST(RST), .EN(1'b1), .D(running_next),.Q(running));
    reg_en #(.W(8))  reg_cat    (.CLK(CLK), .RST(RST), .EN(1'b1), .D(cat_next),    .Q(CAT));
    reg_en #(.W(8))  reg_rest   (.CLK(CLK), .RST(RST), .EN(1'b1), .D(rest_next),   .Q(REST));
    reg_en #(.W(1))  reg_done   (.CLK(CLK), .RST(RST), .EN(1'b1), .D(done_next),   .Q(DONE));
    reg_en #(.W(1))  reg_div0   (.CLK(CLK), .RST(RST), .EN(1'b1), .D(div_zero_next), .Q(DIV_ZERO));
endmodule
