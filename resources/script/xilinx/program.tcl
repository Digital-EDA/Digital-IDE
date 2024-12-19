
open_hw -quiet
connect_hw_server -quiet
set found 0
foreach hw_target [get_hw_targets] {
    current_hw_target $hw_target
    open_hw_target -quiet
    foreach hw_device [get_hw_devices] {
        if { [string equal -length 6 [get_property PART $hw_device] xc7z020clg400-2] == 1 } {
            puts "------Successfully Found Hardware Target with a xc7z020clg400-2 device------ "
            current_hw_device $hw_device
            set found 1
        }
    }
    if {$found == 1} {break}
    close_hw_target
}   

#download the hw_targets
if {$found == 0 } {
    puts "******ERROR : Did not find any Hardware Target with a xc7z020clg400-2 device****** "
} else {
    set_property PROGRAM.FILE ./[current_project].bit [current_hw_device]
    program_hw_devices [current_hw_device] -quiet
    disconnect_hw_server -quiet
}
file delete /home/dide/project/Digital-IDE/resources/script/xilinx/program.tcl -force
