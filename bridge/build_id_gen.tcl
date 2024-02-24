proc generateBuildID_MIF {} {

	# Get the timestamp (see: http://www.altera.com/support/examples/tcl/tcl-date-time-stamp.html)
	set buildDate [ clock format [ clock seconds ] -format %Y%m%d ]
	set buildTime [ clock format [ clock seconds ] -format %H%M%S ]
	set buildUnique [expr {int(rand()*(4294967295))}]

    set_global_assignment -name VERILOG_MACRO "BUILD_DATE" -remove
    set_global_assignment -name VERILOG_MACRO "BUILD_TIME" -remove
    set_global_assignment -name VERILOG_MACRO "BUILD_UNIQUE_ID" -remove
    set_global_assignment -name VERILOG_MACRO "BUILD_DATE=$buildDate"
    set_global_assignment -name VERILOG_MACRO "BUILD_TIME=$buildTime"
    set_global_assignment -name VERILOG_MACRO "BUILD_UNIQUE_ID=$buildUnique"

	post_message "APF core build date/time generated: date:$buildDate / time: $buildTime / ID: $buildUnique"
}

generateBuildID_MIF
