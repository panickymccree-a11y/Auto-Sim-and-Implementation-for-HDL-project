# EDA Skill 安装与 Smoke Test 报告

测试时间：2026-06-30

## 1. 安装结果

正式 skill 源目录：

- `E:\自动仿真skill\codex_skills\eda-simulate`
- `E:\自动仿真skill\codex_skills\eda-synth-impl`

本机安装目录：

- `C:\Users\Administrator\.codex\skills\eda-simulate`
- `C:\Users\Administrator\.codex\skills\eda-synth-impl`

官方校验：

| Skill | 校验命令 | 结果 |
|---|---|---|
| `eda-simulate` | `quick_validate.py` | PASS |
| `eda-synth-impl` | `quick_validate.py` | PASS |

备注：Windows 中文环境下 validator 需要用 `python -X utf8` 运行，否则 Python 默认 GBK 解码会误报 UTF-8 文件解码错误。

## 2. 工具发现

| 工具 | 路径 | 结果 |
|---|---|---|
| ModelSim | `D:\ModelSim\win64\vsim.exe` | 已找到 |
| Vivado | `D:\Vivado2020.2\Vivado\2020.2\bin\vivado.bat` | 已找到 |

## 3. ModelSim 功能仿真 Smoke Test

测试设计：8-bit counter

测试内容：复位释放后使能计数，testbench 检查连续 16 个周期输出递增。

结果：

| 项目 | 结果 |
|---|---|
| RTL 编译错误 | 0 |
| RTL 编译告警 | 0 |
| TB 编译错误 | 0 |
| TB 编译告警 | 0 |
| 仿真结果 | `TB_PASS: counter simulation completed` |

日志：

- `E:\自动仿真skill\skill_test\reports\modelsim_transcript.log`

路径兼容性备注：ModelSim 2020.4 对 `E:\自动仿真skill\...` 这类中文路径的 `-do` 参数解析存在编码问题。实际 smoke test 使用 ASCII 临时运行目录 `E:\eda_skill_test` 执行，并将成功日志回拷到 `E:\自动仿真skill\skill_test\reports`。

## 4. Vivado 综合/实现 Smoke Test

测试设计：同一个 8-bit counter

测试器件：`xc7a35tcpg236-1`

结果：

| 阶段 | 结果 |
|---|---|
| `synth_design` | PASS |
| `opt_design` | PASS |
| `place_design` | PASS |
| `route_design` | PASS |
| Vivado 输出 | `VIVADO_SMOKE_PASS` |

时序摘要：

| 指标 | 值 |
|---|---:|
| WNS | 7.704 ns |
| TNS | 0.000 ns |
| WHS | 0.257 ns |
| THS | 0.000 ns |

资源摘要：

| 指标 | 值 |
|---|---:|
| Slice LUTs | 7 |
| Slice Registers | 8 |

报告：

- `E:\自动仿真skill\skill_test\reports\vivado_smoke_timing_summary.rpt`
- `E:\自动仿真skill\skill_test\reports\vivado_smoke_utilization.rpt`

## 5. 结论

`eda-simulate` 与 `eda-synth-impl` 两个 skill 的目录结构、元数据、模板资源和最小 EDA 执行链均已通过测试。

后续在实际工程中建议将仿真/实现工作目录放在 ASCII 路径下，避免旧版 ModelSim Tcl 对中文路径解析失败。
