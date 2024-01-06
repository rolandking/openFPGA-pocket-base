`timescale 1ns/1ps

interface sram_if;

    logic [16:0] a;
    logic [15:0] data_from_ram;
    logic [15:0] data_to_ram;
    logic        oe_n;
    logic        we_n;
    logic        ub_n;
    logic        lb_n;

    function automatic connect(
        ref logic [16:0] _a,
        ref logic [15:0] _dq,
        ref logic        _oe_n,
        ref logic        _we_n,
        ref logic        _ub_n,
        ref logic        _lb_n
    );
        _dq           = we_n ? 'Z : data_to_ram;
        data_from_ram = _dq;
    endfunction

    function automatic tie_off();
        a           = '0;
        data_to_ram = 'x;
        oe_n        = '1;
        we_n        = '1;
        ub_n        = '1;
        lb_n        = '1;
    endfunction

endinterface
