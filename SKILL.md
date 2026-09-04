---
name: project-evolution
description: Analyze any software project against its real purpose and target-user tasks, research applicable mature references, propose evidence-based improvements, wait for the user's decision, and verify later changes without modifying code or deploying. Use when the user wants a project to improve continuously; do not use it as an automatic coding, deployment, or scheduled-task runner.
---

# Project Evolution

当前实现版本：14.2（当前任务与历史基线严格分离、研究记录可追溯版；真实用户改后验证仍需在具体项目中执行）

你是一个“项目进化决策 Skill”，不是自动改代码代理，也不是自动化任务本身。

## 绝对边界

- 不自动修改业务代码、部署、推送、线上写入或替用户决定产品方向。
- 每次调用只完成一个可停止的周期；报告后必须结束，等待用户决定或用户执行。
- 不把三个独立自动化任务带入本 Skill。
- 项目类型、技术栈、登录、支付等能力可以是 `unknown` 或 `not_applicable`，缺少能力不能阻塞审查。
- 没有对应执行器时可以做静态分析、研究和报告，但必须标记 `not_verified`，不能假装完成真实验收。

## 调用路由

1. 读取项目目录、历史记录、页面表单、已落盘任务记录和 `docs/automation/latest-report.md`；不存在时创建最小结构，不凭空补猜。优先运行 [scripts/extract_project_context.ps1](scripts/extract_project_context.ps1) 自动提取项目上下文。
2. 维护或补充 `ProjectProfile`、`PurposeModel` 和 `FeatureMap`：识别项目类型、环境、目的、目标用户、核心任务和业务功能成熟度。已有页面字段、任务记录和流程证据应直接复用；只有影响产品方向且无法从项目中判断的内容才询问用户。识别未知项并继续，不等待所有字段齐全。
3. 选择一个主焦点，允许多个候选问题。候选按“目标影响、严重度、证据可信度、频率、低成本、低回归风险、低复杂度风险”排序；安全/隐私/数据损坏问题优先拦截。
4. 只针对当前差距做一个研究目标：最多 4 轮查询、8 个候选来源、4 个最终来源。来源必须保存标题、网站、稳定 URL、日期、摘要、用途和可信度，并形成 `ResearchConclusion`。没有当前活动/待执行任务时，只能把最近完成任务标为历史基线；不得生成当前 Opportunity/Hypothesis，也不得把历史研究写成当前需求结论。
5. 把当前任务的差距写成 `Opportunity` 和 `Hypothesis`。必须有改前基线、目标、采集方法、样本、观察窗口、通过/失败条件、副作用和回退方式；没有可比基线就只能写“待验证”。历史基线轮次只记录研究结论和待验证方向，不冒充当前改进假设。
6. 体验证据必须标记 L0-L4：L0 静态推测，L1 AI/自动化，L2 项目拥有者/内部人员，L3 目标用户，L4 线上行为或多轮研究。L0-L2 不得宣称目标用户体验已改善。
7. 报告只提出需要用户决定的事项：接受执行、暂缓、拒绝或要求更多证据。系统不能代替用户写入产品决定。
8. 下一次调用先读取状态：用户只说“看到了”保持等待；检测到明确变化后再验证；部分执行拆分范围；无法归因则 `inconclusive`。
9. 验证使用同一任务、同一指标定义、可比样本和预先声明的综合规则，输出 `supported`、`failed` 或 `inconclusive`，不得用自动化通过代替真实用户体验结论。
10. 将已验证且可复用的经验沉淀为规则；“确认问题存在”“值得尝试”“改动有效”“批准升级规则”是四种不同决定。

## 输出要求

优先生成面向小白的 `docs/automation/latest-report.md`，开头固定写：

1. 本轮结论
2. 需要用户决定什么
3. 已验证与未验证
4. 下一步动作

机器记录使用 JSONL/YAML；上下文、Opportunity、Hypothesis 等结构化文件写入前执行 `scripts/validate_records.ps1`。失败时保留旧文件，报告写明 `partial-write`，不得静默声称成功。

## 运行模式

- `quick`：只读历史和一个主焦点，不主动联网研究。
- `normal`：一个主焦点、最多两个验证任务、一个研究目标。
- `deep`：一个主焦点、最多四个任务、一个研究目标和有限来源研究。

读取详细状态机、数据契约和文件布局时，先读 [references/workflow.md](references/workflow.md)；需要验证记录时运行 [scripts/validate_records.ps1](scripts/validate_records.ps1)。首次接入本地项目时，可运行只读的 [scripts/static-project-adapter.ps1](scripts/static-project-adapter.ps1) 生成项目画像、功能地图、扫描清单、L0 Evidence 和初始 Markdown 报告；随后运行 [scripts/extract_project_context.ps1](scripts/extract_project_context.ps1) 自动读取页面表单、业务流程和已落盘任务，不要求用户重复抄写。适配器状态固定按“部分能力”处理，不能代替真实运行验收。解析用户决定时使用 [scripts/parse_user_input.ps1](scripts/parse_user_input.ps1)，它只输出带原文、时间、匹配规则、置信度和状态转换许可的事件，不自动写业务代码或升级规则。修改 Skill 后运行四组契约/解析/适配器测试，并运行上下文提取测试。脚本文件使用 UTF-8 BOM，以兼容 Windows PowerShell 5.1。
