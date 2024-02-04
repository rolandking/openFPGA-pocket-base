
// take the input from bridge which is a 32 bit word and write it out 8 bits
// at a time to memory

module bridge_to_bytes#(
    parameter int read_cycles  = 2,
    parameter int write_cycles = 1
) (
    bridge_if            bridge,

    output logic [31:0]  mem_address,
    output logic [7:0]   mem_wr_data,
    output logic         mem_wr,
    input  logic [7:0]   mem_rd_data,
    output logic         mem_rd
);

    localparam int max_cycles = (read_cycles > write_cycles) ? read_cycles : write_cycles;

    /*
     * enables has one bit for each enable cycle plus one set bit for the
     * final cycle of the sequence
     */
    localparam int num_enables   = 4 * max_cycles + 1;
    typedef logic[num_enables-1:0] enable_t;
    localparam enable_t read_enables  = {
        {4*(max_cycles-read_cycles){1'b0}},
        1'b1,
        {4{{(read_cycles-1){1'b0}},1'b1}}
    };
    localparam enable_t write_enables  = {
        {4*(max_cycles-write_cycles){1'b0}},
        1'b1,
        {4{{(write_cycles-1){1'b0}},1'b1}}
    };

    enable_t      enables;
    logic [31:0]  write_cache, read_cache;
    logic [31:0]  address;
    logic         valid_address;
    logic         is_read;
    logic         enable, pre_enable;
    logic         last_cycle;
    logic         idle;

    always_ff @(posedge bridge.clk) begin
        if(idle) begin
            if(bridge.rd) begin
                enables <= read_enables;
                is_read <= 1'b1;
            end
            if(bridge.wr) begin
                enables <= write_enables;
                is_read <= 1'b0;
            end
            write_cache <= bridge.wr_data;
            address     <= bridge.addr;
        end else begin
            if(enable) begin
                write_cache <= {write_cache[23:0], 8'hx};
                read_cache  <= {read_cache[23:0], mem_rd_data};
            end else begin
                read_cache[7:0] <= mem_rd_data;
            end

            if(pre_enable) begin
                address <= address + 32'd1;
            end

            enables <= {1'b0, enables[num_enables-1:1]};
        end
    end

    always_comb begin
        mem_wr_data          = write_cache[31-:8];
        idle                 = (enables == '0);
        last_cycle           = (enables == num_enables'(1'b1));
        enable               = enables[0] && !last_cycle;
        pre_enable           = enables[1];
        mem_wr               = enable && ~is_read;
        mem_rd               = enable &&  is_read;
        mem_address          = address;
        bridge.rd_data       = read_cache;
    end

endmodule
