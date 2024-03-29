`timescale 1ns/1ps

module cdc_fifo #(
    parameter int address_width = 4,
    parameter int data_width = 32

) (
    input  wire                   wr_clk,           // clock for data being written to the FIFO
    input  wire [data_width-1:0]  wr_data,          // data to be pushed into the fifo
    input  wire                   wr,               // valid signal for data, data will be pushed if write is ready
    output logic                  wr_ready,         // FIFO can receive data

    input wire                    rd_clk,           // clock for data being read fro the FIFO
    output logic [data_width-1:0] rd_data,          // data to be read, valid when rd is asserted
    output logic                  rd,               // read data is valid
    input  wire                   rd_ack            // ack the read data
);

    localparam int num_entries = ( 1 << address_width );
    typedef logic [data_width-1:0] data_t;
    typedef logic [address_width-1:0] address_t;

    // add one bit to the address for the pointers to differentiate full and/ empty
    typedef logic [address_width:0] pointer_t;

    // infer a simple dual port memory with async clocks
    // address and data defines. mem at the end
    address_t mem_write_address, mem_read_address;

    // write
    pointer_t
        write_p, write_p_next,      // write pointer for the write module's use
        write_p_gray,               // write_p converted to gray
        write_p_gray_cdc,           // write_p_gray crossed into read clock
        write_p_cdc;                // write_p decoded in read clock

    // read
    pointer_t
        read_p, read_p_next,        // read pointers for the read module's use
        read_p_gray,                // read_p converted to gray
        read_p_gray_cdc,            // read_p_gray crossed into write clock
        read_p_cdc;                 // read_p decoded in write clock


    // we can write unless the write pointer has wrapped
    always_comb begin
        // pointers have an extra bit which counts wrap arounds modulus 2. So
        // if the two pointers are equal, the FIFO is empty, if the lower
        // address are equal but the high bit is different, the fifo is full
        wr_ready       = ( write_p != {~read_p_cdc[address_width], read_p_cdc[address_width-1:0]} );
        write_p_next      =   write_p + {{address_width{1'b0}}, 1'b1};
        mem_write_address =   write_p[address_width-1:0];
    end

    // infer the memory
    data_t mem[num_entries];

    always @(posedge wr_clk) begin
        // increment the address on write
        if(wr_ready && wr) begin
            mem[mem_write_address] <= wr_data;
            write_p                <= write_p_next;
        end
    end

    logic rd_ready;
    always_comb begin
        // if the extended pointers are equal the FIFO is empty, else just/ read
        rd_ready               = (read_p != write_p_cdc);
        read_p_next            =  read_p + {{address_width{1'b0}}, 1'b1};
        mem_read_address       = read_p[address_width-1:0];
    end

    always @(posedge rd_clk) begin
        // if data is acked move the pointer.
        // ACK is sampled at the same edge VALID is set, you are expected to
        // know before the valid cycle whether you will consume data and
        // pre-set ACK. If during the valid cycle you decide you can take no
        // more data then deassert ACK
        if(rd_ready && rd_ack) begin
            read_p <= read_p_next;
        end
        rd_data <= mem[mem_read_address];
        rd      <= rd_ready;
    end

    // gray encode the write pointer, pass it over the cdc and unencode it/ again
    // write_p --> write_p_gray -> write_p_gray_cdc -> write_p_cdc
    // the cdc_sync module registers the input once so that delays the
    // increment of the write pointer sent to the read clock so you can
    // guarantee the write succeeds
    int_to_gray#(
        .num_bits   ($bits(pointer_t))
    ) write_p_int_to_gray (
        .int_in     (write_p),
        .gray_out   (write_p_gray)
    );

    cdc_sync#(
        .num_bits   ($bits(pointer_t))
    ) cdc_write_gray_to_rd_clk (
        .from_clk   (wr_clk),
        .from_data  (write_p_gray),

        .to_clk     (rd_clk),
        .to_data    (write_p_gray_cdc)
    );

    gray_to_int#(
        .num_bits   ($bits(pointer_t))
    ) write_p_gray_to_int (
        .gray_in    (write_p_gray_cdc),
        .int_out    (write_p_cdc)
    );

    // gray encode the read pointer, pass it over the cdc and unencode it/ again
    // read_p --> read_p_gray -> read_p_gray_cdc -> read_p_cdc
    // the cdc_sync module registers the input once so that delays the
    // increment of the read pointer sent to the write clock so you can
    // guarantee the read succeeds
    int_to_gray#(
        .num_bits   ($bits(pointer_t))
    ) read_p_int_to_gray (
        .int_in     (read_p),
        .gray_out   (read_p_gray)
    );

    cdc_sync#(
        .num_bits   ($bits(pointer_t))
    ) cdc_read_gray_to_wr_clk (
        .from_clk   (rd_clk),
        .from_data  (read_p_gray),

        .to_clk     (wr_clk),
        .to_data    (read_p_gray_cdc)
    );

    gray_to_int#(
        .num_bits   ($bits(pointer_t))
    ) read_p_gray_cdc_to_int (
        .gray_in    (read_p_gray_cdc),
        .int_out    (read_p_cdc)
    );


endmodule
