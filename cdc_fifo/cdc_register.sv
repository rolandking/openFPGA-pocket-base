`timescale 1ns / 1ps

// simple CDC for a register of data in one direction which
// handshakes in both directions before another word can
// be written
// this is slow and requires a minimum of about 8 clock
// cycles in the slowest domain before a second word can be
// written

module cdc_register#(
    parameter int data_width = 32
) (
    input  logic                   wr_clk,
    input  logic [data_width-1:0]  wr_data,
    input  logic                   wr,
    output logic                   wr_ready,

    input  logic                   rd_clk,
    output logic [data_width-1:0]  rd_data,
    output logic                   rd_data_valid
);

    logic wr_flag_wr = 0;
    logic wr_flag_rd = 0;
    logic rd_flag_rd = 0;
    logic rd_flag_wr = 0;

    // write side

    always_comb begin
        // when the flags agree, you can write
        wr_ready = ~(wr_flag_wr ^ rd_flag_wr);
    end

    always_ff @(posedge wr_clk) begin
        if(wr_ready && wr) begin
            rd_data    <= wr_data;
            wr_flag_wr <= ~wr_flag_wr;
        end
    end

    // pass the wr_flag_wr across the CCD
    cdc_sync#(
        .num_bits  (1)
    ) wr_flag_to_rd (
        .from_clk  (wr_clk),
        .from_data (wr_flag_wr),
        .to_clk    (rd_clk),
        .to_data   (wr_flag_rd)
    );

    // read side

    always_comb begin
        // we can read when the flags differ,
        // the write flag change has passed over the CDC
        rd_data_valid = wr_flag_rd ^ rd_flag_rd;
    end

    always_ff @(posedge rd_clk) begin
        rd_flag_rd <= wr_flag_rd;
    end

    // pass the rd_flag_wr across the CCD to complete the handshake
    cdc_sync#(
        .num_bits  (1)
    ) rd_flag_to_wr (
        .from_clk  (rd_clk),
        .from_data (rd_flag_rd),
        .to_clk    (wr_clk),
        .to_data   (rd_flag_wr)
    );

endmodule
