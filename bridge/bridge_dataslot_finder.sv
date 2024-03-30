`timescale 1ns/1ps

// monitors writes on the dataslot bus and host_dataslot_request_write
// commands to find
// 1. the base address for a slot with given ID
// 2. if this is being written with size zero

module bridge_dataslot_finder#(
    parameter pocket::slot_id_t SLOT_ID = 0
) (
    bus_if                         bridge_dataslot_in,
    host_dataslot_request_write_if host_dataslot_request_write,

    output pocket::bridge_addr_t   slot_base_address,
    output logic                   slot_base_found,
    output logic                   slot_size_zero
);

    bridge_pkg::dataslot_even_t dataslot_even;
    always_comb dataslot_even = bridge_dataslot_in.wr_data;

    logic slot_base_found_int                   = '0;
    logic slot_size_zero_int                    = '1;
    pocket::bridge_addr_t slot_base_address_int = '0;

    always @(posedge bridge_dataslot_in.clk) begin
        if(
            host_dataslot_request_write.valid &&
            host_dataslot_request_write.param.slot_id == SLOT_ID
        ) begin
            slot_size_zero_int <= (host_dataslot_request_write.param.expected_size == 0);
        end

        if(
            bridge_dataslot_in.wr                &&
            (bridge_dataslot_in.addr[2:0] == '0) &&
            (dataslot_even.slot_id == SLOT_ID)
        ) begin
            slot_base_address_int <= bridge_dataslot_in.addr;
            slot_base_found_int   <= '1;
        end
    end

    always_comb begin
        slot_base_found   = slot_base_found_int;
        slot_size_zero    = slot_size_zero_int;
        slot_base_address = slot_base_address_int;
    end


endmodule
