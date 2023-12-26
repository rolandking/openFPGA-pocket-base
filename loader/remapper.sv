`timescale 1ns/1ps

module remapper#(
    parameter logic [31:0] BASE_ADDRESS   = 32'h0,
    parameter logic [31:0] MAP_ADDRESS    = 32'h0,
    parameter logic [15:0] MAP_LENGTH     = 16'd0,
    parameter logic        HAS_READ       = 1,
    parameter logic        HAS_WRITE      = 1,
    parameter int          NUM_MAPS       = 1
)(
    input  logic[31:1]     raw_address,
    output logic           selected,
    output logic           mapped_address
);

    localparam logic [31:0] END_ADDRESS = BASE_ADDRESS + 32'(MAP_LENGTH);

    always_comb begin
        mapped_address  = raw_address - BASE_ADDRESS + MAP_ADDRESS;
        selected        = (raw_address >= BASE_ADDRESS) && (raw_address < END_ADDRESS);
    end


endmodule
