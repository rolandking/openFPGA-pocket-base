`timescale 1ns/1ps

/*
 * interface for a bidirectional port. The top level connects to an
 * inout array and an output to the tri-state buffer which selects
 * the direction
 */

typedef enum logic {
    FROM_PORT  = 1'b0,
    TO_PORT    = 1'b1
} port_dir_e;

// bundle the in and out data and the direction in one interface
interface port_if #(
    parameter int hi_index = 7,
    parameter int lo_index = 0
) (
    input  wire                      clk,

    inout  logic [hi_index:lo_index] port_inout,
    output logic                     port_dir
);
    // select the direction and wire all the input/outputs up
    port_dir_e                       dir;

    // when FROM_PORT, from_cart has the data, to_port is 'z
    logic [hi_index:lo_index]        from_port;

    // when TO_PORT, the to_port data is sent to the port and
    // to from_port
    logic [hi_index:lo_index]        to_port;

    always_comb begin
        from_port = port_inout;
        port_dir  = dir;

        case(dir)
            FROM_PORT: begin
                port_inout = 'z;
            end
            TO_PORT: begin
                port_inout= to_port;
            end
            default: begin
                port_inout = 'z;
            end
        endcase
    end
endinterface

// tie the port off to be an input. Set to_port so any
// attempt to use it will give a multiple driver error
`define PORT_TIE_OFF_FROM_PORT(port)   \
    always_comb begin                  \
        port.dir     = FROM_PORT;      \
        port.to_port = 'x;             \
    end

`define PORT_TIE_OFF_TO_PORT(port)     \
    always_comb port.dir = TO_PORT;
