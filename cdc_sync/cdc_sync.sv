`timescale 1ns/1ps

// cdc sync module. Registers the input data in the from clock domain once
// to ensure it's registered, then registers it twice into the to domain
// https://www.edn.com/synchronizer-techniques-for-multi-clock-domain-socs-fpgas/
//
module cdc_sync#(
    parameter int num_bits
) (
    input  wire               from_clk, 
    input  wire[num_bits-1:0] from_data,
    input  wire               to_clk,
    output wire[num_bits-1:0] to_data
);

    // first register the from_data in the from_clk domain
    logic [num_bits-1:0] from_data_ff;

    always @(posedge from_clk) begin
        from_data_ff <= from_data;
    end

    // the register into the to_clk domain twice 
    logic [num_bits-1:0] to_data_metastable;

    always @(posedge to_clk) begin
        to_data_metastable <= from_data_ff;
        to_data            <= to_data_metastable;
    end

endmodule

