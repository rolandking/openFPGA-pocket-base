`timescale 1ns/1ps

module tristate_buffer #(
    parameter int hi_index = 0,
    parameter int lo_index = 0
) (
    inout wire [hi_index:lo_index] port,
    inout wire [hi_index:lo_index] data_in,
    input wire [hi_index:lo_index] data_out,
    input pocket::dir_e            dir
);

    genvar i;
    generate
        for(i = lo_index ; i <= hi_index ; i++) begin : gen_tran
            tran (port[i], data_in[i]);
        end
    endgenerate

    always_comb begin
        port = (dir == pocket::DIR_OUT) ? data_out : 'Z;
    end

endmodule
