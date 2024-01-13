`timescale 1ns/1ps

/*
 * interface for a bidirectional port. The top level connects to an
 * inout array and an output to the tri-state buffer which selects
 * the direction
 */

// bundle the in and out data and the direction in one interface
interface port_if #(
    parameter int hi_index = 7,
    parameter int lo_index = 0
) ();
    // select the direction and wire all the input/outputs up
    pocket::dir_e                   dir;

    // data out FROM the port
    wire [hi_index:lo_index]        data_out;

    // data IN TO the port
    wire [hi_index:lo_index]        data_in;

    function automatic tie_off_in();
        dir      = pocket::DIR_IN;
        data_out = 'x;
    endfunction

    function automatic tie_off_out(logic[hi_index:lo_index] value);
        dir      = pocket::DIR_OUT;
        data_out = value;
    endfunction

endinterface

module port_connect #(
    parameter int hi_index = 7,
    parameter int lo_index = 0
) (
    inout wire [hi_index:lo_index] port_data,
    output wire                    port_dir,

    port_if                        port
);

    tristate_buffer #(
        .hi_index(hi_index),
        .lo_index(lo_index)
    ) tb (
        .port     (port_data),
        .data_in  (port.data_in),
        .data_out (port.data_out),
        .dir      (port.dir)
    );

    always_comb begin
        port_dir = port.dir;
    end

endmodule
