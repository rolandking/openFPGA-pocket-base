 `timescale 1ns/1ps

 interface bridge_if(
    input wire clk
 );
    pocket::bridge_addr_t addr;
    pocket::bridge_data_t wr_data;
    logic                 wr;
    pocket::bridge_data_t rd_data;
    logic                 rd;
 endinterface

 `define BRIDGE_CONNECT_MASTER_SLAVE_NO_READ(master,slave) \
    always_comb begin                                      \
        slave.addr          = master.addr;                 \
        slave.wr_data       = master.wr_data;              \
        slave.wr            = master.wr;                   \
        slave.rd            = master.wr;                   \
    end

 `define BRIDGE_CONNECT_MASTER_SLAVE_READ(master,slave)    \
    always_comb begin                                      \
        master.rd_data = slave.rd_data;                    \
    end

 `define BRIDGE_CONNECT_MASTER_SLAVE(master,slave)         \
    `BRIDGE_CONNECT_MASTER_SLAVE_NO_READ(master,slave)     \
    `BRIDGE_CONNECT_MASTER_SLAVE_READ(master,slave)
