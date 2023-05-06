// Software License Agreement

// The software supplied herewith by Analogue Enterprises Limited (the "Company”),
// the Analogue Pocket Framework (“APF”), is provided and licensed to you, the
// Company's customer, solely for use in designing, testing and creating
// applications for use with Company's Products or Services.  The software is
// owned by the Company and/or its licensors, and is protected under applicable
// laws, including, but not limited to, U.S. copyright law. All rights are
// reserved. By using the APF code you are agreeing to the terms of the End User
// License Agreement (“EULA”) located at [https://www.analogue.link/pocket-eula]
// and incorporated herein by reference. To the extent any use of the APF requires 
// application of the MIT License or the GNU General Public License and terms of 
// this APF Software License Agreement and EULA are inconsistent with such license, 
// the applicable terms of the MIT License or the GNU General Public License, as 
// applicable, will prevail.

// THE SOFTWARE IS PROVIDED "AS-IS" AND WE EXPRESSLY DISCLAIM ANY IMPLIED
// WARRANTIES TO THE FULLEST EXTENT PROVIDED BY LAW, INCLUDING BUT NOT LIMITED TO,
// ANY WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE OR
// NON-INFRINGEMENT. TO THE EXTENT APPLICABLE LAWS PROHIBIT TERMS OF USE FROM
// DISCLAIMING ANY IMPLIED WARRANTY, SUCH IMPLIED WARRANTY SHALL BE LIMITED TO THE
// MINIMUM WARRANTY PERIOD REQUIRED BY LAW, AND IF NO SUCH PERIOD IS REQUIRED,
// THEN THIRTY (30) DAYS FROM FIRST USE OF THE SOFTWARE. WE CANNOT GUARANTEE AND
// DO NOT PROMISE ANY SPECIFIC RESULTS FROM USE OF THE SOFTWARE. WITHOUT LIMITING
// THE FOREGOING, WE DO NOT WARRANT THAT THE SOFTWARE WILL BE UNINTERRUPTED OR
// ERROR-FREE.  IN NO EVENT WILL WE BE LIABLE TO YOU OR ANY OTHER PERSON FOR ANY
// INDIRECT, CONSEQUENTIAL, EXEMPLARY, INCIDENTAL, SPECIAL OR PUNITIVE DAMAGES,
// INCLUDING BUT NOT LIMITED TO, LOST PROFITS ARISING OUT OF YOUR USE, OR
// INABILITY TO USE, THE SOFTWARE, EVEN IF WE HAVE BEEN ADVISED OF THE POSSIBILITY
// OF SUCH DAMAGES. UNDER NO CIRCUMSTANCES SHALL OUR LIABILITY TO YOU FOR ANY
// CLAIM OR CAUSE OF ACTION WHATSOEVER, AND REGARDLESS OF THE FORM OF THE ACTION,
// WHETHER ARISING IN CONTRACT, TORT OR OTHERWISE, EXCEED THE AMOUNT PAID BY YOU
// TO US, IF ANY, DURING THE 90 DAY PERIOD IMMEDIATELY PRECEDING THE DATE ON WHICH
// YOU FIRST ASSERT ANY SUCH CLAIM. THE FOREGOING LIMITATIONS SHALL APPLY TO THE
// FULLEST EXTENT PERMITTED BY APPLICABLE LAW.
//
// 6515C - Analogue Pocket main unit
// SOCRATES FPGA
// 
// 2022-08-17 Analogue

`default_nettype none

	wire    [23:0]  video_rgb;
    wire            video_rgb_clock;
    wire            video_rgb_clock_90;
    wire            video_de;
    wire            video_skip;
    wire            video_vs;
    wire            video_hs;

mf_ddio_bidir_12 isco (
    .oe ( 1'b1 ),
    .datain_h ( video_rgb[23:12] ),
    .datain_l ( video_rgb[11: 0] ),
    .outclock ( video_rgb_clock ),
    .padio ( scal_ddio_12 )
);

wire    [11:0]  scal_ddio_12;
assign scal_vid = scal_ddio_12;

mf_ddio_bidir_12 iscc (
    .oe ( 1'b1 ),
    .datain_h ( {video_vs, video_hs, video_de, video_skip} ),
    .datain_l ( {video_vs, video_hs, video_de, video_skip} ),
    .outclock ( video_rgb_clock ),
    .padio ( scal_ddio_ctrl )
);

wire    [3:0]   scal_ddio_ctrl;
assign scal_vs = scal_ddio_ctrl[3];
assign scal_hs = scal_ddio_ctrl[2];
assign scal_de = scal_ddio_ctrl[1];
assign scal_skip = scal_ddio_ctrl[0];

mf_ddio_bidir_12 isclk(
    .oe ( 1'b1 ),
    .datain_h ( 1'b1 ),
    .datain_l ( 1'b0 ),
    .outclock ( video_rgb_clock_90 ),
    .padio ( scal_clk )
);



// controller data (pad) controller.
    wire    [31:0]  cont1_key;
    wire    [31:0]  cont2_key;
    wire    [31:0]  cont3_key;
    wire    [31:0]  cont4_key;
    wire    [31:0]  cont1_joy;
    wire    [31:0]  cont2_joy;
    wire    [31:0]  cont3_joy;
    wire    [31:0]  cont4_joy;
    wire    [15:0]  cont1_trig;
    wire    [15:0]  cont2_trig;
    wire    [15:0]  cont3_trig;
    wire    [15:0]  cont4_trig;
        
io_pad_controller ipm (
    .clk            ( clk_74a ),
    .reset_n        ( reset_n ),

    .pad_1wire      ( bridge_1wire ),
        
    .cont1_key          ( cont1_key ),
    .cont2_key          ( cont2_key ),
    .cont3_key          ( cont3_key ),
    .cont4_key          ( cont4_key ),
    .cont1_joy          ( cont1_joy ),
    .cont2_joy          ( cont2_joy ),
    .cont3_joy          ( cont3_joy ),
    .cont4_joy          ( cont4_joy ),
    .cont1_trig         ( cont1_trig ),
    .cont2_trig         ( cont2_trig ),
    .cont3_trig         ( cont3_trig ),
    .cont4_trig         ( cont4_trig )
);
    
    
// virtual pmp bridge
    wire            bridge_endian_little;
    wire    [31:0]  bridge_addr;
    wire            bridge_rd;
    wire    [31:0]  bridge_rd_data;
    wire            bridge_wr;
    wire    [31:0]  bridge_wr_data;

io_bridge_peripheral ibs (

    .clk            ( clk_74a ),
    .reset_n        ( reset_n ),
    
    .endian_little  ( bridge_endian_little ),
    
    .pmp_addr       ( bridge_addr ),
    .pmp_rd         ( bridge_rd ),
    .pmp_rd_data    ( bridge_rd_data ),
    .pmp_wr         ( bridge_wr ),
    .pmp_wr_data    ( bridge_wr_data ),

    .phy_spimosi    ( bridge_spimosi ),
    .phy_spimiso    ( bridge_spimiso ),
    .phy_spiclk     ( bridge_spiclk ),
    .phy_spiss      ( bridge_spiss )

);


///////////////////////////////////////////////////
// instantiate the user core top-level

core_top ic (

    // physical connections 
    //
    .clk_74a                ( clk_74a ),
    .clk_74b                ( clk_74b ),

    .cart_tran_bank2        ( cart_tran_bank2 ),
    .cart_tran_bank2_dir    ( cart_tran_bank2_dir ),
    .cart_tran_bank3        ( cart_tran_bank3 ),
    .cart_tran_bank3_dir    ( cart_tran_bank3_dir ),
    .cart_tran_bank1        ( cart_tran_bank1 ),
    .cart_tran_bank1_dir    ( cart_tran_bank1_dir ),
    .cart_tran_bank0        ( cart_tran_bank0 ),
    .cart_tran_bank0_dir    ( cart_tran_bank0_dir ),
    .cart_tran_pin30        ( cart_tran_pin30 ),
    .cart_tran_pin30_dir    ( cart_tran_pin30_dir ),
    .cart_pin30_pwroff_reset ( cart_pin30_pwroff_reset ),   
    .cart_tran_pin31        ( cart_tran_pin31 ),
    .cart_tran_pin31_dir    ( cart_tran_pin31_dir ),

    .port_ir_rx             ( port_ir_rx ),
    .port_ir_tx             ( port_ir_tx ),
    .port_ir_rx_disable     ( port_ir_rx_disable ),
    
    .port_tran_si           ( port_tran_si ),
    .port_tran_si_dir       ( port_tran_si_dir ),
    .port_tran_so           ( port_tran_so ),
    .port_tran_so_dir       ( port_tran_so_dir ),
    .port_tran_sck          ( port_tran_sck ),
    .port_tran_sck_dir      ( port_tran_sck_dir ),
    .port_tran_sd           ( port_tran_sd ),
    .port_tran_sd_dir       ( port_tran_sd_dir ),
 
    .cram0_a                ( cram0_a ),
    .cram0_dq               ( cram0_dq ),
    .cram0_wait             ( cram0_wait ),
    .cram0_clk              ( cram0_clk ),
    .cram0_adv_n            ( cram0_adv_n ),
    .cram0_cre              ( cram0_cre ),
    .cram0_ce0_n            ( cram0_ce0_n ),
    .cram0_ce1_n            ( cram0_ce1_n ),
    .cram0_oe_n             ( cram0_oe_n ),
    .cram0_we_n             ( cram0_we_n ),
    .cram0_ub_n             ( cram0_ub_n ),
    .cram0_lb_n             ( cram0_lb_n ),
    .cram1_a                ( cram1_a ),
    .cram1_dq               ( cram1_dq ),
    .cram1_wait             ( cram1_wait ),
    .cram1_clk              ( cram1_clk ),
    .cram1_adv_n            ( cram1_adv_n ),
    .cram1_cre              ( cram1_cre ),
    .cram1_ce0_n            ( cram1_ce0_n ),
    .cram1_ce1_n            ( cram1_ce1_n ),
    .cram1_oe_n             ( cram1_oe_n ),
    .cram1_we_n             ( cram1_we_n ),
    .cram1_ub_n             ( cram1_ub_n ),
    .cram1_lb_n             ( cram1_lb_n ),

    .dram_a                 ( dram_a ),
    .dram_ba                ( dram_ba ),
    .dram_dq                ( dram_dq ),
    .dram_dqm               ( dram_dqm ),
    .dram_clk               ( dram_clk ),
    .dram_cke               ( dram_cke ),
    .dram_ras_n             ( dram_ras_n ),
    .dram_cas_n             ( dram_cas_n ),
    .dram_we_n              ( dram_we_n ),
    
    .sram_a                 ( sram_a ),
    .sram_dq                ( sram_dq ),
    .sram_oe_n              ( sram_oe_n ),
    .sram_we_n              ( sram_we_n ),
    .sram_ub_n              ( sram_ub_n ),
    .sram_lb_n              ( sram_lb_n ),

    .vblank                 ( vblank ),
    .vpll_feed              ( vpll_feed ),
    
    .dbg_tx                 ( dbg_tx ),
    .dbg_rx                 ( dbg_rx ),
    .user1                  ( user1 ),
    .user2                  ( user2 ),
    
    .aux_sda                ( aux_sda ),
    .aux_scl                ( aux_scl ),    
    
    
    // logical connections with user core
    //
    .video_rgb              ( video_rgb ),
    .video_rgb_clock        ( video_rgb_clock ),
    .video_rgb_clock_90     ( video_rgb_clock_90 ),
    .video_de               ( video_de ),
    .video_skip             ( video_skip ),
    .video_vs               ( video_vs ),
    .video_hs               ( video_hs ),

    .audio_mclk             ( scal_audmclk ),
    .audio_adc              ( scal_audadc ),
    .audio_dac              ( scal_auddac ),
    .audio_lrck             ( scal_audlrck ),
    
    .bridge_endian_little   ( bridge_endian_little ),
    .bridge_addr            ( bridge_addr ),
    .bridge_rd              ( bridge_rd ),
    .bridge_rd_data         ( bridge_rd_data ), 
    .bridge_wr              ( bridge_wr ),
    .bridge_wr_data         ( bridge_wr_data ),
    
    .cont1_key              ( cont1_key ),
    .cont2_key              ( cont2_key ),
    .cont3_key              ( cont3_key ),
    .cont4_key              ( cont4_key ),
    .cont1_joy              ( cont1_joy ),
    .cont2_joy              ( cont2_joy ),
    .cont3_joy              ( cont3_joy ),
    .cont4_joy              ( cont4_joy ),
    .cont1_trig             ( cont1_trig ),
    .cont2_trig             ( cont2_trig ),
    .cont3_trig             ( cont3_trig ),
    .cont4_trig             ( cont4_trig )
    
);

endmodule

