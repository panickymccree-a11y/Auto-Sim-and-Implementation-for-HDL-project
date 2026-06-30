# Vivado implementation and timing template
# Run after sourcing {{VIVADO_HOME}}/settings64.bat or settings64.sh.
#
# Example:
#   vivado -mode batch -source vivado_impl.tcl

set project_name "{{PROJECT_NAME}}"
set output_dir "{{OUTPUT_DIR}}"
set report_dir "{{REPORT_DIR}}"
set top_module "{{TOP_MODULE}}"
set part_name "{{PART}}"
set synth_dcp "{{SYNTH_DCP}}"
set write_bitstream_enable {{WRITE_BITSTREAM_ENABLE}}

file mkdir $output_dir
file mkdir $report_dir

if {![file exists $synth_dcp]} {
    puts "IMPL_ERROR: synthesized checkpoint not found: $synth_dcp"
    exit 2
}

open_checkpoint $synth_dcp

if {[catch {opt_design} result]} {
    puts $result
    exit 1
}

if {[catch {place_design} result]} {
    puts $result
    exit 1
}

if {[catch {phys_opt_design} result]} {
    puts "IMPL_WARN: phys_opt_design failed or not applicable"
    puts $result
}

if {[catch {route_design} result]} {
    puts $result
    report_route_status -file [file join $report_dir "route_status_failed.rpt"]
    exit 1
}

write_checkpoint -force [file join $output_dir "post_route.dcp"]

report_route_status -file [file join $report_dir "route_status.rpt"]
report_utilization -file [file join $report_dir "impl_utilization.rpt"]
report_power -file [file join $report_dir "impl_power.rpt"]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -file [file join $report_dir "impl_timing_summary.rpt"]
report_timing -delay_type max -max_paths 50 -sort_by slack -file [file join $report_dir "timing_violations_max_paths.rpt"]

set timing_summary [report_timing_summary -return_string]
if {[regexp {WNS\(ns\)\s+([-0-9.]+)} $timing_summary -> wns]} {
    if {$wns < 0} {
        puts "TIMING_WARN: negative WNS detected: $wns ns"
    }
}

if {$write_bitstream_enable} {
    if {[catch {write_bitstream -force [file join $output_dir "${top_module}.bit"]} result]} {
        puts $result
        exit 1
    }
}

puts "IMPL_OK: implementation completed"
exit 0
