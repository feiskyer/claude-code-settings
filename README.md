# Claude Code Settings/Commands/Skills for Vibe Coding

[![Run in Smithery](https://smithery.ai/badge/skills/feiskyer)](https://smithery.ai/skills?ns=feiskyer&utm_source=github&utm_medium=badge)


A curated collection of Claude Code settings, custom commands, skills and sub-agents designed for enhanced development workflows. This setup includes specialized commands, skills and subagents for feature development (spec-driven workflow), code analysis, GitHub integration, and knowledge management.

> For OpenAI Codex settings, configurations and custom prompts, please refer [feiskyer/codex-settings](https://github.com/feiskyer/codex-settings).

## Setup

### Using Claude Code Plugin

```sh
/plugin marketplace add feiskyer/claude-code-settings

# Install main plugin (commands, agents and skills)
/plugin install claude-code-settings

# Alternatively, install individual skills without commands/agents
/plugin install codex-skill               # Codex automation
/plugin install autonomous-skill          # Long-running task automation
/plugin install nanobanana-skill          # Image generation
/plugin install kiro-skill                # Kiro workflow
/plugin install spec-kit-skill            # Spec-Kit workflow
/plugin install youtube-transcribe-skill  # YouTube transcript extraction
```

Alternatively, run a one-command installation via the [Claude Plugins CLI](https://claude-plugins.dev) to skip the marketplace setup:

```bash
npx claude-plugins install @feiskyer/claude-code-settings/claude-code-settings
```

This automatically adds the marketplace and installs the plugin in a single step.

**Note:**

- [~/.claude/settings.json](settings.json) is not configured via Claude Code Plugin, you'd need to configure it manually.

### Manual Setup

```sh
# Backup original claude settings
mv ~/.claude ~/.claude.bak

# Clone the claude-code-settings
git clone https://github.com/feiskyer/claude-code-settings.git ~/.claude

# Install LiteLLM proxy
pip install -U 'litellm[proxy]'

# Start litellm proxy (which would listen on http://0.0.0.0:4000)
litellm -c ~/.claude/guidances/litellm_config.yaml

# For convenience, run litellm proxy in background with tmux
# tmux new-session -d -s copilot 'litellm -c guidances/litellm_config.yaml'
```

Once started, you'll see:

```sh
...
Please visit https://github.com/login/device and enter code XXXX-XXXX to authenticate.
...
```

Open the link, log in and authenticate your GitHub Copilot account.

**Note:**

1. The default configuration is leveraging [LiteLLM Proxy Server](https://docs.litellm.ai/docs/simple_proxy) as LLM gateway to GitHub Copilot. You can also use [copilot-api](https://github.com/ericc-ch/copilot-api) as the proxy as well (remember to change your port to 4141).
2. Make sure the following models are available in your account; if not, replace them with your own model names:

- ANTHROPIC_DEFAULT_SONNET_MODEL: claude-sonnet-4.5
- ANTHROPIC_DEFAULT_OPUS_MODEL: claude-opus-4
- ANTHROPIC_DEFAULT_HAIKU_MODEL: gpt-5-mini

## Commands

The `commands/` directory contains [custom slash commands](https://code.claude.com/docs/en/slash-commands) that extend Claude Code's slash commands, which could be invoked via `/<command-name> [arguments]`.

<details>
<summary>Analysis & Reflection</summary>

### Analysis & Reflection

- `/think-harder [problem]` - Enhanced analytical thinking
- `/think-ultra [complex problem]` - Ultra-comprehensive analysis
- `/reflection` - Analyze and improve Claude Code instructions
- `/reflection-harder` - Comprehensive session analysis and learning
- `/eureka [breakthrough]` - Document technical breakthroughs

</details>

<details>
<summary>GitHub Integration</summary>

### GitHub Integration

- `/gh:review-pr [PR_NUMBER]` - Comprehensive PR review and comments
- `/gh:fix-issue [issue-number]` - Complete issue resolution workflow

</details>

<details>
<summary>Documentation & Knowledge</summary>

### Documentation & Knowledge

- `/cc:create-command [name] [description]` - Create new Claude Code commands

</details>

<details>
<summary>Utilities</summary>

### Utilities

- `/translate [text]` - Translate English/Japanese tech content to Chinese

</details>

## Skills

Skills are now distributed as separate plugins for modular installation. Install only what you need:

<details>
<summary>codex-skill - handoff task to Codex CLI</summary>

### [codex-skill](plugins/codex-skill)

Non-interactive automation mode for hands-off task execution using OpenAI Codex. Use when you want to leverage codex, gpt-5, or gpt-5.1 to implement features or plans designed by Claude.

**Installation:**

```sh
/plugin marketplace add feiskyer/claude-code-settings
/plugin install codex-skill
```

**Key Features:**

- Multiple execution modes (read-only, workspace-write, danger-full-access)
- Model selection support (gpt-5, gpt-5.1, gpt-5.1-codex, etc.)
- Autonomous execution without approval prompts
- JSON output support for structured results
- Resumable sessions

**Requirements:** Codex CLI installed (`npm i -g @openai/codex` or `brew install codex`)

</details>

<details>
<summary>autonomous-skill - Long-running task automation</summary>

### [autonomous-skill](plugins/autonomous-skill)

Execute complex, long-running tasks across multiple sessions using a dual-agent pattern (Initializer + Executor) with automatic session continuation.

**Installation:**

```sh
/plugin marketplace add feiskyer/claude-code-settings
/plugin install autonomous-skill
```

**Key Features:**

- Dual-agent pattern (Initializer creates a task list, Executor completes tasks)
- Auto-continuation across sessions with progress tracking
- Task isolation with per-task directories (`.autonomous/<task-name>/`)
- Progress persistence via `task_list.md` and `progress.md`
- Headless mode execution using Claude CLI

**Usage:**

```text
You: "Please use autonomous skill to build a REST API for a todo app"
Claude: [Creates .autonomous/build-rest-api-todo/, initializes task list, starts execution]
```

**Requirements:** Claude CLI installed

</details>

<details>
<summary>nanobanana-skill - draw image with Gemini nanobanana</summary>

### [nanobanana-skill](plugins/nanobanana-skill)

Generate or edit images using Google Gemini API via nanobanana. Use when creating, generating, or editing images.

**Installation:**

```sh
/plugin marketplace add feiskyer/claude-code-settings
/plugin install nanobanana-skill
```

**Key Features:**

- Image generation with various aspect ratios
- Image editing capabilities
- Multiple model options (gemini-3-pro-image-preview, gemini-2.5-flash-image)
- Resolution options (1K, 2K, 4K)
- Support for various aspect ratios (square, portrait, landscape, ultra-wide)

**Requirements:**

- GEMINI_API_KEY configured in `~/.nanobanana.env`
- Python3 with google-genai, Pillow, python-dotenv (install via `pip install -r requirements.txt` in the plugin directory)

</details>

<details>
<summary>youtube-transcribe-skill - Extract YouTube subtitles</summary>

### [youtube-transcribe-skill](plugins/youtube-transcribe-skill)

Extract subtitles/transcripts from a YouTube video link.

**Installation:**

```sh
/plugin marketplace add feiskyer/claude-code-settings
/plugin install youtube-transcribe-skill
```

**Key Features:**

- Dual extraction methods: CLI (fast) and Browser Automation (fallback)
- Automatic subtitle language selection (zh-Hans, zh-Hant, en)
- Efficient DOM-based extraction for browser method
- Saves transcripts to local text files

**Requirements:**

- `yt-dlp` (for CLI method)
- or `chrome-devtools-mcp` (for browser automation method)

</details>

<details>
<summary>kiro-skill - Interactive Feature Development</summary>

### [kiro-skill](./skills/kiro-skill)

Interactive feature development workflow from idea to implementation.

**Triggered by**: "kiro", or references to `.kiro/specs/` directory

**Installation:**

```sh
/plugin marketplace add feiskyer/claude-code-settings
/plugin install kiro-skill
```

**Workflow**:

1. **Requirements** → Define what needs to be built (EARS format with user stories)
2. **Design** → Determine how to build it (architecture, components, data models)
3. **Tasks** → Create actionable implementation steps (test-driven, incremental)
4. **Execute** → Implement tasks one at a time

**Usage**:

```text
You: "I need to create a kiro feature spec for user authentication"
Claude: [Automatically uses kiro-skill]
```

</details>

<details>
<summary>spec-kit-skill - Constitution-Based Development</summary>

### [spec-kit-skill](./skills/spec-kit-skill)

GitHub Spec-Kit integration for constitution-based spec-driven development.

**Triggered by**: "spec-kit", "speckit", "constitution", "specify", or references to `.specify/` directory

**Installation:**

```sh
/plugin marketplace add feiskyer/claude-code-settings
/plugin install spec-kit-skill
```

**Prerequisites**:

```sh
# Install spec-kit CLI
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Initialize project
specify init . --ai claude
```

**7-Phase Workflow**:

1. **Constitution** → Establish governing principles
2. **Specify** → Define functional requirements
3. **Clarify** → Resolve ambiguities (max 5 questions)
4. **Plan** → Create technical strategy
5. **Tasks** → Generate dependency-ordered tasks
6. **Analyze** → Validate consistency (read-only)
7. **Implement** → Execute implementation

**Usage**:

```text
You: "Let's create a constitution for this project"
Claude: [Automatically uses spec-kit-skill, detects CLI, guides through phases]
```

</details>

## Agents

The `agents/` directory contains specialized AI [subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents) that extend Claude Code's capabilities.

<details>
<summary>Available Agents</summary>

- **pr-reviewer** - Expert code reviewer for GitHub pull requests
- **github-issue-fixer** - GitHub issue resolution specialist
- **instruction-reflector** - Analyzes and improves Claude Code instructions
- **deep-reflector** - Comprehensive session analysis and learning capture
- **insight-documenter** - Technical breakthrough documentation specialist
- **ui-engineer** - UI/UX development specialist
- **command-creator** - Expert at creating new Claude Code custom commands

</details>

## Settings

[Sample Settings](settings/README.md) - Pre-configured settings for various model providers and setups.

<details>
<summary>Available Settings</summary>

### [copilot-settings.json](settings/copilot-settings.json)

Using Claude Code with GitHub Copilot proxy. Points to localhost:4141 for the Anthropic API base URL.

### [litellm-settings.json](settings/litellm-settings.json)

Using Claude Code with LiteLLM gateway. Points to localhost:4000 for the Anthropic API base URL.

### [deepseek-settings.json](settings/deepseek-settings.json)

Using Claude Code with DeepSeek v3.1 (via DeepSeek's official Anthropic-compatible API).

### [qwen-settings.json](settings/qwen-settings.json)

Using Claude Code with Qwen models via Alibaba's DashScope API. Uses the Qwen3-Coder-Plus model through a claude-code-proxy.

### [siliconflow-settings.json](settings/siliconflow-settings.json)

Using Claude Code with SiliconFlow API. Uses the Moonshot AI Kimi-K2-Instruct model.

### [vertex-settings.json](settings/vertex-settings.json)

Using Claude Code with Google Cloud Vertex AI. Uses Claude Opus 4 model with Google Cloud project settings.

### [azure-settings.json](settings/azure-settings.json)

Configuration for using Claude Code with Azure AI (Anthropic-compatible endpoint). Points to Azure AI services endpoint.

### [azure-foundry-settings.json](settings/azure-foundry-settings.json)

Configuration for using Claude Code with Azure AI Foundry native mode. Uses `CLAUDE_CODE_USE_FOUNDRY` flag with Claude Opus 4.1 + Sonnet 4.5 model.

### [minimax.json](settings/minimax.json)

Configuration for using Claude Code with MiniMax API. Uses the MiniMax-M2 model.

</details>

## Limitations

**WebSearch** tool in Claude Code is an [Anthropic specific tool,](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/web-search-tool) and it is not available when you’re not using the official Anthropic API. Hence, if you need web search, you'd need to connect Claude Code with external web search MCP servers, e.g. [Tavily MCP](https://docs.tavily.com/documentation/mcp), [Brave MCP](https://github.com/brave/brave-search-mcp-server), [Firecrawl MCP](https://docs.firecrawl.dev/mcp-server) or [DuckDuckGo Search MCP](https://github.com/nickclyde/duckduckgo-mcp-server).

## FAQs

<details>
<summary>Login Issue of Claude Code 2.0+ extension in VSCode</summary>

For Claude Code 2.0+ extension in VSCode, if you're not using a Claude.ai subscription, please put the environment variables manually in your vscode settings.json:

```json
{
  "claude-code.environmentVariables": [
    {
      "name": "ANTHROPIC_BASE_URL",
      "value": "http://localhost:4000"
    },
    {
      "name": "ANTHROPIC_AUTH_TOKEN",
      "value": "sk-dummy"
    },
    {
      "name": "ANTHROPIC_MODEL",
      "value": "opusplan"
    },
    {
      "name": "ANTHROPIC_DEFAULT_SONNET_MODEL",
      "value": "claude-sonnet-4.5"
    },
    {
      "name": "ANTHROPIC_DEFAULT_OPUS_MODEL",
      "value": "claude-opus-4"
    },
    {
      "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL",
      "value": "gpt-5-mini"
    },
    {
      "name": "DISABLE_NON_ESSENTIAL_MODEL_CALLS",
      "value": "1"
    },
    {
      "name": "DISABLE_TELEMETRY",
      "value": "1"
    },
    {
      "name": "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
      "value": "1"
    }
  ]
}
```

Note that the contents of [~/.claude/config.json](config.json) are also required to skip claude.ai login.

</details>

<details>
<summary>Missing API Key and Invalid API Key issues</summary>

Ensure the API key you configured in `ANTHROPIC_AUTH_TOKEN` is added to approved API key in `~/.claude.json`, e.g.

```javascript
{
  "customApiKeyResponses": {
    "approved": [
      "sk-dummy"
    ],
    "rejected": []
  },
  ... (your other settings)
}
```

</details>

## Guidances

- [Claude Code with GitHub Copilot as Model Provider](guidances/github-copilot.md).
- [Claude Code with LLM Gateway (LiteLLM) as Model Provider](guidances/llm-gateway-litellm.md).

## References

- [Claude Code official document](https://docs.anthropic.com/en/docs/claude-code/overview) - must read official document.
- [anthropics/skills](https://github.com/anthropics/skills) - official list of Claude Code skills that teach Claude how to complete specific tasks in a repeatable way
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) - curated list of slash-commands, CLAUDE.md files, CLI tools, and other resources.
- [wshobson/agents](https://github.com/wshobson/agents) - a comprehensive collection of specialized AI subagents for Claude Code.

## LICENSE

This project is released under MIT License - See [LICENSE](LICENSE) for details.
