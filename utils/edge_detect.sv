`timescale 1ns/1ps

module edge_detect#(
    parameter logic positive = 1'b1
) (
    input  wire  clk,
    input  wire  in,
    output logic out
);

    logic in_ff = positive;

    always_ff @(posedge clk) begin
        in_ff <= in;
    end

    always_comb begin
        out = (in == positive) && (in ^ in_ff);
    end

endmodule