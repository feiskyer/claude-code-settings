# 使用 Parallel MCP 核验公开资料来源

当你需要核实文档中的一条具体说法时，可以在普通 Claude Code 会话中使用 Parallel 搜索公开资料，再读取原文核对。此流程按项目单独启用，不需要安装新的技能。

## 1. 在需要核验的项目中启用

先运行 `claude mcp list` 并检查 `/mcp`。如果已有手动配置或插件提供的 Parallel 搜索连接，直接复用，避免重复添加。

否则，在目标项目目录中执行：

```sh
claude mcp add --transport http --scope local parallel \
  'https://mcp.parallel.ai/mcp?tools=web_search,web_fetch' \
  --header 'User-Agent: claude-code-settings/parallel-source-check'

claude mcp get parallel
claude
```

`local` scope 只对当前项目和当前用户生效，配置保存在用户配置中；不会写入项目的 `.mcp.json`。这个连接仅提供 `web_search` 和 `web_fetch`。匿名调用无需 Parallel API key，但有速率限制，详见 [Parallel MCP setup](https://docs.parallel.ai/integrations/mcp/quickstart)。

在新会话中运行 `/mcp`，确认 `parallel` 已连接且这两个工具可用。保留 Claude Code 的工具权限确认，按提示审核本次调用的参数。

## 2. 搜索、读取原文、给出引用

只发送你明确允许公开查询的问题、关键词和公开 URL。不要把本地文件、内部项目名称、凭据或私有链接作为工具参数。

例如，在普通会话中输入：

```text
请用 Parallel 的 web_search 核验：Python asyncio.TaskGroup 是在哪个版本加入的？
只查询公开的 Python 官方文档。搜索后选择结果中的 docs.python.org 原始 URL，
用 web_fetch 读取该页中与引入版本有关的原文，不要读取本地文件。
最后用中文给出结论、支持结论的简短证据，以及工具结果中的原始来源链接。
如果没有找到足够证据，请明确说明未能核实。
```

核验时检查：

- 工具调用记录中先出现该连接的 `web_search`，随后出现针对所选来源的 `web_fetch`。
- 读取的页面来自 `docs.python.org`，内容确实支持结论；搜索摘要只是线索。
- 最终回答保留工具结果中的原始 URL，方便读者打开原文核对。

## 3. 连接失败或结束使用

连接不可用、请求超时或触发速率限制时，先在 `/mcp` 检查状态；不要把失败当作“没有相关资料”。搜索为空或原文无法支持结论时，应报告未能核实。需要改用其他已配置的工具时，先说明情况并征得用户同意。

结束使用后，在同一项目目录移除这个手动添加的连接：

```sh
claude mcp remove --scope local parallel
```

更多配置、scope 和连接排错说明见 [Claude Code MCP 文档](https://code.claude.com/docs/en/mcp)。
