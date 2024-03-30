`timescale 1ns/1ps

// monitors writes on the dataslot bus and host_dataslot_request_write
// commands to find
// 1. the base address for a slot with given ID
// 2. if this is being written with size zero

module bridge_dataslot_find_and_replace#(
    parameter pocket::slot_id_t     SLOT_ID   = 0,
    parameter pocket::bridge_data_t SLOT_SIZE = 0
) (
    bus_if                         bridge_dataslot_in,
    bus_if                         bridge_dataslot_out,

    host_dataslot_request_write_if host_dataslot_request_write,

    output logic                   slot_base_found,
    output logic                   slot_size_zero
);

    pocket::bridge_addr_t slot_base_address;

    bridge_dataslot_finder#(
        .SLOT_ID (SLOT_ID)
    ) finder (
        .bridge_dataslot_in,
        .host_dataslot_request_write,
        .slot_base_address,
        .slot_base_found,
        .slot_size_zero
    );

    bridge_dataslot_size_replace#(
        .SLOT_SIZE  (SLOT_SIZE)
    ) replacer (
        .bridge_dataslot_in,
        .bridge_dataslot_out,
        .slot_base_address,
        .slot_base_found
    );

endmodule
