`timescale 1ns/1ps

module cdc_buffer#(
    parameter int data_width
)(
    input wire                    wr_clk,
    input wire  [data_width-1:0]  wr_data,
    input wire                    wr,

    input wire                    rd_clk,
    output logic[data_width-1:0]  rd_data
);

    typedef logic [4:0] address_t;

    address_t
        write_address = 5'd0,
        written_address = 5'd0,
        written_address_gray,
        read_address_gray,
        read_address;

    always_ff @(posedge wr_clk) begin
        if(wr) begin
            written_address <= write_address;
            write_address   <= write_address + 5'd1;
        end
    end

    int_to_gray#(
        .num_bits   ($bits(address_t))
    ) write_addr_to_gray (
        .int_in     (written_address),
        .gray_out   (written_address_gray)
    );

    cdc_sync#(
        .num_bits   ($bits(address_t))
    ) cdc_write_gray_to_rd_clk (
        .from_clk   (wr_clk),
        .from_data  (written_address_gray),

        .to_clk     (rd_clk),
        .to_data    (read_address_gray)
    );

    gray_to_int#(
        .num_bits   ($bits(address_t))
    ) read_gray_to_addr (
        .gray_in    (read_address_gray),
        .int_out    (read_address)
    );


    (* ramstyle="mlab" *)
    logic [data_width-1:0] mem [32];

    always_ff @(posedge wr_clk) begin
        if(wr) begin
            mem[write_address] <= wr_data;
        end
    end

    always_ff @(posedge rd_clk) begin
        rd_data <= mem[read_address];
    end

endmodule
