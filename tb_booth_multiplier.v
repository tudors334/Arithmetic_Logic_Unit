// Testbench pentru booth_multiplier.
// Ruleaza inmultiri cu semn (C2) si compara rezultatul pe 16 biti.
`timescale 1ns/1ps

module tb_booth_multiplier;

    // ---- Semnale ----
    reg        CLK, RST, EN;
    reg  [7:0] A, B;
    wire [15:0] RESULT;
    wire        DONE;

    // ---- Clock: perioada 10 ns ----
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // ---- Instantiere DUT ----
    booth_multiplier dut (
        .CLK(CLK), .RST(RST), .EN(EN),
        .A(A), .B(B),
        .RESULT(RESULT), .DONE(DONE)
    );

    // ---- Task: ruleaza o inmultire si verifica ----
    task run_mul;
        input [7:0]  opA, opB;
        input [15:0] expected;
        reg   [15:0] got;
        reg          ok;
        begin
            // Aplica EN un singur ciclu
            @(negedge CLK);
            A = opA; B = opB; EN = 1'b1;
            @(negedge CLK);
            EN = 1'b0;

            // Asteapta DONE
            @(posedge CLK);
            while (DONE !== 1'b1) @(posedge CLK);
            got = RESULT;
            @(negedge CLK);

            ok = (got === expected);
            $write("  MUL  %0d * %0d = %0d",
                    $signed(opA), $signed(opB), $signed(got));
            if (ok)
                $display("  [OK]");
            else
                $display("  [FAIL] expected %0d", $signed(expected));

            // Pauza intre operatii
            repeat(2) @(negedge CLK);
        end
    endtask

    // ---- Stimuli ----
    initial begin
        $dumpfile("tb_booth_multiplier.vcd");
        $dumpvars(0, tb_booth_multiplier);

        // Reset initial
        RST = 1; EN = 0; A = 0; B = 0;
        repeat(4) @(posedge CLK);
        @(negedge CLK); RST = 0;
        repeat(2) @(negedge CLK);

        $display("=================================================");
        $display(" TB booth_multiplier  Booth Radix-2 (signed C2)");
        $display("=================================================");

        // --------------------------------------------------
        // 1. Ambii pozitivi
        // --------------------------------------------------
        $display("\n-- Ambii pozitivi --");
        run_mul(8'd7,   8'd6,   16'd42);       //   7 *   6 =    42
        run_mul(8'd12,  8'd11,  16'd132);      //  12 *  11 =   132
        run_mul(8'd1,   8'd1,   16'd1);        //   1 *   1 =     1
        run_mul(8'd0,   8'd99,  16'd0);        //   0 *  99 =     0
        run_mul(8'd127, 8'd127, 16'd16129);    // 127 * 127 = 16129

        // --------------------------------------------------
        // 2. Un operand negativ
        // --------------------------------------------------
        $display("\n-- Un operand negativ --");
        run_mul(8'hFD,  8'd4,   16'hFFF4);    //  -3 *   4 =   -12
        run_mul(8'd15,  8'hFE,  16'hFFE2);    //  15 *  -2 =   -30
        run_mul(8'd10,  8'hF6,  16'hFF9C);    //  10 * -10 =  -100
        run_mul(8'd127, 8'hFF,  16'hFF81);    // 127 *  -1 =  -127

        // --------------------------------------------------
        // 3. Ambii negativi
        // --------------------------------------------------
        $display("\n-- Ambii negativi --");
        run_mul(8'hFD,  8'hFD,  16'd9);       //  -3 *  -3 =     9
        run_mul(8'hFF,  8'hFF,  16'd1);       //  -1 *  -1 =     1
        run_mul(8'h80,  8'hFF,  16'd128);     //-128 *  -1 =   128
        run_mul(8'hF6,  8'hF6,  16'd100);     // -10 * -10 =   100

        // --------------------------------------------------
        // 4. Cazuri limita
        // --------------------------------------------------
        $display("\n-- Cazuri limita --");
        run_mul(8'd0,   8'd0,   16'd0);       //   0 *   0 =     0
        run_mul(8'd1,   8'd0,   16'd0);       //   1 *   0 =     0
        run_mul(8'h80,  8'h80,  16'h4000);    //-128 *-128 = 16384
        run_mul(8'd127, 8'h80,  16'hC080);    // 127 *-128 =-16256

        $finish;
    end

endmodule
