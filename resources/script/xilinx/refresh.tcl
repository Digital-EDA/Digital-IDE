remove_files -quiet [get_files]
set xip_repo_paths {}
set_property ip_repo_paths $xip_repo_paths [current_project] -quiet
update_ip_catalog -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/ip/xfft_v9/xfft_v9.xci -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/bimpy.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/bimpy.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/bitreverse.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/bitreverse.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/butterfly.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/butterfly.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/convround.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/convround.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/hwbfly.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/hwbfly.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/ifftmain.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/ifftmain.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/ifftstage.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/ifftstage.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/laststage.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/laststage.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/longbimpy.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/longbimpy.v -quiet
add_files /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/qtrstage.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/src/ifft/qtrstage.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-Test/DIDEtemp/user/sim/FFT_IFFT_tb.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/FFT/Flow/FFT_IFFT.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/FFT/Flow/stage/BF_stage.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/FFT/Flow/stage/fft_stage.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/FFT/Flow/top/fft.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/FFT/Flow/top/ifft.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/FFT/Flow/utils/ftrans.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/FFT/Flow/utils/ftwiddle.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Memory/SRAM/Shift/shiftTaps.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/Complex/cmplAdsu.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/Complex/cmplMult.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Memory/SRAM/SDPRAM.v -quiet
add_files -fileset sim_1 /home/dide/project/Digital-IDE/library/Basic/Math/Advance/Complex/cordic.v -quiet
add_files -fileset constrs_1 /home/dide/project/Digital-Test/DIDEtemp/user/data -quiet
file delete /home/dide/project/Digital-IDE/resources/script/xilinx/refresh.tcl -force
