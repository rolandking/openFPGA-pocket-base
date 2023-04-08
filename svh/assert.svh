`ifndef ASSERT_SVH
`define ASSERT_SVH

`define STATIC_ASSERT(condition, message) initial assert (condition) else $error( "Assertion Failure: %s: %s", "message", "condition");

`endif
