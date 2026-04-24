// control_unit: un FSM mic care orchestreaza operatia ALU.
// Pe scurt: la START prinde OP, incarca A/B in registre, apoi porneste blocul cerut.
// Pentru ADD/SUB nu asteapta (rezultatul e combinational), pentru MUL/DIV sta pana
// primeste semnalul de final de la modulul respectiv.
//
// Intrari:
//   CLK, RST, START, OP[1:0], MUL_RES, DIV_RES
// Iesiri:
//   LOADX, LOADY  - incarca operanzii in registrele interne
//   EN_SUM/EN_SUB - pulse de 1 ciclu pentru add/sub
//   EN_MULT/EN_DIV- pulse de 1 ciclu care pornesc mul/div
//   DONE          - 1 ciclu cand operatia s-a incheiat
//
// Stari (pe inteles):
//   S_IDLE     asteapta START
//   S_LOAD     pulseaza LOADX/LOADY ca sa prinda A/B
//   S_EXECUTE  decide dupa OP: direct DONE (ADD/SUB) sau WAIT (MUL/DIV)
//   S_WAIT_*   asteapta MUL_RES / DIV_RES
//   S_DONE     pulseaza DONE si revine in IDLE
module control_unit (
    input  wire        CLK,
    input  wire        RST,
    input  wire        START,
    input  wire [1:0]  OP,
    input  wire        MUL_RES,
    input  wire        DIV_RES,
    output wire        LOADX,
    output wire        LOADY,
    output wire        EN_SUM,
    output wire        EN_SUB,
    output wire        EN_MULT,
    output wire        EN_DIV,
    output wire        DONE
);
    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_MUL = 2'b10;
    localparam OP_DIV = 2'b11;

    localparam [2:0]
        S_IDLE      = 3'd0,
        S_LOAD      = 3'd1,
        S_EXECUTE   = 3'd2,
        S_WAIT_MUL  = 3'd3,
        S_WAIT_DIV  = 3'd4,
        S_DONE      = 3'd5;

    wire [2:0] state_q;
    wire [2:0] state_next;
    reg_en #(.W(3)) state_reg (
        .CLK(CLK), .RST(RST), .EN(1'b1),
        .D(state_next), .Q(state_q)
    );

    wire [1:0] op_q;
    wire [1:0] op_next;
    reg_en #(.W(2)) op_reg (
        .CLK(CLK), .RST(RST), .EN(1'b1),
        .D(op_next), .Q(op_q)
    );

    assign op_next = (state_q == S_IDLE && START) ? OP : op_q;

    assign state_next =
        (state_q == S_IDLE)     ? (START ? S_LOAD : S_IDLE) :
        (state_q == S_LOAD)     ? S_EXECUTE :
        (state_q == S_EXECUTE)  ? ((op_q == OP_ADD || op_q == OP_SUB) ? S_DONE :
                                  (op_q == OP_MUL ? S_WAIT_MUL : S_WAIT_DIV)) :
        (state_q == S_WAIT_MUL) ? (MUL_RES ? S_DONE : S_WAIT_MUL) :
        (state_q == S_WAIT_DIV) ? (DIV_RES ? S_DONE : S_WAIT_DIV) :
        (state_q == S_DONE)     ? S_IDLE :
        S_IDLE;

    assign LOADX   = (state_q == S_LOAD);
    assign LOADY   = (state_q == S_LOAD);
    assign EN_SUM  = (state_q == S_EXECUTE && op_q == OP_ADD);
    assign EN_SUB  = (state_q == S_EXECUTE && op_q == OP_SUB);
    assign EN_MULT = (state_q == S_EXECUTE && op_q == OP_MUL);
    assign EN_DIV  = (state_q == S_EXECUTE && op_q == OP_DIV);
    assign DONE    = (state_q == S_DONE);
endmodule
