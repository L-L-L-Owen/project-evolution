# project-evolution

`project-evolution` 是一个面向软件项目持续改进的 Codex Skill 原型。

它可以帮助你：

- 读取项目类型、技术环境、页面表单和已落盘任务；
- 建立项目画像、目的模型和业务功能地图；
- 根据当前任务制定有限研究计划；
- 保存可追溯的研究来源与研究结论；
- 生成面向用户的 Markdown 进化报告；
- 等待用户决定，并为后续复核保留结构化记录。

## 当前定位

当前版本是 **Alpha / 个人内部有限发布版**，不是稳定版，也不是完整的自动进化平台。

它不会自动修改业务代码、启动任务、部署、推送 GitHub 或替用户做产品决定。当前版本也尚未实现自动变化检测和完整的改后验证闭环。

## 使用方式

在 Codex 中调用 `$project-evolution`，并指定一个项目目录。首次接入时可先运行静态适配器，再运行上下文提取脚本。

示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/static-project-adapter.ps1 `
  -ProjectPath "C:\path\to\your-project" `
  -ProjectId "demo-project" `
  -OutputDir "C:\path\to\your-project\docs\project-evolution"

powershell -NoProfile -ExecutionPolicy Bypass -File scripts/extract_project_context.ps1 `
  -ProjectPath "C:\path\to\your-project" `
  -ProjectId "demo-project" `
  -OutputDir "C:\path\to\your-project\docs\project-evolution"
```

## 验证

Windows PowerShell 5.1 和 PowerShell 7 均可运行测试：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_project_context.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_validator.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_user_input.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_static_adapter.ps1
```

## 数据与隐私

不要把真实客户线索、邮箱、电话、Cookie、密钥、密码或生产日志提交到 Skill 仓库。项目试用数据应保存在具体项目中，并在提交前人工检查。

## 许可证

MIT License，见 [LICENSE](LICENSE)。
