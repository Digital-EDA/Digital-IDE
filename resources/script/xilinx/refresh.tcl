remove_files -quiet [get_files]
set xip_repo_paths {}
set_property ip_repo_paths $xip_repo_paths [current_project] -quiet
update_ip_catalog -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/Controller/controller.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/Controller/controller.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Hazard/ForwardUnit.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Hazard/ForwardUnit.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Hazard/HDU.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Hazard/HDU.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Memory/dm_8k.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Memory/dm_8k.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Memory/im_8k.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Memory/im_8k.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/EX_MEM.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/EX_MEM.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/ID_EX.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/ID_EX.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/IF_ID.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/IF_ID.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/MEM_WB.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Pipe/MEM_WB.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/BU.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/BU.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/Ext.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/Ext.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/FU.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/FU.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/OR.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/OR.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/alu.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/alu.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/alu_ctrl.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/alu_ctrl.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/mux.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/mux.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/npc.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/npc.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/pc.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/pc.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/pc_add.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/pc_add.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/regfile.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/Utils/regfile.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/DataPath/datapath.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/DataPath/datapath.v -quiet
add_files /home/dide/project/Digital-Test/MipsDesign/src/MyCpu.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/src/MyCpu.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/MipsDesign/sim/testBench.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Apply/Comm/FDE/AGC/AGC.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Apply/Comm/MDS/Modulation/AnalogMod.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Apply/Comm/MDS/Modulation/DigitalMod.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/FixedPoint/accuml.v -quiet
add_files -fileset constrs_1 /home/dide/project/Digital-Test/MipsDesign -quiet
file delete /home/dide/project/Digital-IDE/resources/script/xilinx/refresh.tcl -force
