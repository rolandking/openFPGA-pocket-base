`timescale 1ns/1ps

import pocket::bridge_addr_t;
import pocket::slot_id_t;

package bridge_pkg;

    /////////////////////////////////////////////////////////
    // host commands
    /////////////////////////////////////////////////////////

    typedef enum bridge_word_t {
        host_request_status         = 16'h0000,
        host_reset_enter            = 16'h0010,
        host_reset_exit             = 16'h0011,
        host_dataslot_request_read  = 16'h0080,
        host_dataslot_request_write = 16'h0082,
        host_dataslot_update        = 16'h008a,
        host_dataslot_complete      = 16'h008f,
        host_rtc_update             = 16'h0090,
        host_savestate_start_query  = 16'h00a0,
        host_savestate_load_query   = 16'h00a4,
        host_notify_menu_state      = 16'h00b0,
        host_notify_cartridge       = 16'h00b1,
        host_notify_docked_state    = 16'h00b2,
        host_notify_display_mode    = 16'h00b8
    } host_commands_e;


    /////////////////////////////////////////////////////////
    // host_request_status
    //  parameters - none
    //  result     - host_request_status_result_e
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef enum bridge_word_t {
        host_request_status_result_undefined = 16'h0000,
        host_request_status_result_booting   = 16'h0001,
        host_request_status_result_setup     = 16'h0002,
        host_request_status_result_idle      = 16'h0003,
        host_request_status_result_running   = 16'h0004
    } host_request_status_result_e;

    /*
     * default to
     * - booting until the pll is locked
     * - setup until the host de-asserts reset_n
     * - running after that
     */
    function automatic host_request_status_result_e host_request_status_result_default(
        logic pll_core_locked,
        logic reset_n
    );
        host_request_status_result_default = host_request_status_result_booting;
        if(pll_core_locked) begin
            host_request_status_result_default = host_request_status_result_setup;
        end
        if(reset_n) begin
            host_request_status_result_default = host_request_status_result_running;
        end
    endfunction



    /////////////////////////////////////////////////////////
    // host_reset_enter
    //  parameters - none
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////


    /////////////////////////////////////////////////////////
    // host_reset_exit
    //  parameters - none
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////


    /////////////////////////////////////////////////////////
    // host_dataslot_request_read
    //  parameters - host_dataslot_request_read_param_t
    //  result     - host_dataslot_requset_read_result_e
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic [15:0]  slot_id;
    } host_dataslot_request_read_param_t;

    function automatic host_dataslot_request_read_param_t host_dataslot_request_read_param_extract(
        bridge_param_t in
    );
        host_dataslot_request_read_param_t retval;
        // skip 16 : 127 -> 112
        retval.slot_id = in[111 : 96];
        // skip 96 : 95  ->   0
        return retval;
    endfunction

    typedef enum bridge_word_t {
        host_dataslot_request_read_result_ready_to_read = 16'h0000,
        host_dataslot_request_read_result_not_allowed   = 16'h0001,
        host_dataslot_request_read_result_check_later   = 16'h0002
    } host_dataslot_request_read_result_e;


    /////////////////////////////////////////////////////////
    // host_dataslot_request_write
    //  parameters - host_dataslot_request_write_param_t
    //  result     - host_dataslot_request_write_result_e
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic [15:0]  slot_id;
        logic [47:0]  expected_size;
    } host_dataslot_request_write_param_t;

    function automatic host_dataslot_request_write_param_t host_dataslot_request_write_param_extract(
        bridge_param_t in
    );
        host_dataslot_request_write_param_t retval;
        retval.expected_size[47:32] = in[127 : 112];
        retval.slot_id              = in[111 :  96];
        retval.expected_size[31:0]  = in[ 95 :  64];
        // skip 64 :  63 ->   0
        return retval;
    endfunction

    typedef enum bridge_word_t {
        host_dataslot_request_write_result_ready_to_write = 16'h0000,
        host_dataslot_request_write_result_not_allowed    = 16'h0001,
        host_dataslot_request_write_result_check_later    = 16'h0002
    } host_dataslot_request_write_result_e;


    /////////////////////////////////////////////////////////
    // host_dataslot_update
    //  parameters - host_dataslot_update_param_t
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic [15:0]  slot_id;
        logic [47:0]  expected_size;
    } host_dataslot_update_param_t;

    function automatic host_dataslot_update_param_t host_dataslot_update_param_extract(
        bridge_param_t in
    );
        host_dataslot_update_param_t retval;
        retval.expected_size[47:32] = in[127 : 112];
        retval.slot_id              = in[111 :  96];
        retval.expected_size        = in[ 95 :  64];
        // skip 64 :  63 ->   0
        return retval;
    endfunction


    /////////////////////////////////////////////////////////
    // host_dataslot_complete
    //  parameters - none
    //  result     - host_dataslot_complete_result_e
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef enum bridge_word_t {
        host_dataslot_complete_result_ok = 16'h0000
    } host_dataslot_complete_result_e;


    /////////////////////////////////////////////////////////
    // host_rtc_update
    //  parameters - host_rtc_update_param_t
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic [31:0]    seconds_since_1970;
        logic [31:0]    current_date_bcd;
        logic [27:24]   day_of_week;
        logic [23:0]    current_time_bcd;
    } host_rtc_update_param_t;

    function automatic host_rtc_update_param_t host_rtc_update_param_extract(
        bridge_param_t in
    );
        host_rtc_update_param_t retval;

        retval.seconds_since_1970 = in[127 : 96];
        retval.current_date_bcd   = in[ 95 : 64];
        // skip  4 : 63 -> 60
        retval.day_of_week        = in[ 59 : 56];
        retval.current_time_bcd   = in[ 55 : 32];
        // skip 32 : 31 ->  0

        return retval;
    endfunction


    /////////////////////////////////////////////////////////
    // host_savestate_start_query
    //  parameters - host_savestate_start_query_param_t
    //  result     - host_savestate_start_query_result_e
    //  response   - host_savestate_start_query_response_t
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic         valid;
    } host_savestate_start_query_param_t;

    function automatic host_savestate_start_query_param_t host_savestate_start_query_param_extract(
        bridge_param_t in
    );
        host_savestate_start_query_param_t retval;

        // skip 31 : 127 -> 97
        retval.valid = in[96];
        // skip 96 :  95 ->  0

        return retval;
    endfunction

    typedef enum bridge_word_t {
        host_savestate_start_query_result_ok    = 16'h0000,
        host_savestate_start_query_result_busy  = 16'h0001,
        host_savestate_start_query_result_done  = 16'h0002,
        host_savestate_start_query_result_error = 16'h0003
    } host_savestate_start_query_result_e;

    typedef struct packed {
        logic         created;
        logic [31:0]  address;
        logic [31:0]  size;
    } host_savestate_start_query_response_t;

    function automatic bridge_param_t host_savestate_start_query_response_expand(
        host_savestate_start_query_response_t in
    );
        return {31'hx, in.created, in.address, in.size, 32'hx};
    endfunction


    /////////////////////////////////////////////////////////
    // host_savestate_load_query
    //  parameters - host_savestate_load_query_param_t
    //  result     - host_savestate_load_query_result_e
    //  response   - host_savestate_load_query_response_t
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic         valid;
    } host_savestate_load_query_param_t;

    function automatic host_savestate_load_query_param_t host_savestate_load_query_param_extract(
        bridge_param_t in
    );
        host_savestate_load_query_param_t retval;

        // skip 31 : 127 -> 97
        retval.valid = in[96];
        // skip 96 :  95 ->  0

        return retval;
    endfunction

    typedef enum bridge_word_t {
    host_savestate_load_query_result_ok    = 16'h0000,
    host_savestate_load_query_result_busy  = 16'h0001,
    host_savestate_load_query_result_done  = 16'h0002,
    host_savestate_load_query_result_error = 16'h0003
    } host_savestate_load_query_result_e;

    typedef struct packed {
        logic         loaded;
        logic [31:0]  address;
        logic [31:0]  max_size;
    } host_savestate_load_query_response_t;

    function automatic bridge_param_t host_savestate_load_query_response_expand(
        host_savestate_load_query_response_t in
    );
        return {31'hx, in.loaded, in.address, in.max_size, 32'hx};
    endfunction


    /////////////////////////////////////////////////////////
    // host_notify_menu_state
    //  parameters - host_notify_menu_state_param_t
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic         in_menu;
    } host_notify_menu_state_param_t;

    function automatic host_notify_menu_state_param_t host_notify_menu_state_param_extract(
        bridge_param_t in
    );
        host_notify_menu_state_param_t retval;

        // skip 31 : 127 -> 97
        retval.in_menu = in[96];
        // skip 96 :  95 ->  0

        return retval;
    endfunction

    /////////////////////////////////////////////////////////
    // host_notify_cartridge
    //  parameters - host_notify_cartridge_param_t
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic          user_selected_play;
        logic          power_after_reset;
        logic [7:0]    boot_value;
    } host_notify_cartridge_param_t;

    function automatic host_notify_cartridge_param_t host_notify_cartridge_param_extract(
        bridge_param_t in
    );
        host_notify_cartridge_param_t retval;

        // skip  7 : 127 - 121
        retval.user_selected_play = in[120];
        // skip  7 : 119 - 113
        retval.power_after_reset  = in[112];
        // skip  8 : 111 - 104
        retval.boot_value         = in[103 : 96];
        // skip 64 : 95  - 0

        return retval;

    endfunction


    /////////////////////////////////////////////////////////
    // host_notify_docked_state
    //  parameters - host_notify_docked_state_param_t
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic         docked;
    } host_notify_docked_state_param_t;

    function automatic host_notify_docked_state_param_t host_notify_docked_state_param_extract(
        bridge_param_t in
    );

        host_notify_docked_state_param_t retval;
        // skip 31 : 127 -> 97
        retval.docked = in[96];
        // skip 96 :  95 ->  0

        return retval;
    endfunction


    /////////////////////////////////////////////////////////
    // host_notify_dcmdisplay_mode
    //  parameters - host_notify_display_mode_param_t
    //  result     - none
    //  response   - host_notify_display_mode_response_t
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic [15:8]   display_mode;
        logic          grayscale;
    } host_notify_display_mode_param_t;

    function automatic host_notify_display_mode_param_t host_notify_display_mode_param_extract(
        bridge_param_t in
    );
        host_notify_display_mode_param_t retval;
        // skip 16 : 127 - 112
        retval.display_mode = in[111 : 104];
        // skip  7 : 103 - 97
        retval.grayscale    = in[96];
        // skip 96 : 95  -  0

        return retval;
    endfunction

    typedef struct packed {
        logic [15:0]   affirm_greyscale;
    } host_notify_display_mode_response_t;

    function automatic bridge_param_t host_notify_display_mode_response_expand(
        host_notify_display_mode_response_t in
    );
        return {16'hx, in.affirm_greyscale, 96'hx};

    endfunction

    parameter logic [15:0] affirm_greyscale_allow = 16'h444d;


    /////////////////////////////////////////////////////////
    // core commands
    /////////////////////////////////////////////////////////

    typedef enum bridge_word_t {
        core_ready_to_run           = 16'h0140,
        core_debug_event_log        = 16'h0152,
        core_dataslot_read          = 16'h0180,
        core_dataslot_write         = 16'h0184,
        core_dataslot_flush         = 16'h0188,
        core_get_dataslot_filename  = 16'h0190,
        core_open_dataslot_file     = 16'h0192
    } core_commands_e;

    /////////////////////////////////////////////////////////
    // core_ready_to_run
    //  parameters - none
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////
    // core_debug_event_log
    //  parameters - core_debug_event_log_param_t
    //  result     - none
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        logic [15:0]   event_id;
    } core_debug_event_log_param_t;

    function automatic bridge_param_t core_debug_event_log_param_expand(
        core_debug_event_log_param_t in
    );
        return {16'hx, in.event_id, 96'hx};
    endfunction


    /////////////////////////////////////////////////////////
    // core_dataslot_read
    //  parameters - core_dataslot_read_param_t
    //  result     - core_dataslot_read_result_e
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        slot_id_t      slot_id;
        logic [31:0]   slot_offset;
        bridge_addr_t  bridge_addr;
    } core_dataslot_read_param_t;

    function automatic bridge_param_t core_dataslot_read_param_expand(
        core_dataslot_read_param_t in
    );
        return {16'hx, in.slot_id, in.slot_offset, in.bridge_addr, 32'hx};

    endfunction

    typedef enum bridge_word_t {
        core_dataslot_read_result_ok      = 16'h0000,
        core_dataslot_read_result_no_slot = 16'h0001,
        core_dataslot_read_result_error   = 16'h0002
    } core_dataslot_read_result_e;

    /////////////////////////////////////////////////////////
    // core_dataslot_write
    //  parameters - core_dataslot_write_param_t
    //  result     - core_dataslot_write_result_e
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        slot_id_t      slot_id;
        logic [31:0]   slot_offset;
        bridge_addr_t  bridge_addr;
        logic [31:0]   length;
    } core_dataslot_write_param_t;

    function automatic bridge_param_t core_dataslot_write_param_expand(
        core_dataslot_write_param_t in
    );
        return {16'hx, in.slot_id, in.slot_offset, in.bridge_addr, in.length};

    endfunction

    typedef enum bridge_word_t {
        core_dataslot_write_result_ok      = 16'h0000,
        core_dataslot_write_result_no_slot = 16'h0001,
        core_dataslot_write_result_error   = 16'h0002
    } core_dataslot_write_result_e;


    /////////////////////////////////////////////////////////
    // core_dataslot_flush
    //  parameters - core_dataslot_flush_param_t
    //  result     - core_dataslot_flush_result_e
    //  response   - none
    /////////////////////////////////////////////////////////

    typedef struct packed {
        slot_id_t slot_id;
    } core_dataslot_flush_param_t;

    function automatic bridge_param_t core_dataslot_flush_param_expand(
        core_dataslot_flush_param_t in
    );
        return {16'hx, in.slot_id, 96'hx};
    endfunction

    typedef enum bridge_word_t {
        core_dataslot_flush_result_ok      = 16'h0000,
        core_dataslot_flush_result_no_slot = 16'h0001
    } core_dataslot_flush_result_e;


    /////////////////////////////////////////////////////////
    // core_get_dataslot_filename
    //  parameters - core_get_dataslot_filename_param_t
    //  result     - core_get_dataslot_filename_result_e
    //  response   - (written to the get_dataslot_file_t
    //                in the pointer)
    /////////////////////////////////////////////////////////

    typedef struct packed {
        slot_id_t     slot_id;
        bridge_addr_t pointer;
    } core_get_dataslot_filename_param_t;

    function automatic bridge_param_t core_get_dataslot_filename_param_expand(
        core_get_dataslot_filename_param_t in
    );
        return {16'hx, in.slot_id, in.pointer, 64'hx};
    endfunction

    typedef enum bridge_word_t {
        core_get_dataslot_filename_result_ok      = 16'h0000,
        core_get_dataslot_filename_result_no_slot = 16'h0001
    } core_get_dataslot_filename_result_e;

    typedef struct packed {
        logic [255:0][7:0] file_path;
    } get_dataslot_file_t;

    /////////////////////////////////////////////////////////
    // core_open_dataslot_file
    //  parameters - core_open_dataslot_file_param_t
    //  result     - core_open_dataslot_file_param_e
    //  response   - (written to the open_dataslot_file_t
    //                in the pointer)
    /////////////////////////////////////////////////////////

    typedef struct packed {
        slot_id_t     slot_id;
        bridge_addr_t pointer;
    } core_open_dataslot_file_param_t;

    function automatic bridge_param_t core_open_dataslot_file_param_expand(
        core_open_dataslot_file_param_t in
    );
        return {16'hx, in.slot_id, in.pointer, 64'hx};
    endfunction

    typedef enum bridge_word_t {
    core_open_dataslot_file_result_ok       = 16'h0000,
    core_open_dataslot_file_result_created  = 16'h0001,
    core_open_dataslot_file_result_no_slot  = 16'h0002,
    core_open_dataslot_file_result_no_file  = 16'h0003,
    core_open_dataslot_file_result_bad_path = 16'h0004,
    core_open_dataslot_file_result_error    = 16'h0005
    } core_open_dataslot_file_result_e;

    typedef struct packed {
        logic [255:0][7:0]  file_path;
        logic [31:2]       _reserved_0;
        logic               resize_file;
        logic               create_if_not_exist;
        logic [31:0]        size;
    } open_dataslot_file_t;

endpackage
