`timescale 1ns/1ps

/*
 * Standard UART module. Supports tx and rx.
 * Requires a clock 8x the UART speed
 *
 * Supports only the standard 8bits, 1 stop, no parity
 */

 interface uart_if(
    input wire clk,
    input wire rst
 );

    logic tx;
    logic rx;

    logic [7:0] tx_data;
    logic       tx_data_valid;
    logic       tx_data_ack;

    logic [7:0] rx_data;
    logic       rx_data_valid;

    function automatic tie_off();
        tx_data       = '0;
        tx_data_valid = '0;
        tx            = '0;
    endfunction

 endinterface

 module uart_connect(
    input  wire  rx,
    output logic tx,

    uart_if      uart
 );
    always_comb begin
        uart.rx = rx;
        tx      = uart.tx;
    end
 endmodule

 module UART
 (
    uart_if  uart
);

    // bits to be shifted out including the start bits, we'll shift
    // 1's into it which will also be the stop bit
    logic [8:0] shift_out_data = '1;

    // we count down from 79 to 0 shifting each time we hit 0bxxx000 and can load
    // new data on '0. Shift in a 1 so we go high at the end of the cycle
    logic [6:0] shift_count = 0;

    // ack data at the end of any cycle the shift count is zero
    always_comb begin
        uart.tx_data_ack = ~uart.rst && (shift_count == '0);
    end

    always @(posedge uart.clk) begin
        if(uart.rst) begin
            shift_out_data <= '1;
            shift_count    <= '0;
        end else begin
            if(uart.tx_data_ack) begin
                if(uart.tx_data_valid) begin
                    shift_out_data <= { uart.tx_data, 1'b0 };
                    shift_count    <= 7'd79;
                end
            end else begin
                if(shift_count[2:0] == '0) begin
                    shift_out_data <= { 1'b1, shift_out_data[8:1] };
                end
                shift_count <= shift_count - 6'd1;
            end
        end
    end

    always_comb begin
        uart.tx = shift_out_data[0];
    end

    logic [8:0] shift_in_data;
    logic [2:0] pulse_count = 0;
    logic       last_level  = 1;

    always @(posedge uart.clk) begin
        uart.rx_data_valid <= 1'b0;
        if (uart.rx != last_level) begin
            pulse_count <= 3'd1;
            last_level  <= uart.rx;
        end else begin
            if(pulse_count == 3'd3) begin
                if(shift_in_data[0] == 1'b0 && uart.rx == 1'b1) begin
                    uart.rx_data_valid <= '1;
                    shift_in_data <= '1;
                    uart.rx_data  <= shift_in_data[8:1];
                end else begin
                    shift_in_data <= {uart.rx, shift_in_data[8:1]};
                end
            end

            pulse_count <= pulse_count + 3'd1;
        end
    end

endmodule
