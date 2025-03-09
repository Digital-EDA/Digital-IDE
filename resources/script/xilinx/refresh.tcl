remove_files -quiet [get_files]
set xip_repo_paths {}
set_property ip_repo_paths $xip_repo_paths [current_project] -quiet
update_ip_catalog -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/async_fifo.v -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/DPRAM.v -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/ecc_decode.sv -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/ecc_encode.sv -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/ecc_pkg.sv -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/hbram/hbram_controller.v -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/hbram/hbram_ctrl.v -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/hbram/hyper_bus.v -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/hbram_test.v -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/spi_slave.v -quiet
add_file d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/src/test.v -quiet
add_files -fileset constrs_1 d:/Project/FPGA/Design/TCL_project/Test/Efinity/user/data -quiet
file delete d:/Project/Code/.prj/Digital-IDE/resources/script/xilinx/refresh.tcl -force
