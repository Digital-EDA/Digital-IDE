
if {[current_sim] != ""} {
    relaunch_sim -quiet
} else {
    launch_simulation -quiet
}

set curr_wave [current_wave_config]
if { [string length $curr_wave] == 0 } {
    if { [llength [get_objects]] > 0} {
        add_wave /
        set_property needs_save false [current_wave_config]
    } else {
        send_msg_id Add_Wave-1 WARNING "No top level signals found. Simulator will start without a wave window. If you want to open a wave window go to 'File->New Waveform Configuration' or type 'create_wave_config' in the TCL console."
    }
}
run 1us
file delete c:/Users/11934/Project/Digital-IDE/digital-ide/resources/script/xilinx/simulate.tcl -force
