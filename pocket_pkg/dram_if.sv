`timescale 1ns/1ps

/*
 * just bundle the wires and pass them through, can add a data_to_ram
 * and data_from_ram later when you implement the module
 */

interface dram_if;
    logic [12:0]  a;
    logic [1:0]   ba;
    logic [15:0]  dq;
    logic [1:0]   dqm;
    logic         clk;
    logic         cke;
    logic         ras_n;
    logic         cas_n;
    logic         we_n;

    function automatic connect(
        ref logic [12:0] _a,
        ref logic [1:0]  _ba,
        ref logic [15:0] _dq,
        ref logic [1:0]  _dqm,
        ref logic        _clk,
        ref logic        _cke,
        ref logic        _ras_n,
        ref logic        _cas_n,
        ref logic        _we_n
    );
        _a     = a;
        _ba    = ba;
        _dq    = dq;
        _dqm   = dqm;
        _clk   = clk;
        _cke   = cke;
        _ras_n = ras_n;
        _cas_n = cas_n;
        _we_n  = we_n;
    endfunction

    function automatic tie_off();
        a     = '0;
        ba    = '0;
        dq    = 'Z;
        dqm   = '0;
        clk   = '0;
        cke   = '0;
        ras_n = '1;
        cas_n = '1;
        we_n  = '1;
    endfunction

endinterface
