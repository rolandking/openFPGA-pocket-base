`timescale 1ns/1ps

module pulse_generator#(
    parameter int BEATS = 2
) (
    input wire clk,
    output logic pulse
);

    generate
        if(BEATS==1) begin : gen_noop
            always_comb pulse = 1'b1;
        end else begin : gen_count
            logic [BEATS-1:0] shifter = {1'b1, {(BEATS-1){1'b0}}};
            always_comb pulse = shifter[0];
            always_ff @(posedge clk) begin
                shifter <= {shifter[0], shifter[BEATS-1:1]};
            end
        end
    endgenerate

endmodule
