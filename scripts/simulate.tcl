
set project_name [lindex $argv 0]

open_project tmp/$project_name.xpr

set_property simulator_language Verilog [current_project]

set_property top tb [get_filesets sim_1]

# Compile the design
launch_simulation

# Run behavioral simulation
run all

close_project
