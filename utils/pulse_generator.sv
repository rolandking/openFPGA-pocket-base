`timescale 1ns/1ps

module pulse_generator#(
    parameter int   BEATS = 2,
    parameter logic PULSE_START = 1'b0
) (
    input  wire clk,
    output logic pulse,
    input  wire  reset
);

    generate
        if(BEATS==1) begin : gen_noop
            always_comb pulse = 1'b1;
        end else begin : gen_count
            typedef logic [BEATS-1:0] shifter_t;
            localparam shifter_t SHIFTER_RESET = PULSE_START ? {{(BEATS-1){1'b0}},1'b1} : {1'b1,{(BEATS-1){1'b0}}};
            shifter_t shifter = SHIFTER_RESET;
            always_comb pulse = shifter[0];
            always_ff @(posedge clk) begin
                if(reset) begin
                    shifter <= SHIFTER_RESET;
                end else begin
                    shifter <= {shifter[0], shifter[BEATS-1:1]};
                end
            end
        end
    endgenerate

endmodule
