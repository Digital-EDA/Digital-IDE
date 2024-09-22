set_param general.maxThreads 8
create_project template /home/dide/project/Digital-Test/MipsDesign/prj/xilinx -part none -force
set_property SOURCE_SET source_1   [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1 -quiet
source /home/dide/project/Digital-IDE/resources/script/xilinx/refresh.tcl -quiet
file delete /home/dide/project/Digital-IDE/resources/script/xilinx/launch.tcl -force
