// ============================================================
// Testbench: tb_adder_8bit
// Module under test: adder_8bit
// Dependinte: full_adder.v, adder_8bit.v
// Simulare: ModelSim -> compile toate 3, simulate tb_adder_8bit
// ============================================================
`timescale 1ns/1ps

module tb_adder_8bit;

    // ---- Semnale ----
    reg  [7:0] A, B;
    reg        Cin;
    wire [7:0] SUM;
    wire       Cout, Overflow;

    // ---- Instantiere DUT ----
    adder_8bit dut (
        .A(A), .B(B), .Cin(Cin),
        .SUM(SUM), .Cout(Cout), .Overflow(Overflow)
    );

    // ---- Task: afiseaza un rezultat ----
    task show;
        input [7:0] a, b;
        input       cin;
        input [7:0] sum;
        input       cout, ov;
        input [7:0] expected_sum;
        input       expected_cout, expected_ov;
        reg   ok;
        begin
            ok = (sum === expected_sum) &&
                 (cout === expected_cout) &&
                 (ov   === expected_ov);
            $write("  A=%0d B=%0d Cin=%0d => SUM=%0d Cout=%0d OV=%0d",
                    $signed(a), $signed(b), cin,
                    $signed(sum), cout, ov);
            if (ok)
                $display("  [OK]");
            else
                $display("  [FAIL] expected SUM=%0d Cout=%0d OV=%0d",
                          $signed(expected_sum), expected_cout, expected_ov);
        end
    endtask

    // ---- Stimuli ----
    initial begin
        $dumpfile("tb_adder_8bit.vcd");
        $dumpvars(0, tb_adder_8bit);

        $display("=================================================");
        $display(" TB adder_8bit  (signed C2 / unsigned mixt)");
        $display("=================================================");

        // --------------------------------------------------
        // 1. Adunari simple pozitive, fara overflow
        // --------------------------------------------------
        $display("\n-- Adunari fara overflow --");

        // 15 + 27 = 42, Cout=0, OV=0
        A=8'd15;  B=8'd27;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd42, 0, 0);

        // 0 + 0 = 0
        A=8'd0;   B=8'd0;   Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd0, 0, 0);

        // 100 + 27 = 127 (maxim pozitiv signed fara OV)
        A=8'd100; B=8'd27;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd127, 0, 0);

        // 1 + 1 = 2
        A=8'd1;   B=8'd1;   Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd2, 0, 0);

        // --------------------------------------------------
        // 2. Cin = 1
        // --------------------------------------------------
        $display("\n-- Cu Cin=1 --");

        // 5 + 5 + 1 = 11
        A=8'd5;   B=8'd5;   Cin=1; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd11, 0, 0);

        // 0 + 0 + 1 = 1
        A=8'd0;   B=8'd0;   Cin=1; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd1, 0, 0);

        // --------------------------------------------------
        // 3. Adunari negative (C2): -3 + 10 = 7
        // --------------------------------------------------
        $display("\n-- Operanzi negativi (C2) --");

        // -3 + 10 = 7
        A=8'hFD;  B=8'd10;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd7, 1, 0);

        // -2 + -3 = -5 (FE + FD = FB)
        A=8'hFE;  B=8'hFD;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'hFB, 1, 0);

        // -1 + -1 = -2
        A=8'hFF;  B=8'hFF;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'hFE, 1, 0);

        // -128 + 1 = -127
        A=8'h80;  B=8'd1;   Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'h81, 0, 0);

        // --------------------------------------------------
        // 4. Overflow pozitiv: 127 + 1 => OV=1
        // --------------------------------------------------
        $display("\n-- Overflow --");

        // 127 + 1 = -128 (overflow pozitiv)
        A=8'd127; B=8'd1;   Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'h80, 0, 1);

        // 100 + 100 = 200 -> overflow (200 > 127)
        A=8'd100; B=8'd100; Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd200, 0, 1);

        // -128 + -1 = overflow negativ
        A=8'h80;  B=8'hFF;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'h7F, 1, 1);

        // --------------------------------------------------
        // 5. Carry out (unsigned overflow): 255 + 1
        // --------------------------------------------------
        $display("\n-- Carry out (unsigned) --");

        // 255 + 1 = 256 -> SUM=0, Cout=1
        A=8'hFF;  B=8'd1;   Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'd0, 1, 0);

        // 255 + 255 = 510 -> SUM=FE, Cout=1
        A=8'hFF;  B=8'hFF;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'hFE, 1, 0);

        // --------------------------------------------------
        // 6. Cazuri limita
        // --------------------------------------------------
        $display("\n-- Cazuri limita --");

        // 0 + 255 = 255
        A=8'd0;   B=8'hFF;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'hFF, 0, 0);

        // 128 + 128 = 256 -> SUM=0, Cout=1, OV=1 (signed: -128+-128)
        A=8'h80;  B=8'h80;  Cin=0; #10;
        show(A,B,Cin,SUM,Cout,Overflow, 8'h00, 1, 1);

        $display("\n=================================================");
        $display(" TB adder_8bit TERMINAT");
        $display("=================================================");
        $finish;
    end

endmodule
