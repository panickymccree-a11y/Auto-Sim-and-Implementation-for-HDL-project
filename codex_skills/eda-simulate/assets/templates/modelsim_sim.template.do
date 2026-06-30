# ModelSim/QuestaSim simulation template
# Replace {{...}} placeholders before running.
#
# Example:
#   {{MODELSIM_HOME}}/win64/vsim -c -do modelsim_sim.do

onerror {
    echo "SIM_ERROR: ModelSim command failed"
    quit -code 1
}

set PROJECT_ROOT "{{PROJECT_ROOT}}"
set WORK_LIB "work"
set RTL_FILES [list {{RTL_FILES}}]
set TB_FILE "{{TB_FILE}}"
set TB_TOP "{{TB_TOP}}"
set RUN_TIME "{{RUN_TIME}}"
set TRANSCRIPT_LOG "{{TRANSCRIPT_LOG}}"
set VCD_FILE "{{VCD_FILE}}"

if {[file exists $WORK_LIB]} {
    vdel -lib $WORK_LIB -all
}

vlib $WORK_LIB
vmap $WORK_LIB $WORK_LIB

transcript file $TRANSCRIPT_LOG

foreach src $RTL_FILES {
    if {![file exists $src]} {
        echo "SIM_ERROR: RTL file not found: $src"
        quit -code 2
    }
    vlog -work $WORK_LIB +acc $src
}

if {![file exists $TB_FILE]} {
    echo "SIM_ERROR: testbench file not found: $TB_FILE"
    quit -code 2
}
vlog -work $WORK_LIB +acc $TB_FILE

vsim -voptargs=+acc ${WORK_LIB}.${TB_TOP}

log -r /*
add wave -r /*

if {$VCD_FILE ne ""} {
    vcd file $VCD_FILE
    vcd add -r /*
}

run $RUN_TIME

if {$VCD_FILE ne ""} {
    vcd flush
}

transcript file ""
quit -code 0
