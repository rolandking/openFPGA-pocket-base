`timescale 1ns/1ps

module bridge_core(
    bridge_if                                       bridge,

    // host_request_status - core provides a continuous status,
    // returning undefined will hold the request
    input  bridge_pkg::host_request_status_result_e core_status,

    // turn the reset_enter and reset_exit pulses into reset_n
    // which defaults to 0
    output logic                                    reset_n = 0,

    // command related
    host_dataslot_request_read_if                   host_dataslot_request_read,
    host_dataslot_request_write_if                  host_dataslot_request_write,
    host_dataslot_update_if                         host_dataslot_update,
    host_dataslot_complete_if                       host_dataslot_complete,
    host_rtc_update_if                              host_rtc_update,
    host_savestate_start_query_if                   host_savestate_start_query,
    host_savestate_load_query_if                    host_savestate_load_query,
    output logic                                    in_menu = 0,
    host_notify_cartridge_if                        host_notify_cartridge,
    output logic                                    docked = 0,
    host_notify_display_mode_if                     host_notify_display_mode
);

    bridge_driver_if cmd(bridge.clk), req(bridge.clk);

    bridge_driver bd(
        .bridge,
        .cmd,
        .req
    );

    bridge_cmd(
        .cmd,
        .core_status,
        .reset_n,
        .host_dataslot_request_read,
        .host_dataslot_request_write,
        .host_dataslot_update,
        .host_dataslot_complete,
        .host_rtc_update,
        .host_savestate_start_query,
        .host_savestate_load_query,
        .in_menu,
        .host_notify_cartridge,
        .docked,
        .host_notify_display_mode
    );

    // TEMP
    always_comb begin
        req.valid = '1;
        req.word  = 16'h140;
    end

endmodule
