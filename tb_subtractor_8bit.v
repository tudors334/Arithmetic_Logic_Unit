// ============================================================
// Testbench: tb_subtractor_8bit
// Module under test: subtractor_8bit
// Dependinte: full_adder.v, adder_8bit.v, subtractor_8bit.v
// Simulare: ModelSim -> compile toate, simulate tb_subtractor_8bit
// ============================================================
`timescale 1ns/1ps

module tb_subtractor_8bit;

    // ---- Semnale ----
    reg  [7:0] A, B;
    wire [7:0] DIFF;
    wire       Borrow, Overflow;

    // ---- Instantiere DUT ----
    subtractor_8bit dut (
        .A(A), .B(B),
        .DIFF(DIFF), .Borrow(Borrow), .Overflow(Overflow)
    );

    // ---- Task: afiseaza si verifica un rezultat ----
    task show;
        input [7:0] a, b;
        input [7:0] diff;
        input       borrow, ov;
        input [7:0] expected_diff;
        input       expected_borrow, expected_ov;
        reg   ok;
        begin
            ok = (diff   === expected_diff)   &&
                 (borrow === expected_borrow) &&
                 (ov     === expected_ov);
            $write("  A=%0d B=%0d => DIFF=%0d Borrow=%0d OV=%0d",
                    $signed(a), $signed(b),
                    $signed(diff), borrow, ov);
            if (ok)
                $display("  [OK]");
            else
                $display("  [FAIL] expected DIFF=%0d Borrow=%0d OV=%0d",
                          $signed(expected_diff), expected_borrow, expected_ov);
        end
    endtask

    // ---- Stimuli ----
    initial begin
        $dumpfile("tb_subtractor_8bit.vcd");
        $dumpvars(0, tb_subtractor_8bit);

        $display("=================================================");
        $display(" TB subtractor_8bit  (signed C2)");
        $display("=================================================");

        // --------------------------------------------------
        // 1. Scaderi simple pozitive, fara borrow / overflow
        // --------------------------------------------------
        $display("\n-- Scaderi simple fara borrow --");

        // 50 - 20 = 30
        A=8'd50;  B=8'd20;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd30, 0, 0);

        // 100 - 1 = 99
        A=8'd100; B=8'd1;   #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd99, 0, 0);

        // 127 - 127 = 0
        A=8'd127; B=8'd127; #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd0, 0, 0);

        // 10 - 10 = 0
        A=8'd10;  B=8'd10;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd0, 0, 0);

        // --------------------------------------------------
        // 2. Rezultat negativ -> Borrow=1
        // --------------------------------------------------
        $display("\n-- Rezultat negativ (Borrow=1) --");

        // 10 - 25 = -15 (F1 in C2)
        A=8'd10;  B=8'd25;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'hF1, 1, 0);

        // 0 - 1 = -1 (FF)
        A=8'd0;   B=8'd1;   #10;
        show(A,B,DIFF,Borrow,Overflow, 8'hFF, 1, 0);

        // 0 - 255 = -255 (01 in C2 cu borrow)
        A=8'd0;   B=8'hFF;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'h01, 1, 0);

        // --------------------------------------------------
        // 3. Operanzi negativi (C2)
        // --------------------------------------------------
        $display("\n-- Operanzi negativi (C2) --");

        // -3 - 3 = -6 (FA)
        A=8'hFD;  B=8'd3;   #10;
        show(A,B,DIFF,Borrow,Overflow, 8'hFA, 1, 0);

        // -3 - (-3) = 0
        A=8'hFD;  B=8'hFD;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd0, 0, 0);

        // -1 - 1 = -2 (FE)
        A=8'hFF;  B=8'd1;   #10;
        show(A,B,DIFF,Borrow,Overflow, 8'hFE, 1, 0);

        // -10 - (-3) = -7 (F9)
        A=8'hF6;  B=8'hFD;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'hF9, 0, 0);

        // --------------------------------------------------
        // 4. Overflow: depasire signed
        // --------------------------------------------------
        $display("\n-- Overflow signed --");

        // -128 - 1 = -129 -> overflow (7F result, OV=1)
        A=8'h80;  B=8'd1;   #10;
        show(A,B,DIFF,Borrow,Overflow, 8'h7F, 0, 1);

        // 127 - (-1) = 128 -> overflow
        A=8'd127; B=8'hFF;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'h80, 1, 1);

        // --------------------------------------------------
        // 5. Cazuri limita
        // --------------------------------------------------
        $display("\n-- Cazuri limita --");

        // 255 - 255 = 0 (unsigned)
        A=8'hFF;  B=8'hFF;  #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd0, 0, 0);

        // 128 - 127 = 1
        A=8'h80;  B=8'd127; #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd1, 1, 1);

        // 1 - 0 = 1
        A=8'd1;   B=8'd0;   #10;
        show(A,B,DIFF,Borrow,Overflow, 8'd1, 0, 0);

        $display("\n=================================================");
        $display(" TB subtractor_8bit TERMINAT");
        $display("=================================================");
        $finish;
    end

endmodule
