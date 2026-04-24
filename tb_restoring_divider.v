// Testbench pentru restoring_divider_v2.
// Testeaza impartiri unsigned, inclusiv cazul de impartire la zero.
`timescale 1ns/1ps

module tb_restoring_divider;

    // ---- Semnale ----
    reg        CLK, RST, EN;
    reg  [7:0] A, B;
    wire [7:0] CAT, REST;
    wire       DONE, DIV_ZERO;

    // ---- Clock: perioada 10 ns ----
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // ---- Instantiere DUT ----
    restoring_divider_v2 dut (
        .CLK(CLK), .RST(RST), .EN(EN),
        .A(A), .B(B),
        .CAT(CAT), .REST(REST),
        .DONE(DONE), .DIV_ZERO(DIV_ZERO)
    );

    // ---- Task: ruleaza o impartire si verifica ----
    task run_div;
        input [7:0] dividend, divisor;
        input [7:0] exp_cat, exp_rest;
        input       exp_divzero;
        reg   [7:0] got_cat, got_rest;
        reg         got_dz;
        reg         ok;
        begin
            @(negedge CLK);
            A = dividend; B = divisor; EN = 1'b1;
            @(negedge CLK);
            EN = 1'b0;

            // Asteapta DONE
            @(posedge CLK);
            while (DONE !== 1'b1) @(posedge CLK);
            got_cat  = CAT;
            got_rest = REST;
            got_dz   = DIV_ZERO;
            @(negedge CLK);

            if (exp_divzero) begin
                ok = (got_dz === 1'b1);
                $write("  DIV  %0d / %0d => DIV_ZERO=%0d", dividend, divisor, got_dz);
                if (ok)
                    $display("  [OK]");
                else
                    $display("  [FAIL] expected DIV_ZERO=1");
            end else begin
                ok = (got_cat  === exp_cat)  &&
                     (got_rest === exp_rest) &&
                     (got_dz   === 1'b0);
                $write("  DIV  %0d / %0d => CAT=%0d REST=%0d",
                        dividend, divisor, got_cat, got_rest);
                if (ok)
                    $display("  [OK]");
                else
                    $display("  [FAIL] expected CAT=%0d REST=%0d",
                              exp_cat, exp_rest);
            end

            repeat(2) @(negedge CLK);
        end
    endtask

    // ---- Stimuli ----
    initial begin
        $dumpfile("tb_restoring_divider.vcd");
        $dumpvars(0, tb_restoring_divider);

        // Reset initial
        RST = 1; EN = 0; A = 0; B = 0;
        repeat(4) @(posedge CLK);
        @(negedge CLK); RST = 0;
        repeat(2) @(negedge CLK);

        $display("=================================================");
        $display(" TB restoring_divider_v2  (unsigned)");
        $display("=================================================");

        // --------------------------------------------------
        // 1. Cazuri normale
        // --------------------------------------------------
        $display("\n-- Impartiri normale --");
        run_div(8'd100, 8'd7,   8'd14,  8'd2,  0); // 100/7  = 14 r 2
        run_div(8'd255, 8'd16,  8'd15,  8'd15, 0); // 255/16 = 15 r 15
        run_div(8'd20,  8'd4,   8'd5,   8'd0,  0); //  20/4  =  5 r 0
        run_div(8'd99,  8'd10,  8'd9,   8'd9,  0); //  99/10 =  9 r 9
        run_div(8'd128, 8'd3,   8'd42,  8'd2,  0); // 128/3  = 42 r 2
        run_div(8'd200, 8'd13,  8'd15,  8'd5,  0); // 200/13 = 15 r 5

        // --------------------------------------------------
        // 2. Cat = 0 (dividend < divisor)
        // --------------------------------------------------
        $display("\n-- Dividend mai mic decat divisor (cat=0) --");
        run_div(8'd1,   8'd2,   8'd0,   8'd1,  0); //   1/2  =  0 r 1
        run_div(8'd0,   8'd5,   8'd0,   8'd0,  0); //   0/5  =  0 r 0
        run_div(8'd7,   8'd8,   8'd0,   8'd7,  0); //   7/8  =  0 r 7

        // --------------------------------------------------
        // 3. Impartire exacta (rest = 0)
        // --------------------------------------------------
        $display("\n-- Impartire exacta (rest=0) --");
        run_div(8'd50,  8'd5,   8'd10,  8'd0,  0); //  50/5  = 10 r 0
        run_div(8'd81,  8'd9,   8'd9,   8'd0,  0); //  81/9  =  9 r 0
        run_div(8'd255, 8'd255, 8'd1,   8'd0,  0); // 255/255=  1 r 0
        run_div(8'd1,   8'd1,   8'd1,   8'd0,  0); //   1/1  =  1 r 0

        // --------------------------------------------------
        // 4. Cazuri limita
        // --------------------------------------------------
        $display("\n-- Cazuri limita --");
        run_div(8'd255, 8'd1,   8'd255, 8'd0,  0); // 255/1  = 255 r 0
        run_div(8'd0,   8'd1,   8'd0,   8'd0,  0); //   0/1  =   0 r 0
        run_div(8'd254, 8'd127, 8'd2,   8'd0,  0); // 254/127=   2 r 0
        run_div(8'd128, 8'd255, 8'd0,   8'd128,0); // 128/255=   0 r 128

        // --------------------------------------------------
        // 5. Impartire la zero -> DIV_ZERO=1
        // --------------------------------------------------
        $display("\n-- Impartire la zero --");
        run_div(8'd10,  8'd0,   8'd0,   8'd0,  1); //  10/0 -> DIV_ZERO
        run_div(8'd0,   8'd0,   8'd0,   8'd0,  1); //   0/0 -> DIV_ZERO
        run_div(8'd255, 8'd0,   8'd0,   8'd0,  1); // 255/0 -> DIV_ZERO

        $finish;
    end

endmodule
