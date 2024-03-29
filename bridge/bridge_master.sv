`timescale 1ns/1ps

/*
 * master module for the bridge. Splits it into NUM_LEAVES bridges each with
 * a defined address range.
 * keeps the address constant through the read or write cycle, gates the
 * read and write signals only to the module with that address in range.
 * multiplexes the read data back to the master given the address.
 *
 * Introduces one cycle of delay, bridge timing is not critical.
 */

module bridge_master #(
    parameter logic                       ENDIAN_LITTLE = 1'b0,
    parameter int                         NUM_LEAVES = 1,
    parameter pocket::bridge_addr_range_t ADDR_RANGES[NUM_LEAVES] = '{NUM_LEAVES
        {'{from_addr:'0,to_addr:'1}}
    }
) (
    output logic bridge_endian_little,
    bus_if       bridge_in,
    bus_if       bridge_out[NUM_LEAVES]
);

    `STATIC_ASSERT(bridge_in.data_width == 32, bridge data must be 32 bits)
    `STATIC_ASSERT(bridge_in.addr_width == 32, bridge addr must be 32 bits)

    always_comb bridge_endian_little = ENDIAN_LITTLE;

    pocket::bridge_addr_t addr_ff;
    pocket::bridge_data_t wr_data_ff;
    logic                 rd_ff, wr_ff, rd_ff_ff, wr_ff_ff;
    logic                 selected[NUM_LEAVES], selected_ff[NUM_LEAVES];

     generate
        genvar i;
        genvar j;
        for( i = 0 ; i < NUM_LEAVES ; i++ ) begin : gen_i
            for( j = 0 ; j < NUM_LEAVES ; j++ ) begin : gen_j
                `STATIC_ASSERT(
                    (i==j) ||
                    (ADDR_RANGES[i].from_addr > ADDR_RANGES[j].to_addr) ||
                    (ADDR_RANGES[j].from_addr > ADDR_RANGES[i].to_addr)
                , Address range overlap)
            end
        end
     endgenerate

     // cannot index an array of interfaces in a for() loop which is
     // needed to assign read_data so assign the bridge_out[*].rd_data
     // to an array of simple types and then use that
     pocket::bridge_data_t rd_data[NUM_LEAVES];
     logic                 rd_data_valid[NUM_LEAVES];

     always_ff @(posedge bridge_in.clk) begin
        if(bridge_in.wr || bridge_in.rd) begin
            addr_ff     <= bridge_in.addr;
            wr_data_ff  <= bridge_in.wr_data;
        end
        rd_ff       <= bridge_in.rd;
        wr_ff       <= bridge_in.wr;
        rd_ff_ff    <= rd_ff;
        wr_ff_ff    <= wr_ff;
        selected_ff <= selected;
     end

     always_comb begin
        for( int i = 0 ; i < NUM_LEAVES ; i++) begin
            selected[i] = (addr_ff >= ADDR_RANGES[i].from_addr) && (addr_ff <= ADDR_RANGES[i].to_addr);
        end
     end

     generate
        genvar slave;
        for( slave = 0 ; slave < NUM_LEAVES ; slave++) begin : gen_slave
            always_comb begin
                bridge_out[slave].addr    = addr_ff;
                bridge_out[slave].wr_data = wr_data_ff;
                bridge_out[slave].wr      = wr_ff_ff && selected_ff[slave];
                bridge_out[slave].rd      = rd_ff_ff && selected_ff[slave];
                rd_data[slave]            = bridge_out[slave].rd_data;
                rd_data_valid[slave]      = bridge_out[slave].rd_data_valid;
            end
        end
     endgenerate

     // the top-level bridge doesn't have a read_data_valid signal
     // so register the data.
     always_ff @(posedge bridge_in.clk) begin
        bridge_in.rd_data_valid <= '0;
        for( int i = 0 ; i < NUM_LEAVES ; i++ ) begin
            if(selected_ff[i] && rd_data_valid[i]) begin
                bridge_in.rd_data       <= rd_data[i];
                bridge_in.rd_data_valid <= rd_data_valid[i];
            end
        end
     end

endmodule
