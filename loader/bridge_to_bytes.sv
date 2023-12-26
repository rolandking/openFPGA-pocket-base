
// take the input from bridge which is a 32 bit word and write it out 8 bits
// at a time to memory

module bridge_to_bytes#(
    parameter logic[31:0] valid_bits = '1,
    parameter int read_cycles = 2
) (
    input logic         clk,

    input  logic [31:0]  bridge_addr,
    input  logic [31:0]  bridge_wr_data,
    input  logic         bridge_wr,
    output logic [31:0]  bridge_rd_data,
    input  logic         bridge_rd,

    output logic [31:0]  mem_address,
    output logic [7:0]   mem_wr_data,
    output logic         mem_wr,
    input  logic [7:0]   mem_rd_data,
    output logic         mem_rd,

    output logic         selected
);

    localparam int                    num_enables   = 4 * read_cycles;
    localparam logic[num_enables-1:0] read_enables  = {4{{(read_cycles-1){1'b0}},1'b1}};
    localparam logic[num_enables-1:0] write_enables = {{(num_enables-4){1'b0}},4'b1111};

    logic [num_enables-1:0]           enables;
    logic [31:0]                     write_cache, read_cache;
    logic [31:0]                     address;
    logic                            valid_address;
    logic                            is_read;
    logic                            enable;

    always_comb begin
        selected = (bridge_addr & ~valid_bits) == '0;
    end

    always_ff @(posedge clk) begin
        if((bridge_wr || bridge_rd) && selected) begin
            if(bridge_wr) begin
                enables <= write_enables;
                is_read <= 1'b0;
            end else begin
                enables <= read_enables;
                is_read <= 1'b1;
            end
            write_cache <= bridge_wr_data;
            address     <= bridge_addr;
        end else begin
            enables <= {1'b0, enables[num_enables-1:1]};
            if(enable) begin
                write_cache <= {write_cache[23:0], 8'hx};
                read_cache  <= {read_cache[23:0], mem_rd_data};
                address     <= address + 32'd1;
            end else begin
                read_cache[7:0] <= mem_rd_data;
            end
        end
    end

    always_comb begin
        mem_wr_data    = write_cache[31-:8];
        enable         = enables[0];
        mem_wr         = enable && ~is_read;
        mem_rd         = enable &&  is_read;
        mem_address    = address;
        bridge_rd_data = read_cache;
    end

endmodule
