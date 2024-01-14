`timescale 1ns/1ps

interface sram_if;

    wire [15:0]   data_in;
    wire [15:0]   data_out;
    pocket::dir_e dir;
    wire [16:0]   a;
    wire          oe_n;
    wire          we_n;
    wire          ub_n;
    wire          lb_n;

    function automatic tie_off();
        a           = '0;
        data_out    = 'x;
        dir         = pocket::DIR_IN;
        oe_n        = '1;
        we_n        = '1;
        ub_n        = '1;
        lb_n        = '1;
    endfunction

endinterface

module sram_connect (
    output  wire [16:0]  a,
    inout   wire [15:0]  dq,
    output  wire         oe_n,
    output  wire         we_n,
    output  wire         ub_n,
    output  wire         lb_n,

    sram_if              sram
);

    tristate_buffer #(
        .lo_index   (0),
        .hi_index   (15)
    ) src_tb (
        .port       (dq),
        .data_in    (sram.data_in),
        .data_out   (sram.data_out),
        .dir        (sram.dir)
    );

    always_comb begin
        a    = sram.a;
        oe_n = sram.oe_n;
        we_n = sram.we_n;
        ub_n = sram.ub_n;
        lb_n = sram.lb_n;
    end

endmodule
