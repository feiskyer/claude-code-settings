# Claude Code Skills & Agents

[![Stars](https://img.shields.io/github/stars/feiskyer/claude-code-settings)](https://github.com/feiskyer/claude-code-settings/stargazers)
[![Forks](https://img.shields.io/github/forks/feiskyer/claude-code-settings)](https://github.com/feiskyer/claude-code-settings/network/members)
[![License: MIT](https://img.shields.io/github/license/feiskyer/claude-code-settings)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/feiskyer/claude-code-settings)](https://github.com/feiskyer/claude-code-settings/commits)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

给 Claude Code 加上深度调研、图片生成、GitHub 自动化等能力，配好多模型切换，开箱即用。

> OpenAI Codex 的配置和自定义 prompt 请参考 [feiskyer/codex-settings](https://github.com/feiskyer/codex-settings)。

## 快速开始

推荐使用 Claude 官方 marketplace 安装，有两种等价方式：

**方式一：在 Claude Code 会话内使用 slash command**

```sh
/plugin marketplace add feiskyer/claude-code-settings

# 安装主插件（包含所有技能和代理）
/plugin install claude-code-settings
```

**方式二：使用 Claude Code 命令行**

```sh
claude plugin marketplace add feiskyer/claude-code-settings

# 安装主插件（包含所有技能和代理）
claude plugin install claude-code-settings@claude-code-settings
```

主插件包含的完整技能列表：brainstorming、codex-skill、deep-research、github-fix-issue、github-review-pr、gpt-image-skill、grill-me、handoff、nanobanana-skill、skill-creator、translate、youtube-transcribe-skill，详见[技能列表](#技能列表)。单个技能也可以通过 npx skills 按需安装（见下方其他安装方式）。

**注意：** [~/.claude/settings.json](settings.json) 不通过 Plugin 配置，需要手动设置。

<details>
<summary><b>其他安装方式</b></summary>

### npx skills

> **⚠️ 注意：** `npx skills` 安装的技能版本可能滞后于本仓库最新版本。如需获取最新技能，请优先使用上方的官方 marketplace 方式。

`npx skills` 可以为你的 AI 编程工具按需安装单个技能：

```sh
# 列出可用技能
npx -y skills add -l feiskyer/claude-code-settings

# 安装全部技能
npx -y skills add --all feiskyer/claude-code-settings

# 手动选择要安装的技能
npx -y skills add feiskyer/claude-code-settings
```

### 手动安装

> **⚠️ 手动安装会覆盖 `~/.claude` 目录，请务必先备份原有配置。**

```sh
# 备份原有配置
mv ~/.claude ~/.claude.bak

# 克隆本仓库
git clone https://github.com/feiskyer/claude-code-settings.git ~/.claude

# 启动 Copilot Gateway 代理（监听 http://localhost:4141）
npx copilot-gateway@latest start --proxy-env

# 也可以用 tmux 在后台运行
# tmux new-session -d -s copilot 'npx copilot-gateway@latest start --proxy-env'
```

首次启动会提示认证：

```
Please visit https://github.com/login/device and enter code XXXX-XXXX to authenticate.
```

打开链接，登录并授权你的 GitHub Copilot 账户。

**注意：**

1. 仓库根目录的 [settings.json](settings.json) 是作者的配置模板，默认指向 [copilot-gateway](https://github.com/feiskyer/copilot-gateway) 代理（`http://localhost:4141`）。如需使用 [LiteLLM Proxy Server](https://docs.litellm.ai/docs/simple_proxy) 等其他网关，把 `ANTHROPIC_BASE_URL` 改为对应地址（如 `http://localhost:4000`）即可。
2. 确保以下模型在你的账户中可用，否则需替换为你自己的模型名（模型名以你的网关实际提供的为准）：

   - ANTHROPIC_DEFAULT_SONNET_MODEL: claude-sonnet-5
   - ANTHROPIC_DEFAULT_OPUS_MODEL: claude-opus-5
   - ANTHROPIC_DEFAULT_HAIKU_MODEL: claude-haiku-4-5
3. 模板中 `defaultMode` 为 `acceptEdits`（自动接受文件编辑但保留命令确认）。如需完全跳过权限确认可自行改为 `bypassPermissions`，但请了解其安全风险后再启用。

</details>

## 技能列表

技能是[可复用的能力模块](https://docs.anthropic.com/en/docs/claude-code/skills)，教会 Claude 如何完成特定任务。可通过 `/skill-name [参数]` 手动调用，或根据上下文自动触发。

<details>
<summary><b>brainstorming</b> — 头脑风暴：从想法到设计</summary>

### [brainstorming](./skills/brainstorming)

在构建新功能、创建新组件或设计新系统之前使用。通过协作对话探索用户意图、需求和设计方案，再进入实现阶段。

**触发词：** 用户描述想要构建的东西且涉及设计决策

**核心特性：**

- 逐个提问，渐进式理解需求
- 提出 2-3 个方案并推荐最优解
- 分节呈现设计，每节获得用户认可
- 编写规格文档并自审
- 可选的浏览器可视化伴侣（展示 mockup、图表、布局对比）

</details>

<details>
<summary><b>codex-skill</b> — 将任务交给 Codex CLI</summary>

### [codex-skill](./skills/codex-skill)

非交互式自动化模式，把编码、代码审查和计划审查交给 OpenAI Codex 完成。

**触发词：** "codex", "use gpt", "gpt-5", "let openai", "full-auto", "adversarial review", "用codex", "让gpt实现", "对抗式审查", "让codex审查计划", "第二意见"

**核心特性：**

- 多种执行模式（只读、工作区写入、完全访问）
- 对抗式代码审查（结构化 JSON findings）与实现前的计划审查
- 审查结果只呈现不自动改码；Codex 调用失败时如实报告而非代答
- 默认使用 `~/.codex/config.toml` 中配置的模型；非交互、可嵌入自动化流程
- JSON 结构化输出、增量恢复会话（`resume --last`）
- Prompt 组合模板、审查工作流、CLI 参考见 `references/` 目录

**依赖：** Codex CLI（`npm i -g @openai/codex` 或 `brew install codex`）

</details>

<details>
<summary><b>nanobanana-skill</b> — 使用 Gemini 生成图片</summary>

### [nanobanana-skill](./skills/nanobanana-skill)

通过 Google Gemini API 生成或编辑图片。这是默认图片技能——未指明提供商的图片请求都路由到这里。

**触发词：** "nanobanana", "generate image", "create image", "edit image", "图片生成", "生成图片", "AI绘图", "图片编辑"

**核心特性：**

- 多种宽高比和分辨率（1K、2K、4K）
- 图片编辑功能
- 多模型选择（gemini-3.1-flash-image-preview 默认, gemini-3-pro-image-preview 高质量）

**依赖：**

- `GEMINI_API_KEY`（配置在 `~/.nanobanana.env`）
- Python3 + google-genai, Pillow, python-dotenv

</details>

<details>
<summary><b>gpt-image-skill</b> — 使用 OpenAI GPT Image 生成图片</summary>

### [gpt-image-skill](./skills/gpt-image-skill)

使用 OpenAI GPT Image 模型（gpt-image-2, gpt-image-1 等）生成或编辑图片。仅在用户明确指定 OpenAI/GPT 时触发；未指明提供商的图片请求由 nanobanana-skill 处理。

**触发词：** "gpt image", "openai image", "generate image with openai", "用 openai 画图", "用 GPT 生成图片"

**核心特性：**

- 多模型支持（gpt-image-2, gpt-image-1.5, gpt-image-1, gpt-image-1-mini）
- 最多 3 张参考图编辑
- 多种尺寸和质量等级
- 透明背景、多输出格式（png, jpeg, webp）

**依赖：**

- `OPENAI_API_KEY`（配置在 `~/.gpt-image.env` 或环境变量）
- Python3 + openai, Pillow

</details>

<details>
<summary><b>youtube-transcribe-skill</b> — YouTube 字幕提取</summary>

### [youtube-transcribe-skill](./skills/youtube-transcribe-skill)

从 YouTube 视频链接提取字幕/转录文本。

**核心特性：**

- 双提取方式：CLI（快速）和浏览器自动化（兜底）
- 自动选择字幕语言（zh-Hans, zh-Hant, en）
- 保存转录文本到本地文件

**依赖：** `yt-dlp`（CLI 方式）或 `chrome-devtools-mcp`（浏览器方式）

</details>

<details>
<summary><b>deep-research</b> — 多 Agent 深度调研</summary>

### [deep-research](./skills/deep-research)

多 Agent 编排工作流：将调研目标拆分为可并行子目标，通过 `claude -p` 子进程执行，聚合结果并交付精修报告。

**触发词：** "深度调研", "deep research", "wide research", "多Agent并行调研"

**核心特性：**

- 多 Agent 编排：拆分目标为并行子任务
- Skills 优先策略：已安装技能 → MCP 工具 → WebFetch/WebSearch
- 结构化交付：生成文件级报告，含摘要和结论
- 逐章精修与来源验证
- 可扩展执行：从微型（1-2 任务）到大型（15+）

**产出目录结构：**

```
.research/<name>/
├── prompts/           # 子任务 prompt
├── child_outputs/     # 子进程输出
├── logs/              # 执行日志
├── raw/               # 原始数据缓存
└── final_report.md    # 最终报告
```

</details>

<details>
<summary><b>translate</b> — 技术文章中文翻译</summary>

### [translate](./skills/translate)

将英文或日文技术文章翻译为自然流畅的中文。译文忠实原意、读来地道，保留 Markdown 格式和技术术语原文。

**用法：** `/translate [粘贴文本或提供文件路径]`

</details>

<details>
<summary><b>grill-me</b> — 高强度追问式设计审查</summary>

### [grill-me](./skills/grill-me)

针对方案或设计的高强度追问式面试，沿着设计决策树逐一深入，过程中同步维护领域模型（术语表和 ADR）。

**触发词：** `/grill-me [方案/设计描述]`（仅手动调用）

**核心特性：**

- 一次只问一个问题，每个问题给出推荐答案
- 自动对照术语表质疑含糊表达
- 与代码交叉验证用户陈述
- 即时更新 `CONTEXT.md` 术语表
- 审慎创建 ADR（仅限难以逆转的重大决策）
- 支持单上下文和多上下文（Context Map）仓库

</details>

<details>
<summary><b>handoff</b> — 会话交接文档生成</summary>

### [handoff](./skills/handoff)

将当前对话压缩为交接文档，供下一个 agent 无缝接续工作。

**触发词：** `/handoff [下一次会话的重点方向]`（仅手动调用）

**核心特性：**

- 结构化交接：背景与目标、已完成工作、当前状态、待办事项、推荐技能、关键上下文
- 通过路径/URL 引用已有产物，避免重复
- 自动脱敏处理（API key、密码、PII）
- 智能判断：对话过短时提示无需生成

**输出：** `$TMPDIR/handoff-YYYY-MM-DD-HHMM.md`

</details>

<details>
<summary><b>github-fix-issue</b> — 端到端修复 GitHub Issue</summary>

### [github-fix-issue](./skills/github-fix-issue)

从分析到创建分支、实现、测试、提交 PR 的完整 Issue 修复流程。

</details>

<details>
<summary><b>github-review-pr</b> — 审查 GitHub Pull Request</summary>

### [github-review-pr](./skills/github-review-pr)

使用并行子代理进行多角度代码分析（含安全维度），配合对抗式验证——质疑者需在 head SHA 处复读代码、findings 必须附 file:line 与原文引用。支持置信度评分与误报过滤、去重与一致性计数、更新 PR 的增量复审、批量行内评论，干净 PR 自动 LGTM 通过。

</details>

<details>
<summary><b>skill-creator</b> — 创建和评测 Agent 技能</summary>

### [skill-creator](./skills/skill-creator)

创建、迭代优化和基准测试 Agent 技能，包含定量评估循环和描述优化。

</details>

## 子代理

`agents/` 目录包含扩展 Claude Code 能力的专业化[子代理](https://docs.anthropic.com/en/docs/claude-code/sub-agents)。

| 代理 | 功能 |
|------|------|
| **pr-reviewer** | GitHub PR 代码审查专家 |
| **github-issue-fixer** | GitHub Issue 修复专家 |
| **instruction-reflector** | 分析和改进 Claude Code 指令 |
| **deep-reflector** | 会话分析和学习捕获 |
| **insight-documenter** | 技术突破文档化 |
| **ui-engineer** | UI/UX 开发专家 |

## 配置模板

[配置模板目录](settings/README.md) — 为各种模型提供商预配置的 settings.json。

| 配置文件 | 提供商 | 适用场景 |
|----------|--------|----------|
| [copilot-settings.json](settings/copilot-settings.json) | GitHub Copilot | 已有 Copilot 订阅，零额外成本 |
| [litellm-settings.json](settings/litellm-settings.json) | LiteLLM | 需要统一管理多个模型提供商 |
| [deepseek-settings.json](settings/deepseek-settings.json) | DeepSeek v3.1 | 高性价比，国内直连 |
| [qwen-settings.json](settings/qwen-settings.json) | Qwen3-Coder-Plus | 阿里云生态，国内低延迟 |
| [siliconflow-settings.json](settings/siliconflow-settings.json) | Kimi-K2-Instruct | SiliconFlow 平台用户 |
| [vertex-settings.json](settings/vertex-settings.json) | Vertex AI | 已有 GCP 环境 |
| [azure-settings.json](settings/azure-settings.json) | Azure AI | 已有 Azure 环境（Anthropic 兼容） |
| [azure-foundry-settings.json](settings/azure-foundry-settings.json) | Azure AI Foundry | Azure 原生模式 |
| [minimax.json](settings/minimax.json) | MiniMax M3.1 Flash/M3 | MiniMax 平台用户（全球端点） |
| [minimax-cn.json](settings/minimax-cn.json) | MiniMax M3.1 Flash/M3 | MiniMax 平台用户（中国端点） |
| [openrouter-settings.json](settings/openrouter-settings.json) | OpenRouter | 一个 key 访问多个模型 |

## 脚本工具

[`scripts/`](scripts/) 目录包含维护 Claude Code 环境的实用脚本。

| 脚本 | 功能 |
|------|------|
| [`update-cc-plugins.sh`](scripts/update-cc-plugins.sh) | 一键更新所有已安装的 marketplace 和插件/技能 |

```sh
bash ~/.claude/scripts/update-cc-plugins.sh
```

## 扩展 Web 搜索

WebSearch 是 [Anthropic 专有工具](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/web-search-tool)，仅限官方 API 环境。通过接入以下 MCP 服务器可在任意环境中启用网页搜索：

- [Tavily MCP](https://docs.tavily.com/documentation/mcp)
- [Brave MCP](https://github.com/brave/brave-search-mcp-server)
- [Firecrawl MCP](https://docs.firecrawl.dev/mcp-server)
- [DuckDuckGo Search MCP](https://github.com/nickclyde/duckduckgo-mcp-server)

## 常见问题

<details>
<summary>技能没有自动触发怎么办？</summary>

- 确认路径正确：`~/.claude/skills/<name>/SKILL.md`（注意大小写，必须是 `SKILL.md`）
- 通过 Plugin 安装的技能需要重启会话才能加载
- 检查是否存在双层嵌套目录（`skills/name/name/SKILL.md`），需上移一层
- 验证加载状态：直接问 Claude "What skills do you have access to?"
- `disable-model-invocation: true` 的技能（如 grill-me、handoff）不会自动触发，需用 `/skill-name` 手动调用

</details>

<details>
<summary>如何切换模型提供商？</summary>

- 本仓库提供了 [10 套配置模板](#配置模板)，复制对应的 settings.json 即可
- 核心是设置 `ANTHROPIC_BASE_URL` 和 `ANTHROPIC_API_KEY` 指向你的提供商端点
- 使用 GitHub Copilot 需先启动 copilot-gateway：`npx copilot-gateway@latest start --proxy-env`
- 详细指南见 [使用 GitHub Copilot 作为模型提供商](guidances/github-copilot.md) 和 [使用 LLM 网关](guidances/llm-gateway-litellm.md)

</details>

<details>
<summary>技能装多少合适？会不会影响性能？</summary>

- 建议精选需要的技能，不要全装。过多技能会增加上下文消耗、降低触发准确度
- 推荐用 Plugin 安装后按需禁用；也可以用 `npx skills add feiskyer/claude-code-settings` 手动挑选（注意该方式版本可能滞后）
- 如果发现 Claude 响应变慢或触发错误的技能，考虑减少已安装数量

</details>

<details>
<summary>copilot-gateway 认证过期 / 401 错误</summary>

- 重新运行 `npx copilot-gateway@latest start --proxy-env`，按提示完成设备认证
- VSCode 扩展用户需在扩展设置中单独配置环境变量（见下方 VSCode 登录问题）

</details>

<details>
<summary>权限确认太频繁怎么办？</summary>

- 本仓库 settings.json 模板默认 `defaultMode` 为 `acceptEdits`（自动接受编辑，保留命令确认）
- 如需进一步减少确认，可在 settings.json 的 `permissions.allow` 中配置允许列表
- 完全跳过确认可改为 `bypassPermissions`，但请了解其安全风险

</details>

<details>
<summary>VSCode 中 Claude Code 2.0+ 扩展的登录问题</summary>

如果不使用 Claude.ai 订阅，需在 VSCode settings.json 中手动配置环境变量：

```json
{
  "claude-code.environmentVariables": [
    { "name": "ANTHROPIC_BASE_URL", "value": "http://localhost:4000" },
    { "name": "ANTHROPIC_AUTH_TOKEN", "value": "sk-dummy" },
    { "name": "ANTHROPIC_MODEL", "value": "opusplan" },
    { "name": "ANTHROPIC_DEFAULT_SONNET_MODEL", "value": "claude-sonnet-5" },
    { "name": "ANTHROPIC_DEFAULT_OPUS_MODEL", "value": "claude-opus-5" },
    { "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL", "value": "gpt-5-mini" },
    { "name": "DISABLE_TELEMETRY", "value": "1" }
  ]
}
```

同时需要 [~/.claude/config.json](config.json) 的内容来跳过 claude.ai 登录。

</details>

<details>
<summary>API Key 缺失或无效</summary>

确保 `ANTHROPIC_AUTH_TOKEN` 中配置的 API key 已添加到 `~/.claude.json` 的已批准列表：

```json
{
  "customApiKeyResponses": {
    "approved": ["sk-dummy"],
    "rejected": []
  }
}
```

</details>

## 贡献

欢迎提交 Issue 和 Pull Request！开发与测试指南详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 参考指南

- [使用 GitHub Copilot 作为模型提供商](guidances/github-copilot.md)
- [使用 LLM 网关（LiteLLM）作为模型提供商](guidances/llm-gateway-litellm.md)

## 参考资源

- [Claude Code 官方文档](https://docs.anthropic.com/en/docs/claude-code/overview) — 入门必读，涵盖安装、配置和核心概念
- [anthropics/skills](https://github.com/anthropics/skills) — 官方技能仓库，可直接安装或作为编写参考
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — 官方插件列表，通过 marketplace 一键安装
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — 社区精选资源，包含教程、工具和最佳实践
- [wshobson/agents](https://github.com/wshobson/agents) — 更多专业子代理，可按需引入

---

如果这个项目对你有帮助，欢迎点个 ⭐ 支持一下！

## 许可证

本项目基于 MIT 许可证发布 — 详见 [LICENSE](LICENSE)。
