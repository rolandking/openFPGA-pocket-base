`timescale 1ns/1ps

// monitors writes on the dataslot bus and host_dataslot_request_write
// commands to find
// 1. the base address for a slot with given ID
// 2. if this is being written with size zero

module bridge_dataslot_finder#(
    parameter logic [15:0] SLOT_ID = 0
) (
    bus_if                         bridge_dataslot,
    host_dataslot_request_write_if host_dataslot_request_write,

    output pocket::bridge_addr_t   slot_base_address,
    output logic                   slot_base_found,
    output logic                   slot_size_zero = '1
);

    bridge_pkg::dataslot_even_t dataslot_even;
    always_comb dataslot_even = bridge_dataslot.wr_data;

    always @(posedge bridge_dataslot.clk) begin
        if(
            host_dataslot_request_write.valid &&
            host_dataslot_request_write.param.slot_id == SLOT_ID
        ) begin
            slot_size_zero <= (host_dataslot_request_write.param.expected_size == 0);
        end

        if( bridge_dataslot.wr && bridge_dataslot.addr[2:0] == '0) begin
            slot_base_address <= bridge_dataslot.addr;
            slot_base_found   <= '1;
        end
    end


endmodule
