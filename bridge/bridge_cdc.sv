`timescale 1ns / 1ps

module bridge_cdc#(
    parameter int address_width = 2
)(
    bridge_if in,
    bridge_if out
);
    `STATIC_ASSERT(in.data_width == out.data_width, in and out data widths must be equal)

    // this works where in.data_width does not
    localparam int data_width = $bits(in.wr_data);
    typedef logic [data_width-1:0] data_t;

    // pass write data, address and the rd_write signals across
    // the cdc
    typedef struct packed {
        pocket::bridge_addr_t addr;
        data_t                wr_data;
        logic                 wr;
    } entry_t;

    entry_t write_entry, read_entry;
    logic read_valid;

    always_comb begin
        write_entry         = '0;
        write_entry.addr    = in.addr;
        write_entry.wr_data = in.wr_data;
        write_entry.wr      = in.wr;
    end

    cdc_register#(
        .data_width     ($bits(entry_t))
    ) cdcf (
        .wr_clk         (in.clk),
        .wr_data        (write_entry),
        .wr             (in.wr || in.rd),
        .wr_ready       (),

        .rd_clk         (out.clk),
        .rd_data        (read_entry),
        .rd             (read_valid)
    );

    always_comb begin
        out.addr    = read_entry.addr;
        out.wr_data = read_entry.wr_data;
        out.wr      = read_valid && read_entry.wr;
        out.rd      = read_valid && !read_entry.wr;
    end

    pocket::bridge_data_t out_rd_data_ff;
    always @(posedge out.clk) begin
        out_rd_data_ff <= out.rd_data;
    end

    // pass read data back across the domain
    cdc_register#(
        .data_width (data_width)
    ) cdcb (
        .wr_clk     (out.clk),
        .wr_data    (out.rd_data),
        .wr         (out_rd_data_ff != out.rd_data),

        .rd_clk     (in.clk),
        .rd_data    (in.rd_data)
    );

endmodule
