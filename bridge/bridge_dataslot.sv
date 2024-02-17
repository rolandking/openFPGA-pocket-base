`timescale 1ns/1ps

module bridge_dataslot(
    bus_if  bridge
);

    // there are 32 dataslots each 2 32-bit words wide
    // so we need 32 * 4 * 2 = 256 bytes of memory to
    // store the data

    // memory
    logic [5:0] mem_addr;
    logic       mem_clk;
    pocket::bridge_data_t mem_read_data, mem_write_data;
    logic mem_wr;

    pocket::bridge_data_t mem [64];
    logic bridge_rd_ff;

    always_ff @(posedge bridge.clk) begin
        mem_read_data <= mem[mem_addr];
        bridge_rd_ff  <= bridge.rd;
        if(mem_wr) begin
            mem[mem_addr] <= mem_write_data;
        end
    end

    always_comb begin
        mem_addr             = bridge.addr[7:2];
        mem_write_data       = bridge.wr_data;
        mem_wr               = bridge.wr;
        bridge.rd_data       = mem_read_data;
        bridge.rd_data_valid = bridge_rd_ff;
    end

endmodule
