<p align="right">
  <a href="./README.md">English</a> · <strong>简体中文</strong>
</p>

<p align="center">
  <img src="./assets/readme/hero-zh.svg" width="100%" alt="project-evolution：围绕项目目的和真实用户任务，以证据驱动持续改进。">
</p>

**一个围绕项目目的和真实用户任务，持续改进软件项目的 Codex Skill。**

`project-evolution` 把项目目录和真实用户任务转成一个有限的进化闭环：理解项目，发现有价值的差距，调研适用参考，提出可验证的改进，再在下一轮复核结果。

## 真实证明

<p align="center">
  <img src="./assets/readme/proof-zh.svg" width="100%" alt="ProjectProfile、FeatureMap、Evidence、Hypothesis 和 RunResult 组成可追溯的记录链。">
</p>

这些不是宣传用的概念，而是 Skill 数据契约中的真实记录。每类记录都有明确作用、证据要求和下一轮复用位置。

## 它和普通审查有什么不同

| 普通审查 | project-evolution |
| --- | --- |
| 从文件夹、文件或通用清单开始 | 从项目目的和真实用户任务开始 |
| 把“存在”当成“可用” | 分开判断存在、可用、好用和成熟度 |
| 给出没有对比依据的建议 | 把差距连接到定向研究和成熟参考 |
| 输出建议后结束 | 建立基线、验收规则、用户决定和后续结果 |
| 把自动化通过当成体验证明 | 区分静态检查到真实用户行为的证据等级 |

## 项目进化流程

```mermaid
flowchart LR
    A[读取项目上下文] --> B[确认项目目的与用户任务]
    B --> C[建立业务功能地图]
    C --> D[围绕具体差距调研]
    D --> E[形成机会与改进假设]
    E --> F[建立基线与验收条件]
    F --> G[等待用户决定]
    G --> H[用户自行执行改动]
    H --> I[按原标准复核]
    I --> J[保留、调整、撤销或重新打开]
    J --> B
```

这条流程被刻意限制在一个明确焦点内。没有证据或没有需要支持的决定时，不会扩展成“大而全”的项目审查。

## 第一次使用

在 Codex 中调用 `$project-evolution`，并指定项目目录。首次接入本地项目时，可以运行只读适配器：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/static-project-adapter.ps1 `
  -ProjectPath "C:\你的项目路径" `
  -ProjectId "demo-project" `
  -OutputDir "C:\你的项目路径\docs\project-evolution"
```

然后打开 `latest-report.md`。这是给用户查看的主入口；JSON 文件用于追踪和校验。

想做一轮定向改进时，可以使用：

```text
使用 $project-evolution 分析这个项目。
读取当前项目上下文，并选择一个高价值的真实用户任务。
只围绕有证据支持的具体差距做调研。
提出带改前基线和验收条件的改进建议。
不要修改代码或部署，报告完成后停止。
```

## 运行模式

| 模式 | 适用场景 | 范围 |
| --- | --- | --- |
| `quick` | 快速了解当前状态 | 历史记录 + 一个焦点，不主动联网研究 |
| `normal` | 日常持续改进 | 一个焦点、有限验证、一个研究目标 |
| `deep` | 重要或不确定的问题 | 一个焦点、多个任务、有限来源调研 |

## 当前边界

当前版本是 **Alpha / 个人有限发布版**，不是：

- 自动改代码或自动部署代理；
- 替你做产品决策或替代真实目标用户研究的系统；
- 把静态扫描结果冒充“功能好用”的工具；
- 保证销售、转化或商业结果提升的承诺。

自动变化检测、真实目标用户测试和完整的改前改后验证，仍需要结合具体项目开发适配器。

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
