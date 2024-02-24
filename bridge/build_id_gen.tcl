proc generateBuildID_MIF {} {

	# Get the timestamp (see: http://www.altera.com/support/examples/tcl/tcl-date-time-stamp.html)
	set buildDate [ clock format [ clock seconds ] -format %Y%m%d ]
	set buildTime [ clock format [ clock seconds ] -format %H%M%S ]
	set buildUnique [expr {int(rand()*(4294967295))}]

	# Create a Verilog file for output
    file mkdir output_files
	set outputFileName "output_files/id_pkg.sv"
	set outputFile [open $outputFileName "w"]

	# Output the Verilog source
	puts $outputFile "// Build ID package"
	puts $outputFile ""
	puts $outputFile "package id_pkg;"
	puts $outputFile ""
	puts $outputFile "    parameter int build_date   = 32'h$buildDate;"
	puts $outputFile "    parameter int build_time   = 32'h$buildTime;"
	puts $outputFile "    parameter int build_unique = 32'd$buildUnique;"
	puts $outputFile ""
	puts $outputFile "endpackage"
	puts $outputFile ""
	close $outputFile

	post_message "APF core build date/time generated: date:$buildDate / time: $buildTime / ID: $buildUnique"
}

generateBuildID_MIF
