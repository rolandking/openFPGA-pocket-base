`timescale  1ns/1ps

/*
 * there are quite a few options for setting dq depending on the
 * driver so just make this a simple interface
 */

interface cram_if;
    wire [15:0]   data_out;
    inout wire [15:0]   data_in;
    wire          in_en;

    wire [21:16] a;
    wire         clk;
    wire         _wait;               // wait
    wire         adv_n;
    wire         cre;
    wire         ce0_n;
    wire         ce1_n;
    wire         oe_n;
    wire         we_n;
    wire         ub_n;
    wire         lb_n;

    function automatic tie_off();
        a              = '0;
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

module cram_connect(
    inout  wire [15:0]  dq,
    output wire [21:16] a,
    output wire         clk,
    input  wire         _wait,
    output wire         adv_n,
    output wire         cre,
    output wire         ce0_n,
    output wire         ce1_n,
    output wire         oe_n,
    output wire         we_n,
    output wire         ub_n,
    output wire         lb_n,

    cram_if             cram
);
    genvar i;
    generate
        for(i = 0 ; i < 16 ; i++) begin : gen_tran
            tran (dq[i], cram.data_in[i]);
        end
    endgenerate

    always_comb begin
        a = cram.a;
        clk = cram.clk;
        cram._wait = _wait;
        adv_n = cram.adv_n;
        cre = cram.cre;
        ce0_n = cram.ce0_n;
        ce1_n = cram.ce1_n;
        oe_n = cram.oe_n;
        we_n = cram.we_n;
        ub_n = cram.ub_n;
        lb_n = cram.lb_n;
        dq = oe_n ? cram.data_out : 'Z;
    end

endmodule
