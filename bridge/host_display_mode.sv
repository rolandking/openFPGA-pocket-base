`timescale 1ns / 1ps

module host_display_mode#(
    parameter logic supports_grayscale = 1'b0
) (
    input logic                   clk,
    host_notify_display_mode_if   host_notify_display_mode,

    output pocket::display_mode_e display_mode,
    output logic                  grayscale
);

    always_ff @(posedge clk) begin
        if(host_notify_display_mode.valid) begin
            display_mode <= host_notify_display_mode.param.display_mode;
            grayscale    <= host_notify_display_mode.param.grayscale && supports_grayscale;

            host_notify_display_mode.done <= '1;
        end else begin
            host_notify_display_mode.done <= '0;
        end
    end

    always_comb begin
        host_notify_display_mode.response.affirm_grayscale = grayscale ?
            bridge_pkg::grayscale_supported : bridge_pkg::grayscale_not_supported;
    end

endmodule
