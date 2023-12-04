`timescale 1ns/1ps

/*
 *  pass a signal through on enable and then hold it until the next cycle
 */


module enable_hold #(
    parameter int WIDTH = 1
) (
    input  wire clk,
    input  wire en,
    input  logic[WIDTH-1:0] in,
    output logic[WIDTH-1:0] out
 );

    logic [WIDTH-1:0] held;

    always_ff @(posedge clk) begin
        if(en) begin
            held <= in;
        end
    end

    always_comb begin
        out = en ? in : held;
    end

 endmodule
