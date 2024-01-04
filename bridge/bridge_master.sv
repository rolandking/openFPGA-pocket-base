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
    },

    // temporary parameter to deal with core_bridge's failure to adhere
    // to the spec. Delay the read signal by one cycle
    parameter logic                       DELAY_RD = 1
) (
    output logic bridge_endian_little,
    bridge_if    bridge_in,
    bridge_if    bridge_out[NUM_LEAVES]
);

    always_comb bridge_endian_little = ENDIAN_LITTLE;

     pocket::bridge_addr_t addr_ff;
     pocket::bridge_data_t wr_data_ff;
     logic                 rd_ff, wr_ff;
     logic                 selected[NUM_LEAVES], selected_ff[NUM_LEAVES];

     // FIXME get rid of this crap
     logic rd_pipe[3];
     always @(posedge bridge_in.clk) begin
        rd_pipe[2] <= rd_pipe[1];
        rd_pipe[1] <= rd_pipe[0];
        rd_pipe[0] <= rd_ff;
     end

     wire rd_trigger = DELAY_RD ? rd_pipe[2] : rd_ff;

     // FIXME get rid of this crap

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

     always_ff @(posedge bridge_in.clk) begin
        if(bridge_in.wr || bridge_in.rd) begin
            addr_ff     <= bridge_in.addr;
            wr_data_ff  <= bridge_in.wr_data;
            selected_ff <= selected;
        end
        rd_ff <= bridge_in.rd;
        wr_ff <= bridge_in.wr;
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
                bridge_out[slave].wr      = wr_ff && selected_ff[slave];
                bridge_out[slave].rd      = rd_trigger && selected_ff[slave];
                rd_data[slave]            = bridge_out[slave].rd_data;
            end
        end
     endgenerate

     always_comb begin
        bridge_in.rd_data = 'x;
        for( int i = 0 ; i < NUM_LEAVES ; i++ ) begin
            if(selected_ff[i]) begin
                bridge_in.rd_data = rd_data[i];
            end
        end
     end

endmodule
