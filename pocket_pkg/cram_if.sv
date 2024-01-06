`timescale  1ns/1ps

/*
 * there are quite a few options for setting dq depending on the
 * driver so just make this a simple interface
 */

interface cram_if;
    logic [21:0]  a;
    logic [15:0]  data_to_ram;
    logic [15:0]  data_from_ram;
    logic         dq_is_addr;       // asserted dq = addr[15:0], else dq = data_to_ram
    logic         wt;               // wait
    logic         clk;
    logic         adv_n;
    logic         cre;
    logic         ce0_n;
    logic         ce1_n;
    logic         oe_n;
    logic         we_n;
    logic         ub_n;
    logic         lb_n;

    function automatic connect(
        ref logic [21:16] _a,
        ref logic [15:0]  _dq,
        ref logic         _clk,
        ref logic         _wait,
        ref logic         _adv_n,
        ref logic         _cre,
        ref logic         _ce0_n,
        ref logic         _ce1_n,
        ref logic         _oe_n,
        ref logic         _we_n,
        ref logic         _ub_n,
        ref logic         _lb_n
    );

        _a            = a[21:16];
        _dq           = oe_n ? ( dq_is_addr ? a[15:0] : data_to_ram ) : 'Z;
        data_from_ram = _dq;
        _clk          = clk;
        wt            = _wait;
        _adv_n        = adv_n;
        _cre          = cre;
        _ce0_n        = ce0_n;
        _ce1_n        = ce1_n;
        _oe_n         = oe_n;
        _we_n         = we_n;
        _ub_n         = ub_n;
        _lb_n         = lb_n;

    endfunction

    function automatic tie_off();
        a              = '0;
        data_to_ram    = 'Z;
        clk            = '0;
        adv_n          = 1'b1;
        cre            = 1'b0;
        ce0_n          = 1'b1;
        ce1_n          = 1'b1;
        oe_n           = 1'b0;
        we_n           = 1'b1;
        ub_n           = 1'b1;
        lb_n           = 1'b1;
    endfunction

endinterface