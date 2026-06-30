set work_dir "E:/自动仿真skill/skill_test/vivado/work"
set report_dir "E:/自动仿真skill/skill_test/reports"
set rtl_file "E:/自动仿真skill/skill_test/rtl/counter.v"
set part_name "xc7k325tffg900-2"

file mkdir $work_dir
file mkdir $report_dir

create_project -force skill_smoke $work_dir -part $part_name
add_files -norecurse $rtl_file
update_compile_order -fileset sources_1

synth_design -top counter -part $part_name
create_clock -period 10.000 -name clk [get_ports clk]
opt_design
place_design
route_design

report_utilization -file [file join $report_dir "vivado_smoke_utilization.rpt"]
report_timing_summary -file [file join $report_dir "vivado_smoke_timing_summary.rpt"]
write_checkpoint -force [file join $work_dir "post_route.dcp"]
puts "VIVADO_SMOKE_PASS"
exit 0
