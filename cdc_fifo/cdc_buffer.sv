`timescale 1ns/1ps

module cdc_buffer(
    input wire          write_clk,
    input wire  [15:0]  write_data,
    input wire          write_en,

    input wire          read_clk,
    output logic[15:0]  read_data
);

    typedef logic [4:0] address_t;

    address_t
        write_address = 5'd0,
        written_address = 5'd0,
        written_address_gray,
        read_address_gray,
        read_address;

    always_ff @(posedge write_clk) begin
        if(write_en) begin
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
    ) cdc_write_gray_to_read_clk (
        .from_clk   (write_clk),
        .from_data  (written_address_gray),

        .to_clk     (read_clk),
        .to_data    (read_address_gray)
    );

    gray_to_int#(
        .num_bits   ($bits(address_t))
    ) read_gray_to_addr (
        .gray_in    (read_address_gray),
        .int_out    (read_address)
    );


    (* ramstyle="mlab" *)
    logic [15:0] mem [0:31];

    always_ff @(posedge write_clk) begin
        if(write_en) begin
            mem[write_address] <= write_data;
        end
    end

    always_ff @(posedge read_clk) begin
        read_data <= mem[read_address];
    end

endmodule
