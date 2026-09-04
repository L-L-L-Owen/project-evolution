# project-evolution

<p align="center">
  <img src="assets/readme/hero-zh.svg" alt="project-evolution 项目进化闭环" width="100%" />
</p>

**一个围绕项目目的和真实用户任务，持续改进软件项目的 Codex Skill。**

[English](README.md) · [工作流](references/workflow.md) · [更新记录](CHANGELOG.md)

> 研究差距，提出改进，验证结果。

`project-evolution` 不只扫描代码目录，而是结合项目上下文、业务功能地图、定向调研、改进假设和后续复核，帮助项目围绕真实目标持续变好，并保留可追溯记录。

## 它能做什么

- 从项目目录和已有记录中建立项目画像。
- 区分当前任务、待执行任务和最近完成任务。
- 梳理业务功能，而不只是罗列文件夹和源代码。
- 围绕具体差距，对比适用的成熟规范、案例和参考项目。
- 生成包含机会、假设、改前基线和验收条件的 Markdown 汇报。
- 保存用户决定和验证历史，供下一轮继续使用。

## 它不会做什么

这是一个**项目进化决策辅助 Skill**，不是自动改代码平台。它不会：

- 修改业务代码；
- 部署或写入生产环境；
- 自动推送 GitHub；
- 替你决定产品方向；
- 用静态检查冒充真实用户满意度。

当前版本是 **Alpha / 个人有限发布版**。自动变化检测、真实目标用户测试和完整的改前改后验证闭环，仍需要结合具体项目开发适配器。

## 项目进化流程

```mermaid
flowchart LR
    A[读取项目上下文] --> B[确认项目目的与用户任务]
    B --> C[建立业务功能地图]
    C --> D[围绕差距定向调研]
    D --> E[形成机会与改进假设]
    E --> F[建立基线与验收条件]
    F --> G[等待用户决定]
    G --> H[用户自行执行改动]
    H --> I[按原标准复核]
    I --> J[保留、调整、撤销或重新打开]
    J --> B
```

每轮都有明确焦点、证据要求、停止条件和下一步动作，不把“功能存在”直接等同于“功能好用”。

## 快速开始

对目标项目运行只读适配器。生成的记录会写入你指定的输出目录。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/static-project-adapter.ps1 `
  -ProjectPath "C:\你的项目路径" `
  -ProjectId "demo-project" `
  -OutputDir "C:\你的项目路径\docs\project-evolution"

powershell -NoProfile -ExecutionPolicy Bypass -File scripts/extract_project_context.ps1 `
  -ProjectPath "C:\你的项目路径" `
  -ProjectId "demo-project" `
  -OutputDir "C:\你的项目路径\docs\project-evolution"
```

运行后先打开 `latest-report.md`。这是给人查看的主入口；JSON 文件用于追踪、复核和机器校验。

## 运行模式

| 模式 | 适用场景 | 范围 |
| --- | --- | --- |
| `quick` | 只想快速了解当前状态 | 历史记录 + 一个焦点，不主动联网研究 |
| `normal` | 日常持续改进 | 一个焦点、有限验证、一个研究目标 |
| `deep` | 重要或不确定的问题 | 一个焦点、多个任务、有限来源调研 |

## 目录说明

```text
SKILL.md                         Skill 入口
references/workflow.md           状态机和运行规则
references/project-evolution.schema.json
                                 数据契约
scripts/extract_project_context.ps1
                                 只读上下文提取
scripts/static-project-adapter.ps1
                                 保守的静态适配器
scripts/validate_records.ps1    本地契约校验
examples/                        安全示例数据
tests/                           PowerShell 测试脚本
```

## 验证

支持 Windows PowerShell 5.1 和 PowerShell 7：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_project_context.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_validator.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_user_input.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_static_adapter.ps1
```

## 数据与隐私

不要把真实客户线索、邮箱、电话、Cookie、Token、密码、密钥或生产日志提交到本仓库。项目专属记录应保存在被审查的项目中，提交前请人工检查。

## 路线图

- 支持更多项目类型的专用适配器；
- 跨轮次自动检测项目变化；
- 复用改前和改后基线；
- 真实目标用户任务验收；
- 多轮报告更新和更强的证据综合。

## 许可证

MIT License，见 [LICENSE](LICENSE)。
