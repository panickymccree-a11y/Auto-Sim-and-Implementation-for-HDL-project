---
name: eda-synth-impl
description: Run Vivado command-line synthesis, implementation, timing analysis, timing-violation triage, and optional bitstream generation. Use when the user asks to synthesize RTL, run Vivado implementation, inspect timing reports, fix timing violations, analyze WNS/TNS/WHS/THS, generate Vivado reports, or create a bitstream from Verilog/SystemVerilog/VHDL sources.
---

# EDA Synth Impl

Use this skill to drive a reproducible Vivado CLI flow from RTL sources to synthesis, implementation, timing analysis, and optional bitstream generation.

## Inputs To Gather

Collect or infer these before running:

| Input | Requirement |
|---|---|
| RTL files | Verilog/SystemVerilog/VHDL source list |
| Top module | Vivado synthesis top |
| XDC files | Timing constraints and pin constraints |
| Part | Xilinx part number |
| Clock constraints | Clock name, frequency/period, port mapping if XDC is incomplete |
| Vivado path | `{{VIVADO_HOME}}` or shell where `vivado` is on `PATH` |
| Output directory | Checkpoints, logs, reports, optional bitstream |

Do not invent a target part or clock period. Mark missing values as `[待补充]` and ask the user.

## Workflow

### Phase A: Prepare

1. Verify source and XDC paths exist.
2. Verify Vivado with `vivado -version`.
3. Confirm top module and part number.
4. Confirm XDC timing constraints, especially `create_clock`.

### Phase B: Synthesis

1. Copy and fill `assets/templates/vivado_synth.template.tcl`.
2. Run `vivado -mode batch -source <synth.tcl>`.
3. Parse:
   - `synth_utilization.rpt`
   - `synth_timing_summary.rpt`
   - `synth_methodology.rpt`
4. If synthesis fails, enter the error workflow.

### Phase C: Implementation

1. Open the synthesized checkpoint.
2. Copy and fill `assets/templates/vivado_impl.template.tcl`.
3. Run `opt_design`, `place_design`, optional `phys_opt_design`, and `route_design`.
4. Generate:
   - `impl_timing_summary.rpt`
   - `timing_violations_max_paths.rpt`
   - `impl_utilization.rpt`
   - `impl_power.rpt`
   - `route_status.rpt`
5. If implementation fails, enter the error workflow.

### Phase D: Timing Closure

1. Parse WNS, TNS, WHS, THS, and unconstrained path warnings.
2. If timing is clean, optionally run `write_bitstream`.
3. If setup timing fails, inspect `report_timing -max_paths 50`.
4. For each critical path extract startpoint, endpoint, clocks, slack, data path delay, logic levels, dominant cells/nets, and traceable RTL source region.
5. Propose fixes in this order:
   - Add pipeline registers.
   - Register high-fanout controls.
   - Split wide comparators, adders, priority logic, or muxes.
   - Move constant/configuration logic out of the critical path.
   - Use multicycle/false path constraints only when functionally justified.
   - Adjust Vivado implementation strategy after RTL and constraints are checked.

## Error Handling

When Vivado reports an error:

1. Extract the exact `[Synth ...]`, `[Place ...]`, `[Route ...]`, `[Timing ...]`, or `[DRC ...]` message.
2. Locate file and line number when available.
3. Classify the issue as syntax, elaboration, synthesis, constraint, implementation, timing, DRC, or environment.
4. Provide a minimal fix plan.
5. Modify RTL/XDC only after explicit user approval or when the user has already requested automatic fixes.
6. Resume from the failed phase rather than rerunning every previous phase.

## References

Read `references/eda_workflow.md` when the user needs the full portable workflow or environment checklist.

Read `references/common_errors.md` when classifying Vivado synthesis, implementation, timing, DRC, or constraint errors.

## Report Shape

```markdown
## Vivado 综合与实现报告

### 基础信息
- **项目**: <project>
- **顶层**: <top>
- **器件**: <part>
- **Vivado**: <version>

### 实现时序
| 指标 | 值 |
|---|---|
| WNS | |
| TNS | |
| WHS | |
| THS | |

### 关键违例
| Path | Startpoint | Endpoint | Slack | 主要原因 | 建议 |
|---|---|---|---|---|---|
```
