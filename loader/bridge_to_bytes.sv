
// take the input from bridge which is a 32 bit word and write it out 8 bits
// at a time to memory, do the same for reads and put the 32 bits back together

module bridge_to_bytes(
    // 32-bit data + address, address always 0bxxxxx... xxx00
    bus_if  bridge,
    // 8-bit data
    bus_if  mem
);

    `STATIC_ASSERT(bridge.data_width == 32, bridge data width must be 32)
    `STATIC_ASSERT(mem.data_width    ==  8, mem data width must be 8)

    logic idle;
    logic [31:2] bridge_addr_ff;
    logic [31:0] bridge_wr_data_ff;
    logic [1:0]  counter;
    // fill with 1's from the left as each byte of read data is
    // shifted into the buffer
    logic [3:0]  rd_bits;
    logic        is_read;

    typedef enum logic[1:0] {
        IDLE     = 2'b00,
        ADDR_OUT = 2'b01,
        WAIT_RD  = 2'b10
    } state_e;

    state_e state = IDLE;

    always @(posedge bridge.clk) begin

        // shift and count on every cycle, overridden for a new
        // read or write command
        bridge_wr_data_ff[31:8] <= bridge_wr_data_ff[23:0];
        counter                 <= counter + 2'd1;

        // shift valid read data into the 32bit buffer
        // should not need to gate with rd_bits[0] but for safety
        if(mem.rd_data_valid && ~rd_bits[0]) begin
            bridge.rd_data <= {bridge.rd_data[23:0], mem.rd_data};
            rd_bits        <= {1'b1, rd_bits[3:1]};
        end

        case(state)
            IDLE: begin
                if(bridge.rd || bridge.wr) begin
                    bridge_addr_ff    <= bridge.addr[31:2];
                    bridge_wr_data_ff <= bridge.wr_data;
                    is_read           <= bridge.rd;
                    counter           <= '0;
                    rd_bits           <= '0;
                    state             <= ADDR_OUT;
                end
            end
            ADDR_OUT: begin
                if(counter == 2'b11) begin
                    state <= is_read ? WAIT_RD : IDLE;
                end
            end
            WAIT_RD: begin
                if(rd_bits[0]) begin
                    state <= IDLE;
                end
            end
            default: begin
            end
        endcase
    end

    always_comb begin

        mem.rd               = '0;
        mem.wr               = '0;
        bridge.rd_data_valid = '0;

        case(state)
            IDLE: begin
            end
            ADDR_OUT: begin
                mem.rd =  is_read;
                mem.wr = ~is_read;
            end
            WAIT_RD: begin
                bridge.rd_data_valid = rd_bits[0];
            end
            default: begin
            end
        endcase
    end

    always_comb begin
        mem.addr    = {bridge_addr_ff, counter};
        mem.wr_data = bridge_wr_data_ff[31:24];
    end

endmodule
