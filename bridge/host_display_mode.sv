`timescale 1ns / 1ps

module host_display_mode#(
    parameter logic supports_grayscale = 1'b0
) (
    input logic                   clk,
    host_notify_display_mode_if   host_notify_display_mode,

    video_if                      video_in,
    video_if                      video_out
);

    video_if in_internal(), out_internal();

    video_oneway in_oneway(
        .in     (video_in   ),
        .out    (in_internal)
    );

    video_oneway out_oneway(
        .in     (out_internal),
        .out    (video_out)
    );

    logic grayscale = 1'b0;
    always_ff @(posedge clk) begin
        if(host_notify_display_mode.valid) begin
            grayscale    <= host_notify_display_mode.param.grayscale && supports_grayscale;
            host_notify_display_mode.done <= '1;
        end else begin
            host_notify_display_mode.done <= '0;
        end
    end

    generate
        if(supports_grayscale) begin : gen_grayscale_convert
            logic [9:0] video_sum;
            always_comb begin
                `VIDEO_CONNECT_IN_OUT(in_internal, out_internal)
                video_sum = in_internal.rgb.red + in_internal.rgb.red + in_internal.rgb.green + in_internal.rgb.blue;
                if(grayscale) begin
                    out_internal.rgb.red   = video_sum[9:2];
                    out_internal.rgb.green = video_sum[9:2];
                    out_internal.rgb.blue  = video_sum[9:2];
                end
            end
        end else begin : gen_no_grayscale
            always_comb begin
                `VIDEO_CONNECT_IN_OUT(in_internal, out_internal)
            end
        end
    endgenerate

    always_comb begin
        host_notify_display_mode.response.affirm_grayscale = grayscale ?
            bridge_pkg::grayscale_supported : bridge_pkg::grayscale_not_supported;
    end

endmodule
