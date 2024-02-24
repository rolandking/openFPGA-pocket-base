`timescale 1ns/1ps

module bridge_id (
    bus_if bridge
);

    always_ff @(posedge bridge.clk) begin

        // echo the rd back
        bridge.rd_data_valid <= bridge.rd;

        case(bridge.addr[3:2])
            2'b00: begin
                bridge.rd_data <= id_pkg::build_date;
            end
            2'b01: begin
                bridge.rd_data <= id_pkg::build_time;
            end
            2'b10: begin
                bridge.rd_data <= id_pkg::build_unique;
            end
            default: begin
            end
        endcase
    end

endmodule
