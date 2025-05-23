setws d:/Project/FPGA/Design/TCL_project/Soc/ZynqA9/user/sdk/template
openhw d:/Project/FPGA/Design/TCL_project/Soc/ZynqA9/user/sdk/[getprojects -type hw]/system.hdf
connect
targets -set -filter {name =~ "ARM*#0"}
rst -system
namespace eval xsdb { 
    source d:/Project/FPGA/Design/TCL_project/Soc/ZynqA9/user/sdk/SDK/ps7_init.tcl
    ps7_init
}
fpga ./template.bit
dow  d:/Project/FPGA/Design/TCL_project/Soc/ZynqA9/user/sdk/template/Debug/template.elf
con
file delete d:/Project/Code/.prj/Digital-IDE/0.4.x/resources/script/xilinx/soft/program.tcl -force
