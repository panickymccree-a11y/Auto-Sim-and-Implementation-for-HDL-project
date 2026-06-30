---
name: eda-simulate
description: Run FPGA/RTL functional simulation with ModelSim/QuestaSim or Vivado XSim. Use when the user asks to create or run a Verilog/SystemVerilog/VHDL testbench, verify RTL behavior, inspect waveforms, extract signal values, debug simulation compile/runtime errors, or compare ModelSim and Vivado XSim simulation options.
---

# EDA Simulate

Use this skill to turn a natural-language RTL simulation request into a reproducible command-line simulation flow.

## Tool Choice

Default to ModelSim/QuestaSim when both simulators are available. It usually gives richer command-line control, `.do` scripting, recursive signal logging, waveform control, generic/parameter overrides, and interactive Tcl debug.

Use Vivado XSim when the user explicitly requests it, ModelSim/QuestaSim is unavailable, or the design depends on Vivado simulation libraries/IP behavior.

## Inputs To Gather

Collect or infer these before running:

| Input | Requirement |
|---|---|
| DUT sources | RTL file paths or filelist |
| DUT top | Top module/entity name |
| Testbench top | Usually `tb_<dut>` |
| Clock/reset | Period/frequency, reset polarity, reset duration |
| Stimulus | User-defined, file-driven, or generated default stimulus |
| Checks | Expected values, ranges, assertions, or pass/fail conditions |
| Runtime | Fixed time or event-driven stop condition |
| Tool path | `{{MODELSIM_HOME}}`, `{{VIVADO_HOME}}`, or tools already on `PATH` |

Ask for missing inputs only when they cannot be inferred safely from RTL, filelists, or existing scripts.

## Workflow

1. Parse the request into a short simulation configuration summary.
2. Read RTL when port lists, widths, reset polarity, or module names are missing.
3. Generate or update `tb_<dut>.sv`.
4. Copy and fill the appropriate template:
   - ModelSim/QuestaSim: `assets/templates/modelsim_sim.template.do`
   - Vivado XSim: `assets/templates/vivado_sim.template.tcl`
   - Generic testbench: `assets/templates/tb_template.sv`
5. Run the simulator in CLI/batch mode.
6. Parse compile/runtime output.
7. If simulation passes, extract requested signal values, waveform paths, and log summary.
8. Return a concise report with pass/fail status and generated artifact paths.

## Error Handling

Never modify user RTL silently. On compile/runtime failure, report:

- Exact tool error text.
- File and line location when available.
- Probable root cause.
- Minimal proposed fix.

Proceed with edits only when the user has explicitly requested automatic fixes or confirms the proposed fix.

Pay attention to warnings that may change behavior: width truncation, latch inference, unconnected ports, unresolved modules, X propagation, and timescale mismatches.

## References

Read `references/eda_workflow.md` when the user needs the full portable workflow, environment checklist, or end-to-end ModelSim/XSim/Vivado flow.

Read `references/common_errors.md` when classifying or explaining a simulation error.

## Report Shape

```markdown
## 仿真结果报告
- **DUT**: <top>
- **仿真器**: <ModelSim/QuestaSim/XSim version>
- **运行方式**: CLI/batch
- **仿真时长**: <sim time>

### 结果
| 项目 | 结果 |
|---|---|
| Compile errors | 0 |
| Runtime errors | 0 |
| Warnings | N |
| Pass/Fail | PASS/FAIL |

### 输出文件
- 日志: <path>
- 波形: <path>
```
