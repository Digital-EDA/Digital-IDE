set_param general.maxThreads 8
create_project template d:/Project/FPGA/Design/TCL_project/Test/Efinity/prj/xilinx -part none -force
set_property SOURCE_SET sources_1   [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1 -quiet
source d:/Project/Code/.prj/Digital-IDE/resources/script/xilinx/refresh.tcl -quiet
file delete d:/Project/Code/.prj/Digital-IDE/resources/script/xilinx/launch.tcl -force
