`timescale 1ns/1ps

import pocket::dir_e;

module tristate_buffer #(
    parameter int WIDTH = 1
) (
    inout  wire  [WIDTH-1:0] port,
    inout  wire  [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    input  dir_e      dir
);
    generate
        genvar i;
        for( i = 0 ; i < WIDTH ; i++ ) begin : gen_tran
            tran(data_in[i], port[i]);
        end
    endgenerate

    // if data is coming in, tristate the lines, else put data_out there
    always_comb port = (dir == pocket::DIR_IN) ? 'Z : data_out;

endmodule
