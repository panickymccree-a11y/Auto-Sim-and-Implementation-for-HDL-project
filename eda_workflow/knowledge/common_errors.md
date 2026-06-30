# EDA 常见错误库

本文件用于沉淀从聊天记录、仿真日志、Vivado 日志和时序报告中提取的真实错误案例。当前 prompt 未提供具体历史错误原文，因此项目专属案例标记为 `[待补充]`。

## 记录格式

每条错误建议按以下格式补充：

```markdown
## <错误标题>
- **工具**: ModelSim / QuestaSim / Vivado XSim / Vivado Synth / Vivado Impl
- **错误原文**: `<粘贴关键日志>`
- **触发条件**: <何种代码或约束导致>
- **定位方式**: <文件:行号 / 报告字段 / 命令>
- **原因分析**: <中文说明>
- **修复方案**: <最小可行修复>
- **验证方式**: <重跑命令和通过标准>
```

## 已提炼的通用错误类型

### 1. 仿真源文件顺序错误

- **工具**: ModelSim/QuestaSim, Vivado XSim
- **表现**: module/entity/package/interface 未定义。
- **原因**: package、interface、依赖模块或 IP stub 未在 DUT 前编译。
- **修复方案**: 根据依赖顺序重排 filelist，顺序通常为 package/interface -> leaf module -> top -> testbench。
- **验证方式**: 重新运行仿真编译，确认无 unresolved module/entity。

### 2. testbench 端口连接不完整

- **工具**: ModelSim/QuestaSim, Vivado XSim
- **表现**: 端口不存在、位宽不匹配、输出为 X。
- **原因**: DUT 端口更新后 testbench 未同步。
- **修复方案**: 重新从 RTL 顶层提取端口，更新 `tb_<dut>.sv` 的端口声明和实例连接。
- **验证方式**: 编译通过，并在复位释放后关键信号不保持 X。

### 3. XDC 缺少时钟约束

- **工具**: Vivado
- **表现**: timing report 出现 unconstrained paths，或 WNS 结果不可信。
- **原因**: 顶层时钟端口未绑定 `create_clock`，或 generated clock 未定义。
- **修复方案**: 在 XDC 中补充 `create_clock` / `create_generated_clock`，并确认端口名匹配综合网表。
- **验证方式**: `report_timing_summary -report_unconstrained` 无关键未约束路径。

### 4. 时序违例

- **工具**: Vivado Impl
- **表现**: WNS/TNS 为负，`report_timing` 显示 setup violation。
- **原因**: 组合逻辑级数过深、跨层级长布线、高扇出控制、过宽加法/比较/多路选择、约束不合理。
- **修复方案**: 优先定位 Startpoint/Endpoint 对应 RTL，插入流水线、拆分组合逻辑、寄存高扇出信号、减少跨模块长路径。只有在功能上确认为多周期或假路径时才修改约束。
- **验证方式**: 重跑实现，检查 WNS/TNS/WHS/THS 收敛。

## 项目专属错误案例

| 编号 | 状态 | 说明 |
|---|---|---|
| EDA-001 | `[待补充]` | 从历史聊天记录提取 ModelSim/QuestaSim 实际错误 |
| EDA-002 | `[待补充]` | 从历史聊天记录提取 Vivado 综合实际错误 |
| EDA-003 | `[待补充]` | 从历史聊天记录提取 Vivado 实现/时序实际错误 |
