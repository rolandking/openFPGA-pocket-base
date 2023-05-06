
module uart_test(

    input  wire  clk,         // 1.8432mhz
    input  wire  rst,         // 

    output logic tx,
    input  wire  rx,          

    output logic [7:0] data,

    input  wire [15:0] frame_count,
    input  wire        frame_count_valid,
    output wire        frame_count_ack
);

logic [7:0] tx_data = '0;
logic       tx_data_valid = '0;
logic       tx_data_ack;

logic [7:0] rx_data;
logic       rx_data_valid;

// copy rx_data to the output
always @(posedge clk) begin
    if(rx_data_valid) begin
        data <= rx_data;
    end
end

// make a shift buffer of 0xaa {frame counter } 0x55 plus valid bits

logic [35:0] tx_data_shift = 0;

always_comb begin
    // if bit 8 is set then we still have data to send out the UART
    tx_data_valid = tx_data_shift[8];
    tx_data       = tx_data_shift[7:0];

    // if we have no data we will register in valid data on the next cycle
    frame_count_ack = ~tx_data_valid;
end

always @(posedge clk) begin
    if(tx_data_valid) begin
        if(tx_data_ack) begin
            tx_data_shift <= (tx_data_shift >> 9);
        end
    end else begin
        if(frame_count_valid) begin
            tx_data_shift <= {1'b1, 8'h55, 1'b1, frame_count[7:0], 1'b1, frame_count[15:8], 1'b1, 8'haa };
        end
    end
end

UART u1(
    .clk,
    .rst ('0),

    .tx,
    .rx,

    .tx_data,
    .tx_data_valid,
    .tx_data_ack,

    .rx_data,
    .rx_data_valid
);

endmodule
