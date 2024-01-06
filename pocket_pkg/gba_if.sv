 `timescale 1ns/1ps

 interface gba_if;

    logic            si_from_gba;
    logic            si_to_gba;
    logic            si_is_to_gba;
    logic            so_from_gba;
    logic            so_to_gba;
    logic            so_is_to_gba;
    logic            sck_from_gba;
    logic            sck_to_gba;
    logic            sck_is_to_gba;
    logic            sd_from_gba;
    logic            sd_to_gba;
    logic            sd_is_to_gba;

    // connect to top-level logic
    function automatic connect(
        ref logic port_si,
        ref logic port_si_dir,
        ref logic port_so,
        ref logic port_so_dir,
        ref logic port_sck,
        ref logic port_sck_dir,
        ref logic port_sd,
        ref logic port_sd_dir
    );
        port_si       = si_is_to_gba  ? si_to_gba  : 'z;
        si_from_gba   = port_si;
        port_si_dir   = si_is_to_gba;
        port_so       = so_is_to_gba  ? so_to_gba  : 'z;
        so_from_gba   = port_so;
        port_so_dir   = so_is_to_gba;
        port_sck      = sck_is_to_gba ? sck_to_gba : 'z;
        sck_from_gba  = port_sck;
        port_sck_dir  = sck_is_to_gba;
        port_sd       = sd_is_to_gba  ? sd_to_gba  : 'z;
        sd_from_gba   = port_sd;
        port_sd_dir   = sd_is_to_gba;

    endfunction

    // all inputs and the output lines set so setting them will cause a
    // multiple driven net error
    function automatic tie_off();
        si_is_to_gba  = 1'b0;
        si_to_gba     = 'x;
        so_is_to_gba  = 1'b0;
        so_to_gba     = 'x;
        sck_is_to_gba = 1'b0;
        sck_to_gba    = 'x;
        sd_is_to_gba  = 1'b0;
        sd_to_gba     = 'x;
    endfunction

    // si is input, so is output, sck is left
    // for the application to set and sd is unused
    // so set to input.
    // user needs to read sd, drive so and set
    // sck_is_to_gba reading or writing sck_from_gba
    // and sck_to_gba
    function automatic set_gba_mode();
        si_is_to_gba  = 1'b0;
        sd_to_gba     = 'x;
        so_is_to_gba  = 1'b1;
        sd_is_to_gba  = 1'b0;
        sd_to_gba     = 'x;
    endfunction

 endinterface
