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
    logic                            dir_to_port;

    // when FROM_PORT, from_cart has the data, to_port is 'z
    logic [hi_index:lo_index]        from_port;

    // when TO_PORT, the to_port data is sent to the port and
    // to from_port
    logic [hi_index:lo_index]        to_port;

    function automatic connect(ref logic [hi_index:lo_index] port_inout, ref logic port_dir);
        port_dir   = dir_to_port;
        from_port  = port_inout;
        port_inout = dir_to_port ? to_port : 'z;
    endfunction

    function automatic tie_off_from_port();
        dir_to_port = '0;
        to_port     = 'x;
    endfunction

    function automatic tie_off_to_port(logic[hi_index:lo_index] value);
        dir_to_port = 1'b1;
        to_port     = value;
    endfunction

endinterface
