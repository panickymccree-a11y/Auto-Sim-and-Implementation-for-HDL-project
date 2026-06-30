# Auto Sim and Implementation for HDL Project

本仓库沉淀两套 Codex EDA 自动化 skill，用于 HDL/FPGA 项目的功能仿真、Vivado 综合实现、时序报告分析和时序修复建议。

## Skills

| Skill | 位置 | 用途 |
|---|---|---|
| `eda-simulate` | `codex_skills/eda-simulate` | 使用 ModelSim/QuestaSim 或 Vivado XSim 生成并运行 RTL 功能仿真 |
| `eda-synth-impl` | `codex_skills/eda-synth-impl` | 使用 Vivado CLI 执行综合、实现、时序分析和可选 bitstream 生成 |

## 目录

| 路径 | 内容 |
|---|---|
| `codex_skills/` | 可直接安装到 Codex 的正式 skill 目录 |
| `eda_workflow/` | 流程手册、脚本模板、草案 skill 和错误库 |
| `skill_test/` | 最小 counter smoke test 与测试报告 |
| `TEST_REPORT.md` | 本机安装、校验、ModelSim/Vivado smoke test 结果 |

## 安装

将两个 skill 目录复制到本机 Codex skills 目录：

```powershell
Copy-Item -Recurse -Force .\codex_skills\eda-simulate "$env:USERPROFILE\.codex\skills\eda-simulate"
Copy-Item -Recurse -Force .\codex_skills\eda-synth-impl "$env:USERPROFILE\.codex\skills\eda-synth-impl"
```

校验：

```powershell
python -X utf8 "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" "$env:USERPROFILE\.codex\skills\eda-simulate"
python -X utf8 "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" "$env:USERPROFILE\.codex\skills\eda-synth-impl"
```

## 测试状态

当前本机 smoke test 已通过：

- ModelSim 2020.4：counter 功能仿真通过，Errors 0，Warnings 0。
- Vivado 2020.2：counter 综合、布局、布线通过，WNS 7.704 ns。

详见 `TEST_REPORT.md`。

## 路径备注

旧版 ModelSim/QuestaSim 在 Windows 下可能无法正确解析包含中文或非 ASCII 字符的 `-do` 脚本路径。建议将实际仿真/实现工作目录放在 ASCII 路径下；skill 材料本身可以存放在中文路径。
