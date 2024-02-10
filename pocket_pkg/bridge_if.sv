`timescale 1ns/1ps

interface bridge_if#(
    parameter int data_width = 32
)(
    input wire clk
);
    pocket::bridge_addr_t  addr;
    logic [data_width-1:0] wr_data;
    logic                  wr;
    pocket::bridge_data_t  rd_data;
    logic                  rd;
endinterface

module bridge_connect#(
    parameter int data_width=32
)(
    input  pocket::bridge_addr_t addr,
    input  pocket::bridge_data_t wr_data,
    input  logic                 wr,
    output pocket::bridge_data_t rd_data,
    input  logic                 rd,
    bridge_if                    bridge
);

    always_comb begin
        bridge.addr     = addr;
        bridge.wr_data  = wr_data;
        bridge.wr       = wr;
        bridge.rd       = rd;
        rd_data         = bridge.rd_data;
    end

endmodule

`define BRIDGE_CONNECT_TREE_LEAF_NO_READ(_T,_L)     \
    always_comb begin                               \
        _L.addr          = _T.addr;                 \
        _L.wr_data       = _T.wr_data;              \
        _L.wr            = _T.wr;                   \
        _L.rd            = _T.rd;                   \
    end

`define BRIDGE_CONNECT_TREE_LEAF_READ(_T,_L)        \
    always_comb begin                               \
        _T.rd_data = _L.rd_data;                    \
    end

`define BRIDGE_CONNECT_TREE_LEAF(_T,_L)             \
    `BRIDGE_CONNECT_TREE_LEAF_NO_READ(_T,_L)        \
    `BRIDGE_CONNECT_TREE_LEAF_READ(_T,_L)
