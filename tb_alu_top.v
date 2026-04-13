`timescale 1ns/1ps

module tb_alu_top;
    reg         CLK, RST, START;
    reg  [1:0]  OP;
    reg  [7:0]  A, B;
    wire [15:0] RESULT;
    wire [7:0]  REST;
    wire        CARRY_OUT, OVERFLOW, DONE, DIV_ZERO;

    alu_top dut (
        .CLK(CLK), .RST(RST), .START(START), .OP(OP),
        .A(A), .B(B),
        .RESULT(RESULT), .REMAINDER(REST),
        .CARRY_OUT(CARRY_OUT), .OVERFLOW(OVERFLOW),
        .DONE(DONE), .DIV_ZERO(DIV_ZERO)
    );

    initial CLK = 0;
    always #5 CLK = ~CLK;

    reg [15:0] r_result;
    reg [7:0]  r_rest;
    reg        r_divz;

    task print_bin8;
        input [7:0] v;
        integer k;
        begin
            for (k=7; k>=0; k=k-1) $write("%b", v[k]);
        end
    endtask

    task print_bin16;
        input [15:0] v;
        integer k;
        begin
            for (k=15; k>=0; k=k-1) $write("%b", v[k]);
        end
    endtask

    task show_signed8;
        input [7:0] v;
        begin
            if (v[7] == 1'b1)
                $write("-%0d", ((~v) + 8'd1));
            else
                $write("+%0d", v);
        end
    endtask

    task show_signed16;
        input [15:0] v;
        begin
            if (v[15] == 1'b1)
                $write("-%0d", ((~v) + 16'd1));
            else
                $write("+%0d", v);
        end
    endtask

    task show_op8;
        input [7:0] v;
        begin
            print_bin8(v);
            $write(" (");
            show_signed8(v);
            $write(")");
        end
    endtask

    task run_op;
        input [7:0] opA, opB;
        input [1:0] opCode;
        begin
            @(negedge CLK);
            A=opA; B=opB; OP=opCode; START=1'b1;
            @(negedge CLK);
            START=1'b0;

            @(posedge CLK);
            while (DONE !== 1'b1) @(posedge CLK);
            r_result    = RESULT;
            r_rest      = REST;
            r_divz      = DIV_ZERO;

            @(negedge CLK);

            case (opCode)
                2'b00: begin
                    $write("  ADD  ");
                    show_op8(opA);
                    $write("  +  ");
                    show_op8(opB);
                    $display("");
                    $write("       = ");
                    print_bin8(r_result[7:0]);
                    $write("  (");
                    show_signed8(r_result[7:0]);
                    $write(")");
                    $display("");
                end
                2'b01: begin
                    $write("  SUB  ");
                    show_op8(opA);
                    $write("  -  ");
                    show_op8(opB);
                    $display("");
                    $write("       = ");
                    print_bin8(r_result[7:0]);
                    $write("  (");
                    show_signed8(r_result[7:0]);
                    $write(")");
                    $display("");
                end
                2'b10: begin
                    $write("  MUL  ");
                    show_op8(opA);
                    $write("  *  ");
                    show_op8(opB);
                    $display("");
                    $write("       = ");
                    print_bin16(r_result);
                    $write("  (");
                    show_signed16(r_result);
                    $write(")");
                    $display("");
                end
                2'b11: begin
                    $write("  DIV  ");
                    print_bin8(opA);
                    $write(" (%0d)  /  ", opA);
                    print_bin8(opB);
                    $write(" (%0d)", opB);
                    $display("");
                    if (r_divz) begin
                        $display("       = *** IMPARTIRE LA ZERO ***");
                    end else begin
                        $write("       CAT=");
                        print_bin8(r_result[7:0]);
                        $write(" (%0d)  REST=", r_result[7:0]);
                        print_bin8(r_rest);
                        $write(" (%0d)", r_rest);
                        $display("");
                    end
                end
            endcase
            $display("       ---");
            repeat(2) @(negedge CLK);
        end
    endtask

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu_top);

        RST=1; START=0; A=0; B=0; OP=0;
        repeat(4) @(posedge CLK);
        @(negedge CLK); RST=0;
        repeat(2) @(negedge CLK);

        $display("===========================================================");
        $display(" ALU Testbench  C2 signed (ADD/SUB/MUL)  unsigned (DIV)");
        $display("===========================================================");

        $display("\n=== ADD (signed C2) ===");
        run_op(8'd25,  8'd17,  2'b00);  //  25 +  17 =  42
        run_op(8'd0,    8'd0,  2'b00);  //   0 +   0 =   0

        $display("\n=== SUB (signed C2) ===");
        run_op(8'd50,  8'd18,  2'b01);  //  50 -  18 =  32
        run_op(8'd5,   8'd10,  2'b01);  //  5  -  10 =  -5

        $display("\n=== MUL Booth Radix-2 (signed C2) ===");
        run_op(8'd6,   8'd7,   2'b10);  //   6 *   7 =   42
        run_op(8'd12,  8'd12,  2'b10);  //  12 *  12 =  144

        $display("\n=== DIV Restoring (unsigned) ===");
        run_op(8'd48,  8'd8,   2'b11);  // 48/8  = 6 rest 0
        run_op(8'd7,   8'd3,   2'b11);  // 7/3 = 2 rem 1
        run_op(8'd0,   8'd0,   2'b11);  // div/0

        $display("===========================================================");
        $display(" Done");
        $display("===========================================================");
        $finish;
    end
endmodule