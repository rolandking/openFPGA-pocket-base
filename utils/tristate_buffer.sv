`timescale 1ns/1ps

module tristate_buffer #(
    parameter int WIDTH = 1
) (
    inout wire [WIDTH-1:0] port,
    inout wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] data_out,
    input pocket::dir_e    dir
);

    genvar i;
    generate
        for(i = 0 ; i < 16 ; i++) begin : gen_tran
            tran (port[i], data_in[i]);
        end
    endgenerate

    always_comb begin
        port = (dir == pocket::DIR_OUT) ? data_out : 'Z;
    end

endmodule
