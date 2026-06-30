onerror {
    echo "SIM_ERROR: ModelSim command failed"
    quit -code 1
}

set WORK_LIB "work"
set RTL_FILE "E:/自动仿真skill/skill_test/rtl/counter.v"
set TB_FILE "E:/自动仿真skill/skill_test/sim/tb_counter.sv"
set TRANSCRIPT_LOG "E:/自动仿真skill/skill_test/reports/modelsim_transcript.log"

if {[file exists $WORK_LIB]} {
    vdel -lib $WORK_LIB -all
}

vlib $WORK_LIB
vmap $WORK_LIB $WORK_LIB
transcript file $TRANSCRIPT_LOG

vlog -work $WORK_LIB +acc $RTL_FILE
vlog -work $WORK_LIB +acc $TB_FILE
vsim -c -voptargs=+acc ${WORK_LIB}.tb_counter
log -r /*
run 300 ns

transcript file ""
quit -code 0
