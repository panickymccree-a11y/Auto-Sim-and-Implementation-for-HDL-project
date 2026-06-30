# Vivado XSim simulation template
# Run after sourcing {{VIVADO_HOME}}/settings64.bat or settings64.sh.
#
# Example:
#   vivado -mode batch -source vivado_sim.tcl

set project_root "{{PROJECT_ROOT}}"
set rtl_files [list {{RTL_FILES}}]
set tb_file "{{TB_FILE}}"
set tb_top "{{TB_TOP}}"
set sim_run_time "{{RUN_TIME}}"
set work_dir "{{SIM_WORK_DIR}}"
set log_dir "{{LOG_DIR}}"
set wdb_file "{{WDB_FILE}}"

file mkdir $work_dir
file mkdir $log_dir
cd $work_dir

set compile_failed 0

foreach src $rtl_files {
    if {![file exists $src]} {
        puts "SIM_ERROR: RTL file not found: $src"
        exit 2
    }
    if {[catch {exec xvlog -sv $src} result]} {
        puts $result
        set compile_failed 1
        break
    }
}

if {$compile_failed} {
    exit 1
}

if {![file exists $tb_file]} {
    puts "SIM_ERROR: testbench file not found: $tb_file"
    exit 2
}

if {[catch {exec xvlog -sv $tb_file} result]} {
    puts $result
    exit 1
}

if {[catch {exec xelab $tb_top -debug typical -s ${tb_top}_sim} result]} {
    puts $result
    exit 1
}

set run_tcl [file join $work_dir "xsim_run.tcl"]
set fh [open $run_tcl "w"]
puts $fh "log_wave -r /*"
puts $fh "run $sim_run_time"
puts $fh "quit"
close $fh

if {$wdb_file ne ""} {
    set xsim_cmd [list xsim ${tb_top}_sim -tclbatch $run_tcl -wdb $wdb_file]
} else {
    set xsim_cmd [list xsim ${tb_top}_sim -tclbatch $run_tcl]
}

if {[catch {exec {*}$xsim_cmd} result]} {
    puts $result
    exit 1
}

puts "SIM_OK: Vivado XSim completed"
exit 0
