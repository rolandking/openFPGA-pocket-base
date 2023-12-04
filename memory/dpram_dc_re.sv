`timescale 1ns/1ps

module dpram_dc_re#(
    parameter int widthad_a,
    parameter int width_a = 8
) (
    input wire                  clock_a,
    input logic[widthad_a-1:0]  address_a,
    input logic[width_a-1:0]    data_a,
    input logic                 wren_a,
    input logic [width_a/8-1:0] byteena_a,
    input logic                 rden_a,
    output logic [width_a-1:0]  q_a,

    input wire                  clock_b,
    input logic[widthad_a-1:0]  address_b,
    input logic[width_a-1:0]    data_b,
    input logic                 wren_b,
    input logic [width_a/8-1:0] byteena_b,
    input logic                 rden_b,
    output logic [width_a-1:0]  q_b
);

    logic [width_a-1:0] rd_data_a, rd_data_b;
    logic rden_a_ff, rden_b_ff;

    always_ff @(posedge clock_a) rden_a_ff <= rden_a;
    always_ff @(posedge clock_b) rden_b_ff <= rden_b;

    enable_hold#(
        .WIDTH  (width_a)
    ) eh_a (
        .clk    (clock_a),
        .en     (rden_a_ff),
        .in     (rd_data_a),
        .out    (q_a)
    );

    enable_hold#(
        .WIDTH  (width_a)
    ) eh_b (
        .clk    (clock_b),
        .en     (rden_b_ff),
        .in     (rd_data_b),
        .out    (q_b)
    );

    dpram_dc#(
        .widthad_a  (widthad_a),
        .width_a    (width_a)
    ) rom (
        .clock_a    (clock_a),
        .address_a  (address_a),
        .data_a     (data_a),
        .wren_a     (wren_a),
        .byteena_a  (byteena_a),
        .q_a        (rd_data_a),
        .clock_b    (clock_b),
        .address_b  (address_b),
        .data_b     (data_b),
        .wren_b     (wren_b),
        .byteena_b  (byteena_b),
        .q_b        (rd_data_b)
    );

endmodule
