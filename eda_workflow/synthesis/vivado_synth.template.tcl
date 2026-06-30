# Vivado synthesis template
# Run after sourcing {{VIVADO_HOME}}/settings64.bat or settings64.sh.
#
# Example:
#   vivado -mode batch -source vivado_synth.tcl

set project_name "{{PROJECT_NAME}}"
set project_root "{{PROJECT_ROOT}}"
set output_dir "{{OUTPUT_DIR}}"
set report_dir "{{REPORT_DIR}}"
set top_module "{{TOP_MODULE}}"
set part_name "{{PART}}"
set rtl_files [list {{RTL_FILES}}]
set xdc_files [list {{XDC_FILES}}]

file mkdir $output_dir
file mkdir $report_dir

create_project -force $project_name $output_dir -part $part_name
set_property target_language Verilog [current_project]

foreach src $rtl_files {
    if {![file exists $src]} {
        puts "SYNTH_ERROR: RTL file not found: $src"
        exit 2
    }
    add_files -norecurse $src
}

foreach xdc $xdc_files {
    if {$xdc ne ""} {
        if {![file exists $xdc]} {
            puts "SYNTH_ERROR: XDC file not found: $xdc"
            exit 2
        }
        add_files -fileset constrs_1 -norecurse $xdc
    }
}

update_compile_order -fileset sources_1

if {[catch {synth_design -top $top_module -part $part_name} synth_result]} {
    puts $synth_result
    report_compile_order -file [file join $report_dir "compile_order_failed.rpt"]
    exit 1
}

write_checkpoint -force [file join $output_dir "post_synth.dcp"]
report_utilization -file [file join $report_dir "synth_utilization.rpt"]
report_timing_summary -file [file join $report_dir "synth_timing_summary.rpt"]
report_methodology -file [file join $report_dir "synth_methodology.rpt"]

puts "SYNTH_OK: synthesis completed"
exit 0
