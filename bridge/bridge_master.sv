`timescale 1ns/1ps

module bridge_master #(
    parameter int                         NUM_SLAVES = 1,
    parameter pocket::bridge_addr_range_t ADDR_RANGES[NUM_SLAVES] = '{NUM_SLAVES
        {'{from_addr:'0,to_addr:'1}}
    }
) (
    bridge_if bridge_in,
    bridge_if bridge_out[NUM_SLAVES]
);

    `BRIDGE_CONNECT_MASTER_SLAVE(bridge_in,bridge_out[0])
endmodule