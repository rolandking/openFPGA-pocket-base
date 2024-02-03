`timescale 1ns/1ps

module bridge_id#(
    parameter int BUILD_DATE = `BUILD_DATE,
    parameter int BUILD_TIME = `BUILD_TIME,
    parameter int BUILD_UNIQUE_ID = `BUILD_UNIQUE_ID
)(
    bridge_if bridge
);

    always_ff @(posedge bridge.clk) begin
        case(bridge.addr[3:2])
            2'b00: begin
                bridge.rd_data <= BUILD_DATE;
            end
            2'b01: begin
                bridge.rd_data <= BUILD_TIME;
            end
            2'b10: begin
                bridge.rd_data <= BUILD_UNIQUE_ID;
            end
            default: begin
            end
        endcase
    end

endmodule