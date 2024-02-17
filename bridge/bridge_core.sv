`timescale 1ns/1ps

module bridge_core(
    bus_if                                          bridge_cmd,
    bus_if                                          bridge_id,
    bus_if                                          bridge_dataslot,

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
    host_notify_display_mode_if                     host_notify_display_mode,

    core_ready_to_run_if                            core_ready_to_run,
    core_debug_event_log_if                         core_debug_event_log,
    core_dataslot_read_if                           core_dataslot_read,
    core_dataslot_write_if                          core_dataslot_write,
    core_dataslot_flush_if                          core_dataslot_flush,
    core_get_dataslot_filename_if                   core_get_dataslot_filename,
    core_open_dataslot_file_if                      core_open_dataslot_file
);

    bridge_driver_if cmd(bridge_cmd.clk), req(bridge_cmd.clk);

    bridge_driver bd(
        .bridge  (bridge_cmd),
        .cmd,
        .req
    );

    bridge_cmd bc(
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

    bridge_req br(
        .req,

        .core_ready_to_run,
        .core_debug_event_log,
        .core_dataslot_read,
        .core_dataslot_write,
        .core_dataslot_flush,
        .core_get_dataslot_filename,
        .core_open_dataslot_file
    );

    bridge_id bid (
        .bridge    (bridge_id)
    );

    bridge_dataslot bdslt (
        .bridge    (bridge_dataslot)
    );

endmodule
