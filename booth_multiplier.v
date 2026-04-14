// ============================================================
// Module: booth_multiplier
// Algoritm: Booth Radix-2 
// Intrari: A, B  (8-bit signed C2)
// Iesire : RESULT (16-bit signed C2)
//
// Algoritmul Booth Radix-2:
//   Initializam ACC=0, Q=B (multiplier), Q_prev=0.
//   La fiecare din cele 8 pasi examinam perechea (Q[0], Q_prev):
//     01        -> ACC = ACC + M   (M = A, multiplicand)
//     10        -> ACC = ACC - M   (folosim subtractor_8bit)
//   Dupa operatie, shift aritmetic dreapta {ACC, Q, Q_prev} cu 1.
//   Rezultat final: {ACC[7:0], Q} = produs pe 16 biti (C2).
//
// Implementare: doua faze per pas:
//   Phase 0: operatia Booth pe ACC
//   Phase 1: shift aritmetic dreapta
// ============================================================
module booth_multiplier (
    input  wire        CLK,
    input  wire        RST,
    input  wire        EN,
    input  wire [7:0]  A,        // multiplicand (signed C2)
    input  wire [7:0]  B,        // multiplier   (signed C2)
    output wire [15:0] RESULT,
    output wire        DONE
);
    wire [7:0]  M_q;
    wire [7:0]  Q_q;
    wire        Q_prev_q;
    wire [8:0]  ACC_q;      // 9 biti pentru a detecta overflow la adunare
    wire [3:0]  count_q;
    wire        phase_q;
    wire        running_q;

    // Adder: ACC[7:0] + M
    wire [7:0] add_result;
    wire       add_cout, add_ov;
    adder_8bit booth_add (
        .A(ACC_q[7:0]), .B(M_q), .Cin(1'b0),
        .SUM(add_result), .Cout(add_cout), .Overflow(add_ov)
    );

    // Subtractor: ACC[7:0] - M  
    wire [7:0] sub_result;
    wire       sub_borrow, sub_ov;
    subtractor_8bit booth_sub (
        .A(ACC_q[7:0]), .B(M_q),
        .DIFF(sub_result), .Borrow(sub_borrow), .Overflow(sub_ov)
    );

    wire [1:0] booth_bits = {Q_q[0], Q_prev_q};

    wire start  = EN && !running_q;
    wire step   = running_q && (count_q < 4'd8);
    wire phase0 = step && (phase_q == 1'b0);
    wire phase1 = step && (phase_q == 1'b1);
    wire finish = running_q && (count_q >= 4'd8);

    wire [7:0]  M_next;
    wire [7:0]  Q_next;
    wire        Q_prev_next;
    wire [8:0]  ACC_next;
    wire [3:0]  count_next;
    wire        phase_next;
    wire        running_next;
    wire [15:0] result_next;
    wire        done_next;

    assign M_next = start ? A : M_q;

    assign Q_next = start ? B :
                    (phase1 ? {ACC_q[0], Q_q[7:1]} : Q_q);

    assign Q_prev_next = start ? 1'b0 :
                         (phase1 ? Q_q[0] : Q_prev_q);

    assign ACC_next = start ? 9'd0 :
                      (phase0 ?
                          ((booth_bits == 2'b01) ? {add_result[7], add_result} :
                           (booth_bits == 2'b10) ? {sub_result[7], sub_result} :
                           ACC_q) :
                       (phase1 ? {ACC_q[8], ACC_q[8:1]} : ACC_q));

    assign count_next = start ? 4'd0 :
                        (phase1 ? (count_q + 4'd1) : count_q);

    assign phase_next = start ? 1'b0 :
                        (phase0 ? 1'b1 :
                         (phase1 ? 1'b0 : phase_q));

    assign running_next = start ? 1'b1 :
                          (finish ? 1'b0 : running_q);

    assign result_next = finish ? {ACC_q[7:0], Q_q} : RESULT;
    assign done_next   = finish ? 1'b1 : 1'b0;

    reg_en #(.W(8))  reg_m      (.CLK(CLK), .RST(RST), .EN(1'b1), .D(M_next),      .Q(M_q));
    reg_en #(.W(8))  reg_q      (.CLK(CLK), .RST(RST), .EN(1'b1), .D(Q_next),      .Q(Q_q));
    reg_en #(.W(1))  reg_q_prev (.CLK(CLK), .RST(RST), .EN(1'b1), .D(Q_prev_next), .Q(Q_prev_q));
    reg_en #(.W(9))  reg_acc    (.CLK(CLK), .RST(RST), .EN(1'b1), .D(ACC_next),    .Q(ACC_q));
    reg_en #(.W(4))  reg_count  (.CLK(CLK), .RST(RST), .EN(1'b1), .D(count_next),  .Q(count_q));
    reg_en #(.W(1))  reg_phase  (.CLK(CLK), .RST(RST), .EN(1'b1), .D(phase_next),  .Q(phase_q));
    reg_en #(.W(1))  reg_run    (.CLK(CLK), .RST(RST), .EN(1'b1), .D(running_next),.Q(running_q));
    reg_en #(.W(16)) reg_res    (.CLK(CLK), .RST(RST), .EN(1'b1), .D(result_next), .Q(RESULT));
    reg_en #(.W(1))  reg_done   (.CLK(CLK), .RST(RST), .EN(1'b1), .D(done_next),   .Q(DONE));
endmodule