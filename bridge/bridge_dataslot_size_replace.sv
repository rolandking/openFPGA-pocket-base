
module bridge_dataslot_size_replace (
    bus_if                       bridge_dataslot_in,
    bus_if                       bridge_dataslot_out,

    input pocket::bridge_data_t  slot_size,

    input pocket::bridge_addr_t  slot_base_address,
    input logic                  slot_base_found
);

    bridge_pkg::dataslot_odd_t odd_slot;
    always_comb begin
        odd_slot                           = '0;
        odd_slot                           = bridge_dataslot_in.rd_data;
        odd_slot.size_lower                = slot_size;

        bridge_dataslot_out.addr           = bridge_dataslot_in.addr;
        bridge_dataslot_out.wr             = bridge_dataslot_in.wr;
        bridge_dataslot_out.wr_data        = bridge_dataslot_in.wr_data;
        bridge_dataslot_out.rd             = bridge_dataslot_in.rd;

        bridge_dataslot_in.rd_data_valid   = bridge_dataslot_out.rd_data_valid;
        bridge_dataslot_in.rd_data         = (bridge_dataslot_in.addr == {slot_base_address[31:3],3'b100}) ?
            odd_slot :
            bridge_dataslot_out.rd_data;
    end

endmodule
