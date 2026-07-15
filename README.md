# Claude Code 配置与技能集

Claude Code 设置、技能（Skills）和子代理（Sub-agents）合集，涵盖头脑风暴与设计审查、深度调研、GitHub 集成、翻译、图片生成等增强型开发工作流。

> OpenAI Codex 的配置和自定义 prompt 请参考 [feiskyer/codex-settings](https://github.com/feiskyer/codex-settings)。

## 安装

### 方式一：Claude Code Plugin（推荐）

```sh
/plugin marketplace add feiskyer/claude-code-settings

# 安装主插件（包含所有技能和代理）
/plugin install claude-code-settings
```

主插件包含的完整技能列表：brainstorming、codex-skill、deep-research、github-fix-issue、github-review-pr、gpt-image-skill、grill-me、handoff、nanobanana-skill、skill-creator、translate、youtube-transcribe-skill，详见[技能列表](#技能列表)。单个技能也可以通过 [npx skills](#方式二npx-skills) 按需安装。

**注意：** [~/.claude/settings.json](settings.json) 不通过 Plugin 配置，需要手动设置。

### 方式二：npx skills

`npx skills` 可以为你的 AI 编程工具安装技能：

```sh
# 列出可用技能
npx -y skills add -l feiskyer/claude-code-settings

# 安装全部技能
npx -y skills add --all feiskyer/claude-code-settings

# 手动选择要安装的技能
npx -y skills add feiskyer/claude-code-settings
```

### 方式三：手动安装

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

   - ANTHROPIC_DEFAULT_SONNET_MODEL: claude-sonnet-4-6
   - ANTHROPIC_DEFAULT_OPUS_MODEL: claude-opus-4-6
   - ANTHROPIC_DEFAULT_HAIKU_MODEL: claude-haiku-4-5
3. 模板中 `defaultMode` 为 `acceptEdits`（自动接受文件编辑但保留命令确认）。如需完全跳过权限确认可自行改为 `bypassPermissions`，但请了解其安全风险后再启用。

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

非交互式自动化模式，使用 OpenAI Codex 完成 Claude 设计好的功能或计划。

**触发词：** "codex", "use gpt", "gpt-5", "let openai", "full-auto", "用codex", "让gpt实现"

**核心特性：**

- 多种执行模式（只读、工作区写入、完全访问）
- 默认使用 `~/.codex/config.toml` 中配置的模型
- 自主执行无需审批
- JSON 结构化输出、可恢复会话
- CLI 完整参考和场景示例见 `references/` 目录

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

将英文或日文技术文章翻译为自然流畅的中文。采用三步法（直译、问题识别、意译），保留 Markdown 格式和技术术语原文。

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

使用并行子代理进行多角度代码分析，支持置信度评分和误报过滤。

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

| 配置文件 | 说明 |
|----------|------|
| [copilot-settings.json](settings/copilot-settings.json) | GitHub Copilot 代理 |
| [litellm-settings.json](settings/litellm-settings.json) | LiteLLM 网关 |
| [deepseek-settings.json](settings/deepseek-settings.json) | DeepSeek v3.1 |
| [qwen-settings.json](settings/qwen-settings.json) | Qwen3-Coder-Plus（阿里云 DashScope） |
| [siliconflow-settings.json](settings/siliconflow-settings.json) | SiliconFlow（Kimi-K2-Instruct） |
| [vertex-settings.json](settings/vertex-settings.json) | Google Cloud Vertex AI |
| [azure-settings.json](settings/azure-settings.json) | Azure AI（Anthropic 兼容端点） |
| [azure-foundry-settings.json](settings/azure-foundry-settings.json) | Azure AI Foundry 原生模式 |
| [minimax.json](settings/minimax.json) | MiniMax-M3, MiniMax-M2.7, and MiniMax-M2 (global endpoint) |
| [minimax-cn.json](settings/minimax-cn.json) | MiniMax-M3, MiniMax-M2.7, and MiniMax-M2 (China endpoint) |
| [openrouter-settings.json](settings/openrouter-settings.json) | OpenRouter（多模型统一 API） |

## 脚本工具

[`scripts/`](scripts/) 目录包含维护 Claude Code 环境的实用脚本。

| 脚本 | 功能 |
|------|------|
| [`update-cc-plugins.sh`](scripts/update-cc-plugins.sh) | 一键更新所有已安装的 marketplace 和插件/技能 |

```sh
bash ~/.claude/scripts/update-cc-plugins.sh
```

## 开发与测试

修改本仓库的技能或配置后，可以用 `CLAUDE_CONFIG_DIR` 环境变量把 Claude Code 的配置目录直接指向仓库，进行真实测试而不影响 `~/.claude` 下的日常配置：

```sh
# 在任意项目目录用本仓库的配置启动一次性测试会话
CLAUDE_CONFIG_DIR=/path/to/claude-code-settings claude

# 非交互式冒烟测试：验证技能是否正确加载
CLAUDE_CONFIG_DIR=/path/to/claude-code-settings \
  claude -p "List every skill you can currently invoke" --max-turns 2

# 也可以固定成别名
alias claude-test='CLAUDE_CONFIG_DIR=/path/to/claude-code-settings claude'
```

**验证要点：**

- 技能列表应包含仓库 `skills/` 下的技能；`grill-me` 和 `handoff` 因设置了 `disable-model-invocation: true` 不会出现在自动触发列表中，需用 `/grill-me`、`/handoff` 手动调用验证
- 修改 SKILL.md 描述后，可用自然语言请求（而非 `/skill-name`）测试自动触发是否符合预期
- 技能结构校验：`cd skills/skill-creator && python3 -m scripts.quick_validate ../<skill-name>`

**注意：** 测试会话会把运行时状态写回仓库目录（`.claude.json`、`projects/`、settings.json 的字段重排等）。运行时产物已在 `.gitignore` 中忽略，但测试后建议 `git diff` 确认 settings.json 没有混入不想入库的个人设置。

## 已知限制

**WebSearch** 是 [Anthropic 专有工具](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/web-search-tool)，在非官方 Anthropic API 环境下不可用。如需网页搜索，请接入外部 MCP 服务器：

- [Tavily MCP](https://docs.tavily.com/documentation/mcp)
- [Brave MCP](https://github.com/brave/brave-search-mcp-server)
- [Firecrawl MCP](https://docs.firecrawl.dev/mcp-server)
- [DuckDuckGo Search MCP](https://github.com/nickclyde/duckduckgo-mcp-server)

## 常见问题

<details>
<summary>VSCode 中 Claude Code 2.0+ 扩展的登录问题</summary>

如果不使用 Claude.ai 订阅，需在 VSCode settings.json 中手动配置环境变量：

```json
{
  "claude-code.environmentVariables": [
    { "name": "ANTHROPIC_BASE_URL", "value": "http://localhost:4000" },
    { "name": "ANTHROPIC_AUTH_TOKEN", "value": "sk-dummy" },
    { "name": "ANTHROPIC_MODEL", "value": "opusplan" },
    { "name": "ANTHROPIC_DEFAULT_SONNET_MODEL", "value": "claude-sonnet-4-6" },
    { "name": "ANTHROPIC_DEFAULT_OPUS_MODEL", "value": "claude-opus-4-6" },
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

## 参考指南

- [使用 GitHub Copilot 作为模型提供商](guidances/github-copilot.md)
- [使用 LLM 网关（LiteLLM）作为模型提供商](guidances/llm-gateway-litellm.md)

## 参考资源

- [Claude Code 官方文档](https://docs.anthropic.com/en/docs/claude-code/overview) — 必读
- [anthropics/skills](https://github.com/anthropics/skills) — 官方技能列表
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — Anthropic 官方插件列表
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — 社区精选资源
- [wshobson/agents](https://github.com/wshobson/agents) — Claude Code 专业子代理合集

## 许可证

本项目基于 MIT 许可证发布 — 详见 [LICENSE](LICENSE)。
