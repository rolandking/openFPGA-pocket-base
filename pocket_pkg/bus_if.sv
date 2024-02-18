`timescale 1ns/1ps

interface bus_if#(
    parameter int addr_width,
    parameter int data_width
)(
    input wire clk
);
    logic [addr_width-1:0] addr;
    logic                  wr;
    logic [data_width-1:0] wr_data;
    logic                  rd;
    logic [data_width-1:0] rd_data;
    logic                  rd_data_valid;

    function automatic tie_off_rd();
        rd_data       = 'x;
        rd_data_valid = '0;
    endfunction

endinterface

module bridge_connect#(
    parameter int data_width=32
)(
    input  pocket::bridge_addr_t  addr,
    input  logic [data_width-1:0] wr_data,
    input  logic                  wr,
    output logic [data_width-1:0] rd_data,
    input  logic                  rd,

    bus_if                        bridge
);
    `STATIC_ASSERT(bridge.data_width == 32, bridge uses 32 bit data)
    `STATIC_ASSERT(bridge.addr_width == 32, bridge uses 32 bit address)
    always_comb begin
        bridge.addr     = addr;
        bridge.wr_data  = wr_data;
        bridge.wr       = wr;
        bridge.rd       = rd;
        rd_data         = bridge.rd_data;
        // bus.rd_data_valid is ignored
    end

endmodule

`define BUS_CONNECT_TREE_LEAF_NO_READ(_T,_L)        \
    always_comb begin                               \
        _L.addr          = _T.addr;                 \
        _L.wr_data       = _T.wr_data;              \
        _L.wr            = _T.wr;                   \
        _L.rd            = _T.rd;                   \
    end

`define BUS_CONNECT_TREE_LEAF_READ(_T,_L)           \
    always_comb begin                               \
        _T.rd_data       = _L.rd_data;              \
        _T.rd_data_valid = _L.rd_data_valid;        \
    end

`define BUS_CONNECT_TREE_LEAF(_T,_L)                \
    `BUS_CONNECT_TREE_LEAF_NO_READ(_T,_L)           \
    `BUS_CONNECT_TREE_LEAF_READ(_T,_L)
