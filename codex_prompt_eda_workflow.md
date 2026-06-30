# Prompt: 从聊天记录中提取 Modelsim/Vivado 仿真综合流程并封装为 Skills

## 背景

你将在本会话及关联的历史聊天记录中，查找用户使用 **Mentor Graphics ModelSim**（或 QuestaSim）和 **Xilinx Vivado** 进行 FPGA/数字电路开发的全部讨论。目标是从中整理出一套**可脱离当前环境复现**的完整流程，并将其封装为一组可直接调用的 **skills**。

用户在不同项目中可能反复用到这些工具，但现在需要将分散在多轮对话中的操作经验沉淀为结构化、可迁移的工作流。

---

## 第一阶段：从聊天记录中整理流程

### 1.1 搜索范围
- 遍历当前会话及所有**可访问的历史会话/上下文**（包括本项目下的 `.jsonl` 转录、memory 文件、以及你能检索到的任何聊天片段）。
- 关键字线索（不限于这些）：
  - `vlib`, `vmap`, `vsim`, `vlog`, `vcom`, `modelsim.ini`, `questa`
  - `vivado`, `xsim`, `synth_design`, `impl_design`, `write_bitstream`, `open_project`
  - Tcl 脚本片段、`do` 文件、`xdc` 约束文件、`tb_` 前缀的 testbench
  - 任何 FPGA 器件型号、时序报告、资源利用率报告的讨论

### 1.2 整理输出要求
将找到的内容整理为一份 **EDA 流程手册**，按以下结构组织：

```
1. 环境变量与安装目录
   - MODELSim 安装根目录：<由用户给出>
   - Vivado 安装根目录：<由用户给出>
   - 必要的 PATH / license 配置步骤（从聊天记录中提取实际用到的设置）

2. 原理性仿真流程（ModelSim / Vivado XSim）
   - 2.1 创建工程/库的命令（vlib / xsim 工程模式）
   - 2.2 编译源文件的命令及顺序（package → module → testbench）
   - 2.3 启动仿真器的命令（vsim / xsim / xelab）
   - 2.4 波形/日志查看方式（do 文件中的 wave 添加、log 命令）
   - 2.5 仿真退出与结果收集

3. 综合流程（Vivado）
   - 3.1 工程创建或打开（Tcl 脚本形式）
   - 3.2 添加源文件与约束文件
   - 3.3 综合命令（synth_design）及常用选项
   - 3.4 综合报告解析（资源利用率、关键路径预估）

4. 实现流程（Vivado）
   - 4.1 实现命令（opt_design → place_design → route_design）
   - 4.2 时序分析命令（report_timing_summary）
   - 4.3 比特流生成（write_bitstream）

5. 常见错误与解决方案（从聊天记录中提取实际遇到过的错误）
```

### 1.3 关键约束
- **安装目录由用户给出**：流程中的路径不得硬编码，必须以变量/占位符形式表达，如 `$MODELSIM_HOME`、`$VIVADO_HOME`。
- **可移植**：整理出的命令/脚本应在更换机器/操作系统后，仅需修改安装目录变量即可运行。
- **完整性检查**：如果聊天记录中缺失某步骤（如从未讨论过 `write_bitstream`），需明确标注 `[待补充]`，而非凭空编造。

---

## 第二阶段：封装为 Skills

将第一阶段的产物封装为一组 skills。每个 skill 的职责边界清晰，可独立调用或串联使用。

### Skill 1: `eda-simulate` — 原理性仿真

#### 功能目标
根据用户**自然语言描述**的仿真需求，自动完成：选择仿真器 → 撰写 testbench → 运行仿真 → 提取指定结果。

#### 软件选择策略
- **ModelSim/QuestaSim** 和 **Vivado XSim** 均可用于原理性仿真。
- 选择优先级：比较两者在以下维度的表现，优先使用 **可调参数更多、CLI 控制接口更丰富** 的那个：
  - 命令行参数粒度（vsim 的 `-g` 泛型覆盖、`-G` 参数覆盖、`-do` 脚本控制 vs xsim 的等效能力）
  - 波形/信号探针灵活性（ModelSim 的 `log -r /*`、`wave` 命令 vs Vivado 的 waveform 配置）
  - 覆盖率收集支持（ModelSim 的 coverage 选项 vs Vivado 的等效选项）
  - Tcl 交互式调试能力
- **给出你的评估结论**（哪个更优及其理由），然后默认采用更优者。如果用户明确指定使用另一个，则听从用户选择。

#### 输入（用户可用自然语言自由指定）
1. **待测设计（DUT）**：RTL 文件路径（Verilog / VHDL）、顶层模块名
2. **时钟与复位方案**：时钟频率、复位极性、是否需要 PLL/MMCM 等
3. **激励信号**（可选，未指定则生成默认激励）：
   - 输入端口名称、数据类型、驱动时序（如 "每 3 个时钟周期翻转一次"、"按伪随机序列生成"）
   - 外部数据文件导入（如 "从 `input_data.txt` 读取 16-bit hex 数据"）
4. **中间变量探针**（可选）：需要观察/记录的内部信号层级路径
5. **输出验证**（可选）：
   - 期望的输出值或范围
   - 自动比对模式（如 "当 output_valid 为高时，检查 output_data 是否等于 input_data × 2"）
6. **仿真时长**：固定时间或事件驱动（如 "运行 100 μs" 或 "直到 fifo_empty 为高"）

#### 执行流程
```
Step 1: 解析用户需求 → 生成仿真配置摘要，回显给用户确认
Step 2: 若用户未提供完整 DUT 信号列表，先读取 RTL 文件提取端口信息
Step 3: 生成 testbench 文件（命名规则：tb_<dut_module_name>.sv / .v / .vhd）
Step 4: 生成仿真脚本（ModelSim .do 文件 / Vivado Tcl 脚本）
Step 5: 调用仿真器 CLI 执行
Step 6: 监视仿真输出：如遇编译/运行时错误，截取错误信息并报告，等待用户指示
Step 7: 仿真通过后，提取用户在 Step 1 中指定的变量/结果：
   - 将波形导出为指定格式（VCD / WDB / 截图由用户选择）
   - 将指定信号的数据整理为表格/文本摘要
Step 8: 输出结构化结果报告
```

#### 输出格式
```markdown
## 仿真结果报告
- **DUT**: <顶层模块名>
- **仿真器**: ModelSim xx.x / Vivado xx.x
- **仿真时间**: 开始 ~ 结束（wall time + 仿真时间）

### 指定信号数据
| 时间 | 信号名 | 值 | 备注 |
|------|--------|-----|------|
| ... | ... | ... | ... |

### 波形文件
- 路径: ...

### 日志摘要
- Warning: N 条
- Error: 0 条
- 关键信息: ...
```

---

### Skill 2: `eda-synth-impl` — Vivado 综合与实现

#### 功能目标
通过 Vivado **纯 CLI 模式**（无 GUI）驱动综合 → 实现 → 比特流生成的完整流程。遇到错误时，分析原因 → 征求用户同意 → 修复代码 → 从中断点继续。最后对时序违例部分进行报告并给出解决方案。

#### 前置依赖
- Skill 1 的仿真结果（可选但建议：综合前确保仿真通过）
- 用户提供的 Vivado 安装目录
- 目标器件型号（如 `xc7k325tffg900-2`）

#### 输入
1. **RTL 源文件列表**（Verilog / VHDL / SystemVerilog）
2. **约束文件**（.xdc）：引脚约束 + 时序约束
3. **顶层模块名**
4. **目标器件型号**（Part Number）
5. **时钟约束信息**（若 .xdc 中未包含）：时钟名称、频率、端口映射

#### 执行流程
```
Phase A — 准备
  A1: 验证所有源文件存在且可读
  A2: 检查 Vivado 环境（source settings64.sh 或等效）
  A3: 生成或确认 XDC 约束文件存在

Phase B — 综合
  B1: 生成 Vivado Tcl 脚本（create_project → add_files → synth_design）
  B2: 执行 `vivado -mode batch -source <script>.tcl`
  B3: 解析综合日志：
      - 若成功 → 提取资源利用率、预估时序，进入 Phase C
      - 若失败 → 进入错误处理流程（见下方）

Phase C — 实现
  C1: 追加实现命令到 Tcl 脚本（opt_design → place_design → route_design）
  C2: 执行
  C3: 解析实现日志：
      - 若成功 → 进入 Phase D
      - 若失败 → 进入错误处理流程

Phase D — 时序收尾与比特流
  D1: report_timing_summary → 解析 WNS/TNS/WHS/THS
  D2: 若有时序违例 → 进入时序违例报告流程（见下方）
  D3: write_bitstream
  D4: 输出最终报告

错误处理流程（Phase B/C 中遇错时触发）:
  E1: 从日志中提取错误码和错误描述
  E2: 定位错误源（文件:行号）
  E3: 输出结构化错误报告：
      - 错误类型：语法 / 综合 / 约束 / 其他
      - 错误位置：文件路径:行号
      - 错误原因分析（中文说明）
      - 建议修复方案
  E4: **等待用户明确同意**后才修改代码
  E5: 修改后从当前 Phase 起点重新执行（不是整个流程重来）

时序违例报告流程（Phase D 中遇违例时触发）:
  T1: 运行 report_timing -max_paths 50 获取详细违例路径
  T2: 对每条违例路径提取：
      - Startpoint / Endpoint
      - 数据路径延迟 vs 时钟周期
      - 逻辑级数（levels of logic）
      - 最差的 N 个组合逻辑单元
  T3: 输出时序违例报告，对每条违例给出解决方案建议，包括但不限于：
      - 插入流水线寄存器（pipeline stage）
      - 重写关键组合逻辑（减少逻辑级数）
      - 调整约束（如多周期路径、假路径声明）
      - 更换器件速度等级
      - 调整综合/实现策略（如 performance_explore）
  T4: 询问用户要自动应用哪些修复，或手动调整
```

#### 输出格式
```markdown
## Vivado 综合与实现报告

### 基础信息
- **项目名**: ...
- **器件**: ...
- **策略**: ...

### 综合结果
| 指标 | 值 |
|------|-----|
| LUT | ... |
| FF | ... |
| DSP | ... |
| BRAM | ... |
| 预估 f_max | ... |

### 实现结果
| 指标 | 值 |
|------|-----|
| WNS | ... ns |
| TNS | ... ns |
| WHS | ... ns |
| THS | ... ns |
| 总功耗 | ... W |

### 时序违例详情（如有）
| 路径 | Startpoint | Endpoint | Slack | 逻辑级数 | 建议 |
|------|------------|----------|-------|---------|------|
| ... | ... | ... | ... | ... | ... |

### 资源利用率
[资源利用率表格]
```

---

## 补充指令

### 关于占位符与可移植性
- 所有脚本和配置文件中的安装路径使用 `{{MODELSIM_HOME}}` 和 `{{VIVADO_HOME}}` 占位符。
- 在流程文档中附带一份"环境适配清单"：列出用户在新环境中需要修改的变量和需要验证的步骤。
- ModelSim 的 `modelsim.ini` 和 Vivado 的 `settings64.sh`/`settings64.bat` 分别作为各自的环境入口。

### 关于错误处理的严格规则
- **永远不要未经用户同意就修改用户的 RTL 源代码。** 即使你认为修复是 trivial 的。
- 在错误报告中提供足够的上下文（错误信息原文 + 所在文件代码片段），让用户可以自行判断。
- 如果同一错误在同一次会话中出现过，引用之前的分析和修复记录。

### 交付物清单
完成后，应产生以下文件：
```
eda_workflow/
├── README.md                    # 流程总览 + 环境适配清单
├── simulation/
│   ├── modelsim_sim.template.do  # ModelSim 仿真脚本模板
│   ├── vivado_sim.template.tcl   # Vivado XSim 脚本模板
│   └── tb_template.sv            # testbench 通用模板
├── synthesis/
│   ├── vivado_synth.template.tcl # 综合脚本模板
│   └── vivado_impl.template.tcl  # 实现脚本模板
├── skills/
│   ├── eda-simulate.md           # Skill 1 定义（含详细的输入参数说明）
│   └── eda-synth-impl.md         # Skill 2 定义（含错误处理与违例修复细则）
└── knowledge/
    └── common_errors.md          # 从聊天记录中提取的常见错误库
```

### 最后一步
在整个流程文档和两个 skill 定义完成后，做一次**可复现性自检**：
1. 模拟在新机器上的执行流程：从用户给两个安装路径开始，到仿真结果输出，到比特流生成。
2. 列出所有需要用户手动介入的步骤（如 license 激活、驱动安装）。
3. 如果发现某一步依赖当前环境的特殊配置，将其提炼为可配置的参数。
