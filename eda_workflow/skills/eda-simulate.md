---
name: eda-simulate
description: Run FPGA/RTL functional simulation with ModelSim/QuestaSim or Vivado XSim. Use when the user asks to create or run a testbench, verify RTL behavior, inspect waveforms, extract signal values, or debug simulation compile/runtime errors.
---

# EDA Simulate

Use this skill to convert a natural-language RTL simulation request into a reproducible command-line simulation flow.

## Tool Selection

Default to ModelSim/QuestaSim when both tools are available because it usually provides richer CLI control, flexible `.do` scripting, recursive signal logging, waveform control, and interactive Tcl debugging.

Use Vivado XSim when:

- The user explicitly requests XSim.
- ModelSim/QuestaSim is unavailable.
- The design depends on Vivado simulation libraries or IP behavior that is easier to run in XSim.

## Required Inputs

Collect or infer:

| Input | Requirement |
|---|---|
| DUT files | RTL source paths or filelist |
| DUT top | Top module/entity name |
| Testbench top | Usually `tb_<dut>` |
| Clock/reset | Clock period/frequency, reset polarity and reset duration |
| Stimulus | User-defined stimulus, file-driven stimulus, or generated default stimulus |
| Checks | Expected output values, ranges, assertions, or pass/fail conditions |
| Runtime | Fixed time or event-driven stop condition |
| Tool paths | `{{MODELSIM_HOME}}` or `{{VIVADO_HOME}}` |

Ask for missing inputs only when they cannot be inferred safely from RTL or filelists.

## Workflow

1. Parse the user request into a simulation configuration summary.
2. Read RTL when port lists, widths, reset polarity, or module names are missing.
3. Generate or update `tb_<dut>.sv`.
4. Generate the simulator script:
   - ModelSim/QuestaSim: `.do` file based on `simulation/modelsim_sim.template.do`.
   - Vivado XSim: Tcl flow based on `simulation/vivado_sim.template.tcl`.
5. Run the simulator in CLI/batch mode.
6. Parse compile/runtime output:
   - Extract errors and warnings.
   - Include file path and line number when available.
   - Stop and report before modifying user RTL.
7. If simulation passes, extract requested signal values, waveform paths, and log summary.
8. Return a structured simulation report.

## Error Handling

Never silently ignore compile warnings that may affect behavior, such as width truncation, latch inference, unconnected ports, unresolved modules, or timescale mismatches.

Before modifying user RTL, report:

- Error text exactly as emitted by the tool.
- Probable root cause.
- File and line location.
- Minimal proposed fix.

Proceed with edits only when the user has explicitly asked for automatic fixes or confirms the proposed fix.

## Report Format

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

### 指定信号
| 时间 | 信号 | 值 | 备注 |
|---|---|---|---|

### 输出文件
- 日志: <path>
- 波形: <path>
```
