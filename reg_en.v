// ============================================================
// Module: reg_en
// Description: Parameterized register with enable and sync reset
// ============================================================
module reg_en #(
    parameter W = 1
) (
    input  wire         CLK,
    input  wire         RST,
    input  wire         EN,
    input  wire [W-1:0] D,
    output reg  [W-1:0] Q
);
    always @(posedge CLK) begin
        if (RST) begin
            Q <= {W{1'b0}};
        end else if (EN) begin
            Q <= D;
        end
    end
endmodule
