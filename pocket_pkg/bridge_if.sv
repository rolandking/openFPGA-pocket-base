 `timescale 1ns/1ps

 interface bridge_if(
    input wire clk
 );
    pocket::bridge_addr_t addr;
    pocket::bridge_data_t wr_data;
    logic                 wr;
    pocket::bridge_data_t rd_data;
    logic                 rd;

    // connect the bridge_if to top level signal
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

    // explode the bridge_if back into individual signals
    function automatic explode(
        ref pocket::bridge_addr_t _addr,
        ref pocket::bridge_data_t _wr_data,
        ref logic                 _wr,
        ref pocket::bridge_data_t _rd_data,
        ref logic                 _rd
    );
        _addr     = addr;
        _wr_data  = wr_data;
        _wr       = wr;
        _rd       = rd;
        rd_data   = _rd_data;
    endfunction

 endinterface

 `define BRIDGE_CONNECT_TREE_LEAF_NO_READ(_T,_L) \
    always_comb begin                                      \
        _L.addr          = _T.addr;                 \
        _L.wr_data       = _T.wr_data;              \
        _L.wr            = _T.wr;                   \
        _L.rd            = _T.rd;                   \
    end

 `define BRIDGE_CONNECT_TREE_LEAF_READ(_T,_L)    \
    always_comb begin                                      \
        _T.rd_data = _L.rd_data;                    \
    end

 `define BRIDGE_CONNECT_TREE_LEAF(_T,_L)         \
    `BRIDGE_CONNECT_TREE_LEAF_NO_READ(_T,_L)     \
    `BRIDGE_CONNECT_TREE_LEAF_READ(_T,_L)
