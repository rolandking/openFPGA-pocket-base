`timescale 1ns/1ps

/*
 * just bundle the wires and pass them through, can add a data_to_ram
 * and data_from_ram later when you implement the module
 */

interface dram_if;
    wire [15:0]   data_in;
    wire [15:0]   data_out;
    pocket::dir_e dir;
    wire [12:0]   a;
    wire [1:0]    ba;
    wire [1:0]    dqm;
    wire          clk;
    wire          cke;
    wire          ras_n;
    wire          cas_n;
    wire          we_n;

    function automatic tie_off();
        a        = '0;
        ba       = '0;
        dir      = pocket::DIR_IN;
        data_out = 'Z;
        dqm      = '0;
        clk      = '0;
        cke      = '0;
        ras_n    = '1;
        cas_n    = '1;
        we_n     = '1;
    endfunction

endinterface

module dram_connect(

    output  wire    [12:0]  dram_a,
    output  wire    [1:0]   dram_ba,
    inout   wire    [15:0]  dram_dq,
    output  wire    [1:0]   dram_dqm,
    output  wire            dram_clk,
    output  wire            dram_cke,
    output  wire            dram_ras_n,
    output  wire            dram_cas_n,
    output  wire            dram_we_n,

    dram_if                 dram
);

    tristate_buffer #(
        .lo_index   (0),
        .hi_index   (15)
    ) tb (
        .port       (dram_dq),
        .data_in    (dram.data_in),
        .data_out   (dram.data_out),
        .dir        (dram.dir)
    );

    always_comb begin
        dram_a     = dram.a;
        dram_ba    = dram.ba;
        dram_dqm   = dram.dqm;
        dram_clk   = dram.clk;
        dram_cke   = dram.cke;
        dram_ras_n = dram.ras_n;
        dram_cas_n = dram.cas_n;
        dram_we_n  = dram.we_n;
    end

endmodule
