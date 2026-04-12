// ============================================================
// Module: control_unit
// FSM cu 6 stari pentru ALU
//
// Intrari:
//   CLK, RST, START, OP[1:0], MUL_RES, DIV_RES
// Iesiri:
//   LOADX, LOADY   - incarca operanzii in registrii interni
//   EN_SUM         - activeaza adder-ul (un ciclu)
//   EN_SUB         - activeaza subtractor-ul (un ciclu)
//   EN_MULT        - porneste booth multiplier (un ciclu)
//   EN_DIV         - porneste restoring divider (un ciclu)
//   DONE           - semnal de clk 1 ciclu: operatia s-a terminat
//
// Starile:
//   S_IDLE     : Asteapta semnalul START.
//   S_LOAD     : Semnaleaza LOADX si LOADY la un ciclu pentru a incarca
//                operanzii A si B in registrii interni regX, regY.
//   S_EXECUTE  : Decodifica OP si seteaza EN-ul corespunzator.
//                - ADD/SUB: rezultat combinational, merge direct in S_DONE.
//                - MUL: aserteza EN_MULT un ciclu, trece in S_WAIT_MUL.
//                - DIV: aserteza EN_DIV un ciclu, trece in S_WAIT_DIV.
//   S_WAIT_MUL : Asteapta semnalul DONE de la booth_multiplier.
//   S_WAIT_DIV : Asteapta semnalul DONE de la restoring_divider_v2.
//   S_DONE     : Seteaza DONE un ciclu, revine in S_IDLE.
// ============================================================
module control_unit (
    input  wire        CLK,
    input  wire        RST,
    input  wire        START,
    input  wire [1:0]  OP,
    input  wire        MUL_RES,
    input  wire        DIV_RES,
    output reg         LOADX,
    output reg         LOADY,
    output reg         EN_SUM,
    output reg         EN_SUB,
    output reg         EN_MULT,
    output reg         EN_DIV,
    output reg         DONE
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

    reg [2:0] state;
    reg [1:0] op_reg;

    always @(posedge CLK) begin
        if (RST) begin
            state   <= S_IDLE;
            op_reg  <= 2'b00;
            LOADX   <= 1'b0;
            LOADY   <= 1'b0;
            EN_SUM  <= 1'b0;
            EN_SUB  <= 1'b0;
            EN_MULT <= 1'b0;
            EN_DIV  <= 1'b0;
            DONE    <= 1'b0;
        end else begin
            LOADX   <= 1'b0;
            LOADY   <= 1'b0;
            EN_SUM  <= 1'b0;
            EN_SUB  <= 1'b0;
            EN_MULT <= 1'b0;
            EN_DIV  <= 1'b0;
            DONE    <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (START) begin
                        op_reg <= OP;
                        state  <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    LOADX <= 1'b1;
                    LOADY <= 1'b1;
                    state <= S_EXECUTE;
                end

                S_EXECUTE: begin
                    case (op_reg)
                        OP_ADD: begin EN_SUM  <= 1'b1; state <= S_DONE;     end
                        OP_SUB: begin EN_SUB  <= 1'b1; state <= S_DONE;     end
                        OP_MUL: begin EN_MULT <= 1'b1; state <= S_WAIT_MUL; end
                        OP_DIV: begin EN_DIV  <= 1'b1; state <= S_WAIT_DIV; end
                    endcase
                end

                S_WAIT_MUL: begin
                    if (MUL_RES) state <= S_DONE;
                end

                S_WAIT_DIV: begin
                    if (DIV_RES) state <= S_DONE;
                end

                S_DONE: begin
                    DONE  <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
