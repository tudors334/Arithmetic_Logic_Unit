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
    output reg  [15:0] RESULT,
    output reg         DONE
);
    reg [7:0]  M;
    reg [7:0]  Q;
    reg        Q_prev;
    reg [8:0]  ACC;      // 9 biti pentru a detecta overflow la adunare
    reg [3:0]  count;
    reg        phase;
    reg        running;

    // Adder: ACC[7:0] + M
    wire [7:0] add_result;
    wire       add_cout, add_ov;
    adder_8bit booth_add (
        .A(ACC[7:0]), .B(M), .Cin(1'b0),
        .SUM(add_result), .Cout(add_cout), .Overflow(add_ov)
    );

    // Subtractor: ACC[7:0] - M  
    wire [7:0] sub_result;
    wire       sub_borrow, sub_ov;
    subtractor_8bit booth_sub (
        .A(ACC[7:0]), .B(M),
        .DIFF(sub_result), .Borrow(sub_borrow), .Overflow(sub_ov)
    );

    wire [1:0] booth_bits = {Q[0], Q_prev};

    always @(posedge CLK) begin
        if (RST) begin
            RESULT  <= 16'd0;
            DONE    <= 1'b0;
            running <= 1'b0;
            count   <= 4'd0;
            phase   <= 1'b0;
            ACC     <= 9'd0;
            Q       <= 8'd0;
            Q_prev  <= 1'b0;
            M       <= 8'd0;
        end else begin
            DONE <= 1'b0;

            if (EN && !running) begin
                M       <= A;
                Q       <= B;
                Q_prev  <= 1'b0;
                ACC     <= 9'd0;
                count   <= 4'd0;
                phase   <= 1'b0;
                running <= 1'b1;
            end else if (running) begin
                if (count < 4'd8) begin
                    if (phase == 1'b0) begin
                        // Phase 0: Booth operation
                        case (booth_bits)
                            2'b01: ACC <= {add_result[7], add_result}; // +M
                            2'b10: ACC <= {sub_result[7], sub_result}; // -M
                            default: ;
                        endcase
                        phase <= 1'b1;
                    end else begin
                        // Phase 1: arithmetic right shift {ACC, Q, Q_prev}
                        Q_prev <= Q[0];
                        Q      <= {ACC[0], Q[7:1]};
                        ACC    <= {ACC[8], ACC[8:1]};  
                        count  <= count + 4'd1;
                        phase  <= 1'b0;
                    end
                end else begin
                    RESULT  <= {ACC[7:0], Q};
                    DONE    <= 1'b1;
                    running <= 1'b0;
                end
            end
        end
    end
endmodule