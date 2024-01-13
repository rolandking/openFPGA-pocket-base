 `timescale 1ns/1ps

 interface gba_if;

    wire             si_data_in;
    wire             si_data_out;
    pocket::dir_e    si_dir;
    wire             so_data_in;
    wire             so_data_out;
    pocket::dir_e    so_dir;
    wire             sck_data_in;
    wire             sck_data_out;
    pocket::dir_e    sck_dir;
    wire             sd_data_in;
    wire             sd_data_out;
    pocket::dir_e    sd_dir;

    // all inputs and the output lines set so setting them will cause a
    // multiple driven net error
    function automatic tie_off();
        si_dir       = pocket::DIR_IN;
        si_data_out  = 'x;
        so_dir       = pocket::DIR_IN;
        so_data_out  = 'x;
        sck_dir      = pocket::DIR_IN;
        sck_data_out = 'x;
        sd_dir       = pocket::DIR_IN;
        sd_data_out  = 'x;
    endfunction

    // si is input, so is output, sck is left
    // for the application to set and sd is unused
    // so set to input.
    // user needs to read sd, drive so and set
    // sck_is_to_gba reading or writing sck_from_gba
    // and sck_to_gba
    function automatic set_gba_mode();
        si_dir        = pocket::DIR_IN;
        si_data_out   = 'x;
        so_dir        = pocket::DIR_OUT;
        sd_dir        = pocket::DIR_IN;
        sd_data_out   = 'x;
    endfunction

 endinterface

 module gba_connect(
    inout wire port_si,
    inout wire port_si_dir,
    inout wire port_so,
    inout wire port_so_dir,
    inout wire port_sck,
    inout wire port_sck_dir,
    inout wire port_sd,
    inout wire port_sd_dir,

    gba_if     gba
 );
    tristate_buffer #(
        .lo_index   (0),
        .hi_index   (0)
    ) si_tb (
        .port       (port_si),
        .dir        (pocket::dir_e'(port_si_dir)),
        .data_in    (gba.si_data_in),
        .data_out   (gba.si_data_out)
    );

    tristate_buffer #(
        .lo_index   (0),
        .hi_index   (0)
    ) so_tb (
        .port       (port_so),
        .dir        (pocket::dir_e'(port_so_dir)),
        .data_in    (gba.so_data_in),
        .data_out   (gba.so_data_out)
    );

    tristate_buffer #(
        .lo_index   (0),
        .hi_index   (0)
    ) sck_tb (
        .port       (port_sck),
        .dir        (pocket::dir_e'(port_sck_dir)),
        .data_in    (gba.sck_data_in),
        .data_out   (gba.sck_data_out)
    );

    tristate_buffer #(
        .lo_index   (0),
        .hi_index   (0)
    ) sd_tb (
        .port       (port_sd),
        .dir        (pocket::dir_e'(port_sd_dir)),
        .data_in    (gba.sd_data_in),
        .data_out   (gba.sd_data_out)
    );

 endmodule
