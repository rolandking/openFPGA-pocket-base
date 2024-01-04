 `timescale 1ns/1ps

 interface bridge_if(
    input wire clk
 );
    pocket::bridge_addr_t addr;
    pocket::bridge_data_t wr_data;
    logic                 wr;
    pocket::bridge_data_t rd_data;
    logic                 rd;

    function automatic connect(
        ref pocket::bridge_addr_t _addr, 
        ref pocket::bridge_data_t _wr_data,
        ref logic                 _wr,
        ref pocket::bridge_data_t _rd_data,
        ref logic                 _rd
    );
        addr     = _addr;
        wr_data  = _wr_data;
        wr       = _wr;
        rd       = _rd;
        _rd_data = rd_data;
    endfunction

    function automatic connect_leaf(ref leaf);
        leaf.addr    = addr;
        leaf.wr_data = wr_data;
        leaf.wr      = wr;
        leaf.rd      = rd;
        rd_data      = leaf.rd_data;
    endfunction

 endinterface

 `define BRIDGE_CONNECT_TREE_LEAF_NO_READ(_T,_L) \
    always_comb begin                                      \
        _L.addr          = _T.addr;                 \
        _L.wr_data       = _T.wr_data;              \
        _L.wr            = _T.wr;                   \
        _L.rd            = _T.wr;                   \
    end

 `define BRIDGE_CONNECT_TREE_LEAF_READ(_T,_L)    \
    always_comb begin                                      \
        _T.rd_data = _L.rd_data;                    \
    end

 `define BRIDGE_CONNECT_TREE_LEAF(_T,_L)         \
    `BRIDGE_CONNECT_TREE_LEAF_NO_READ(_T,_L)     \
    `BRIDGE_CONNECT_TREE_LEAF_READ(_T,_L)
