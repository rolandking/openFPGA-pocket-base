`timescale 1ns/1ps

module remapper#(
    parameter logic [31:0] BASE_ADDRESS   = 32'h0,
    parameter logic [31:0] MAP_ADDRESS    = 32'h0,
    parameter logic [15:0] MAP_LENGTH     = 16'd0
)(
    input  logic[31:0]     raw_address,
    output logic           selected,
    output logic[31:0]     mapped_address
);

    localparam logic [31:0] END_ADDRESS = BASE_ADDRESS + 32'(MAP_LENGTH);

    always_comb begin
        mapped_address  = raw_address - BASE_ADDRESS + MAP_ADDRESS;
        selected        = (raw_address >= BASE_ADDRESS) && (raw_address < END_ADDRESS);
    end


endmodule
