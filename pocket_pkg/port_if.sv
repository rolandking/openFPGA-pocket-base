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
) (
    inout  logic [hi_index:lo_index] port_inout,
    output logic                     port_dir
);
    // select the direction and wire all the input/outputs up
    logic                            dir_to_port;

    // when FROM_PORT, from_cart has the data, to_port is 'z
    logic [hi_index:lo_index]        from_port;

    // when TO_PORT, the to_port data is sent to the port and
    // to from_port
    logic [hi_index:lo_index]        to_port;

    always_comb begin
        port_dir   = dir_to_port;
        from_port  = port_inout;
        port_inout = dir_to_port ? to_port : 'z;
    end
endinterface

// tie the port off to be an input. Set to_port so any
// attempt to use it will give a multiple driver error
`define PORT_TIE_OFF_FROM_PORT(_X)     \
    always_comb begin                  \
        _X.dir_to_port = '0;           \
        _X.to_port     = 'x;           \
    end

// tie the port off to be an output and set up a fixed
// value
`define PORT_TIE_OFF_TO_PORT(_X, _Y)         \
    always_comb begin                        \
        _X.dir_to_port = 1'b1;               \
        _X.to_port     =  _Y;                \
    end
