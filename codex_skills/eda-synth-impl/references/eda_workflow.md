# EDA 自动仿真与 Vivado 实现流程手册

本文档从 `codex_prompt_eda_workflow.md` 提炼，目标是把 ModelSim/QuestaSim、Vivado XSim、Vivado 综合/实现/时序收敛流程整理为可迁移、可复用的自动化工作流。

当前版本基于 prompt 本身提炼。未能从历史聊天或本地日志确认的项目专属信息均标记为 `[待补充]`。

## 1. 环境适配清单

| 变量/项目 | 说明 | 示例或要求 |
|---|---|---|
| `{{MODELSIM_HOME}}` | ModelSim/QuestaSim 安装根目录 | 由用户提供，不在模板内硬编码 |
| `{{VIVADO_HOME}}` | Vivado 安装根目录 | 由用户提供，不在模板内硬编码 |
| `{{PROJECT_ROOT}}` | 当前 FPGA 工程根目录 | 由用户提供 |
| `{{RTL_FILES}}` | RTL 源文件列表 | 推荐使用 filelist 或 Tcl list |
| `{{TB_FILE}}` | testbench 文件路径 | 自动生成或用户提供 |
| `{{TOP_MODULE}}` | 综合/实现顶层模块名 | 用户提供或从工程中识别 |
| `{{TB_TOP}}` | 仿真 testbench 顶层名 | 通常为 `tb_{{TOP_MODULE}}` |
| `{{XDC_FILES}}` | Vivado 约束文件列表 | 至少包含时钟约束 |
| `{{PART}}` | Xilinx 器件型号 | 例如 `xc7k325tffg900-2` |
| License | ModelSim/Vivado 授权 | 新机器必须先验证 license 可用 |
| 环境入口 | 工具初始化脚本 | Windows 用 `settings64.bat`，Linux 用 `settings64.sh` |

路径建议：旧版 ModelSim/QuestaSim 在 Windows 下可能无法正确解析包含中文或非 ASCII 字符的 `-do` 脚本路径。建议把仿真工作目录、临时工程目录和工具脚本运行目录放在 ASCII 路径下；skill 材料本身可以存放在中文路径。

## 2. 原理性仿真流程

默认优先选择 ModelSim/QuestaSim。原因是其 CLI 参数、`.do` 脚本、波形命令、`log -r` 层级探针和交互调试能力通常比 Vivado XSim 更适合自动化调试。若用户明确指定 Vivado XSim，则按用户选择执行。

### 2.1 ModelSim/QuestaSim

1. 准备环境：确认 `{{MODELSIM_HOME}}`、license、`modelsim.ini`。
2. 创建工作库：`vlib work`，`vmap work work`。
3. 按顺序编译源文件：package/interface 优先，其次 RTL module，最后 testbench。
4. 启动仿真：`vsim -c work.{{TB_TOP}} -do modelsim_sim.do`。
5. 记录信号：`log -r /*`，按需 `add wave`。
6. 运行仿真：固定时间 `run {{RUN_TIME}}` 或事件驱动。
7. 收集结果：transcript、VCD/WLF、指定信号采样表、错误/告警摘要。

模板文件：`simulation/modelsim_sim.template.do`

### 2.2 Vivado XSim

1. 准备环境：调用 `{{VIVADO_HOME}}/settings64.bat` 或 `settings64.sh`。
2. 编译 RTL/testbench：`xvlog` 或 `xvhdl`。
3. elaboration：`xelab {{TB_TOP}} -debug typical`。
4. 仿真：`xsim {{TB_TOP}} -tclbatch <run.tcl>`。
5. 收集日志、WDB/VCD 和指定信号数据。

模板文件：`simulation/vivado_sim.template.tcl`

## 3. Vivado 综合流程

1. 验证 RTL、约束文件、顶层模块名和器件型号。
2. 以 batch Tcl 创建或打开工程。
3. 添加 RTL 和 XDC。
4. `synth_design -top {{TOP_MODULE}} -part {{PART}}`。
5. 输出报告：
   - `report_utilization`
   - `report_timing_summary`
   - `report_methodology`
6. 解析综合日志；失败时提取错误码、文件、行号和上下文，先输出修复建议。

模板文件：`synthesis/vivado_synth.template.tcl`

## 4. Vivado 实现流程

1. 从综合结果或 checkpoint 进入实现。
2. 依次执行：
   - `opt_design`
   - `place_design`
   - `phys_opt_design`（可选）
   - `route_design`
3. 输出实现报告：
   - `report_timing_summary`
   - `report_timing -max_paths 50`
   - `report_utilization`
   - `report_power`
   - `report_route_status`
4. 若 WNS/TNS/WHS/THS 不收敛，进入时序违例分析：
   - 提取 Startpoint/Endpoint。
   - 统计数据路径延迟、逻辑级数、主要组合逻辑单元。
   - 回溯到 RTL 对应代码。
   - 给出流水线、逻辑拆分、约束修正或实现策略调整方案。
5. 仅当时序无严重阻塞或用户明确要求时执行 `write_bitstream`。

模板文件：`synthesis/vivado_impl.template.tcl`

## 5. 错误处理原则

1. 仿真、综合、实现报错时，先报告错误，不直接修改 RTL。
2. 报告必须包含错误原文、文件位置、原因分析和建议修复方案。
3. 修改用户 RTL 前需要用户明确同意。
4. 修复后从失败阶段重新执行，不默认从头重跑。
5. 如果缺少约束、器件型号、安装路径或 license 信息，标记 `[待补充]` 并请求用户补充。

## 6. Skill 划分

| Skill | 文件 | 职责 |
|---|---|---|
| `eda-simulate` | `skills/eda-simulate.md` | 根据自然语言需求生成/运行 testbench，并输出仿真结果 |
| `eda-synth-impl` | `skills/eda-synth-impl.md` | 通过 Vivado CLI 执行综合、实现、时序报告和比特流生成 |

## 7. 可复现性自检

在新机器上复现时，按以下顺序检查：

1. 用户提供 `{{MODELSIM_HOME}}`、`{{VIVADO_HOME}}`、`{{PROJECT_ROOT}}`。
2. 命令行可执行 `vsim -version` 或 `vivado -version`。
3. license 可用，工具启动不报授权错误。
4. 源文件列表、testbench、XDC、器件型号完整。
5. 仿真脚本不含绝对安装路径。
6. Vivado Tcl 脚本不含当前机器特有路径。
7. 所有输出报告进入工程内 `reports/` 或用户指定目录。

## 8. 待补充项

| 项目 | 状态 |
|---|---|
| 实际 ModelSim 安装路径 | `[待补充]` |
| 实际 Vivado 安装路径 | `[待补充]` |
| 默认目标器件型号 | `[待补充]` |
| 项目通用 XDC 模板 | `[待补充]` |
| 历史聊天中出现过的具体错误库 | `[待补充]` |
