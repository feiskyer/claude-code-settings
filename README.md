# Claude Code Settings/Skills for Vibe Coding

A curated collection of Claude Code settings, skills and sub-agents designed for enhanced development workflows. This setup includes specialized skills and subagents for feature development (spec-driven workflow), code analysis, GitHub integration, and knowledge management.

> For OpenAI Codex settings, configurations and custom prompts, please refer [feiskyer/codex-settings](https://github.com/feiskyer/codex-settings).

## Setup

### Using Claude Code Plugin

```sh
/plugin marketplace add feiskyer/claude-code-settings

# Install main plugin (skills and agents)
/plugin install claude-code-settings

# Alternatively, install individual skills
/plugin install codex-skill               # Codex automation
/plugin install autonomous-skill          # Long-running task automation
/plugin install nanobanana-skill          # Image generation
/plugin install kiro-skill                # Kiro workflow
/plugin install spec-kit-skill            # Spec-Kit workflow
/plugin install youtube-transcribe-skill  # YouTube transcript extraction
```

**Note:**

- [~/.claude/settings.json](settings.json) is not configured via Claude Code Plugin, you'd need to configure it manually.

### Using npx skills

`npx skills` could be used to install skills only for your AI coding tools.

```sh
# List skills
npx -y skills add -l feiskyer/claude-code-settings

# Install all skills
npx -y skills add --all feiskyer/claude-code-settings

# Manually select a list of skills to install
npx -y skills add feiskyer/claude-code-settings
```

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
# tmux new-session -d -s copilot 'litellm -c ~/.claude/guidances/litellm_config.yaml'
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

   - ANTHROPIC_DEFAULT_SONNET_MODEL: claude-sonnet-4.6
   - ANTHROPIC_DEFAULT_OPUS_MODEL: claude-opus-4.6
   - ANTHROPIC_DEFAULT_HAIKU_MODEL: gpt-5-mini

## Skills

Skills are [reusable capabilities](https://docs.anthropic.com/en/docs/claude-code/skills) that teach Claude how to complete specific tasks. They can be invoked via `/skill-name [arguments]` or triggered automatically based on context. Install only what you need:

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
<summary>deep-research - Multi-Agent Research Orchestration</summary>

### [deep-research](./skills/deep-research)

Multi-agent orchestration workflow for deep research. Decomposes research goals into parallel sub-objectives, spawns `claude -p` sub-processes, aggregates results, and delivers polished reports.

**Triggered by**: "深度调研", "deep research", "wide research", "multi-agent research", or systematic research needs

**Key Features:**

- **Multi-agent orchestration**: Splits research goals into parallel sub-tasks executed via `claude -p`
- **Skills-first approach**: Prioritizes installed skills, then MCP tools (firecrawl → exa), then WebFetch/WebSearch
- **Structured delivery**: Produces file-based reports with executive summaries, not chat messages
- **Chapter-by-chapter refinement**: Iterative polishing with source verification
- **Comprehensive logging**: Dispatcher logs, per-task logs, raw data caching
- **Scale-aware execution**: Micro (1-2 tasks) to large (15+) with appropriate parallelization

**Use Cases:**

- Systematic web/document research
- Competitive/industry analysis
- Batch URL/dataset processing
- Long-form writing with evidence integration

**Directory Structure:**

```
.research/<name>/
├── prompts/           # Sub-task prompts
├── child_outputs/     # Sub-process outputs
├── logs/              # Execution logs
├── raw/               # Cached raw data
└── final_report.md    # Polished deliverable
```

**Usage:**

```text
You: "深度调研一下 AI Agent 框架的现状"
Claude: [Initiates reconnaissance, proposes sub-objectives, waits for confirmation, then orchestrates parallel research]
```

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

<details>
<summary>reflection - Session analysis and CLAUDE.md improvement</summary>

### [reflection](./skills/reflection)

Analyze development sessions, capture learnings, and improve Claude Code instructions. Supports two modes:

- **Quick mode** (`/reflection`): Analyzes chat history to identify and implement CLAUDE.md improvements
- **Deep mode** (`/reflection deep`): Comprehensive session analysis covering problems solved, patterns, user preferences, system understanding, and knowledge gaps

</details>

<details>
<summary>eureka - Technical breakthrough documentation</summary>

### [eureka](./skills/eureka)

Capture technical breakthroughs and transform them into actionable, reusable documentation. Creates structured breakthrough files in `breakthroughs/` with problem/insight/implementation/impact sections and maintains a searchable index.

**Usage:**

```text
You: "/eureka Reduced API response time from 2s to 100ms by implementing request batching"
Claude: [Creates breakthroughs/2025-01-15-api-request-batching.md, updates INDEX.md]
```

</details>

<details>
<summary>translate - Tech article translation to Chinese</summary>

### [translate](./skills/translate)

Translate English or Japanese tech articles into natural, fluent Chinese using a three-step process (direct translation, issue identification, reinterpretation). Preserves Markdown formatting and keeps technical terms and brand names untranslated.

**Usage:**

```text
You: "/translate [paste text or provide file path]"
Claude: [Outputs polished Chinese translation]
```

</details>

<details>
<summary>command-creator - Create Claude Code custom commands</summary>

### [command-creator](./skills/command-creator)

Create Claude Code custom slash commands with proper structure, frontmatter, and best practices.

</details>

<details>
<summary>github-fix-issue - Fix GitHub issues end-to-end</summary>

### [github-fix-issue](./skills/github-fix-issue)

Fix GitHub issues from analysis through branch creation, implementation, testing, and PR submission.

</details>

<details>
<summary>github-review-pr - Review GitHub pull requests</summary>

### [github-review-pr](./skills/github-review-pr)

Review GitHub pull requests with detailed, multi-perspective code analysis using parallel subagents with confidence scoring and false positive filtering.

</details>

<details>
<summary>skill-creator - Create and benchmark agent skills</summary>

### [skill-creator](./skills/skill-creator)

Create, refine, and benchmark agent skills with iterative evaluation loops, quantitative metrics, and description optimization.

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

### [openrouter-settings.json](settings/openrouter-settings.json)

Using Claude Code with OpenRouter API. OpenRouter provides access to many models through a unified API. Note: `ANTHROPIC_API_KEY` must be blank while `ANTHROPIC_AUTH_TOKEN` contains your OpenRouter API key.

</details>

## Scripts

The [`scripts/`](scripts/) directory contains utility shell scripts for maintaining your Claude Code setup.

| Script | Description |
|--------|-------------|
| [`update-cc-plugins.sh`](scripts/update-cc-plugins.sh) | Update all installed Claude Code marketplaces and plugins/skills in one command |

**Usage:**

```sh
bash ~/.claude/scripts/update-cc-plugins.sh
```

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
      "value": "claude-sonnet-4.6"
    },
    {
      "name": "ANTHROPIC_DEFAULT_OPUS_MODEL",
      "value": "claude-opus-4.6"
    },
    {
      "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL",
      "value": "gpt-5-mini"
    },
    {
      "name": "DISABLE_TELEMETRY",
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
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) - official list of Claude Code plugins managed by Anthropic
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) - curated list of slash-commands, CLAUDE.md files, CLI tools, and other resources.
- [wshobson/agents](https://github.com/wshobson/agents) - a comprehensive collection of specialized AI subagents for Claude Code.

## LICENSE

This project is released under MIT License - See [LICENSE](LICENSE) for details.
