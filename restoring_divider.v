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
    output reg  [7:0]  CAT,
    output reg  [7:0]  REST,
    output reg         DONE,
    output reg         DIV_ZERO
);
    reg [7:0]  Q_reg;
    reg [7:0]  R_reg;
    reg [3:0]  count;
    reg        phase;
    reg        running;

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

    always @(posedge CLK) begin
        if (RST) begin
            CAT       <= 8'd0;
            REST      <= 8'd0;
            DONE      <= 1'b0;
            DIV_ZERO  <= 1'b0;
            running   <= 1'b0;
            count     <= 4'd0;
            phase     <= 1'b0;
            Q_reg     <= 8'd0;
            R_reg     <= 8'd0;
        end else begin
            DONE <= 1'b0;

            if (EN && !running) begin
                if (B == 8'd0) begin
                    CAT       <= 8'hFF;
                    REST      <= 8'hFF;
                    DIV_ZERO  <= 1'b1;
                    DONE      <= 1'b1;
                end else begin
                    Q_reg    <= A;
                    R_reg    <= 8'd0;
                    count    <= 4'd0;
                    phase    <= 1'b0;
                    running  <= 1'b1;
                    DIV_ZERO <= 1'b0;
                end
            end else if (running) begin

                if (count < 4'd8) begin
                    if (phase == 1'b0) begin
                        // ---- Phase 0: shift left {R_reg, Q_reg} ----
                        R_reg <= {R_reg[6:0], Q_reg[7]};
                        Q_reg <= {Q_reg[6:0], 1'b0};
                        phase <= 1'b1;
                    end else begin
                        // ---- Phase 1: subtract / restore ----
                        if (!trial_borrow) begin
                            // R >= D: keep result, quotient bit = 1
                            R_reg    <= trial_diff;
                            Q_reg[0] <= 1'b1;
                        end else begin
                            // R < D: restore, quotient bit = 0
                            R_reg    <= restore_sum;
                            Q_reg[0] <= 1'b0;
                        end
                        count <= count + 4'd1;
                        phase <= 1'b0;
                    end
                end else begin
                    CAT       <= Q_reg;
                    REST      <= R_reg;
                    DONE      <= 1'b1;
                    running   <= 1'b0;
                end

            end
        end
    end
endmodule
