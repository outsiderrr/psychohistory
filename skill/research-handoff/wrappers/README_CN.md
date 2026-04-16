# Research Wrappers（研究包装脚本）

[English](./README.md) · **中文**

通过直接调用有搜索能力的 LLM API 来自动化 Research Hand-off 协议的参考脚本。如果你已经有支持的某个服务商的 API 密钥，并且想跳过 CLI 和对话 AI 之间的手动复制粘贴，就用这些脚本。

## 这是给谁用的

主要给**自带 API 密钥**的 CLI agent 用户——OpenClaw / Cline / Aider / goose / continue.dev 等——这类 CLI agent 的正常使用就需要 API 密钥，密钥本来就在环境变量里。脚本在任何能跑 Bash 的 CLI agent 里都能用。

**Claude Code 用户**也能用：Claude Code 不会把它的内部 API 凭据暴露给你的 shell，但你可以独立配置一个专门用于研究步骤的 API 密钥（Perplexity / Anthropic / OpenAI / Gemini）。

## skill 如何使用它们

`character-toolkit/SKILL.md` Step 3.1（Research Phase Handling）会检查 `PSYCHOHISTORY_RESEARCH_TOOL` 环境变量：

1. 如果它指向一个可执行文件，skill 会把填好的研究提示词通过 stdin 传给它、从 stdout 读研究结果、整合进 `references.md`——**完全跳过手动复制粘贴**。
2. 如果可执行文件失败（非零退出码、空输出、超时），skill 报告错误并降级到标准 Research Hand-off（手动复制粘贴到对话 AI）。
3. 如果 `PSYCHOHISTORY_RESEARCH_TOOL` 未设置，skill 直接走标准 Research Hand-off。

## 可用的 wrapper

| 脚本 | 服务商 | 环境变量 | 说明 |
|---|---|---|---|
| `perplexity.sh` | Perplexity | `PERPLEXITY_API_KEY` | 专用的研究型 LLM，自带网络搜索。**推荐默认**——为这个用例而生，API 最干净 |
| `anthropic.sh` | Anthropic Claude | `ANTHROPIC_API_KEY` | 用 Claude + `web_search_20250305` 工具；合成能力强 |
| `openai.sh` | OpenAI | `OPENAI_API_KEY` | 用 `gpt-4o-search-preview`（Chat Completions 端点） |
| `gemini.sh` | Google Gemini | `GEMINI_API_KEY` 或 `GOOGLE_API_KEY` | 用 Gemini 2.5 Pro + `google_search` grounding |

## 配置步骤

1. **选一个 wrapper**。根据你已有的 API 密钥来选（或从零开始——研究场景推荐 Perplexity）。只需要一个就够。

2. **在 shell 配置里导出 API 密钥**（`~/.bashrc` / `~/.zshrc` 等）：

   ```bash
   export PERPLEXITY_API_KEY="pplx-..."
   ```

3. **把 `PSYCHOHISTORY_RESEARCH_TOOL` 指向 wrapper 脚本的绝对路径**：

   ```bash
   export PSYCHOHISTORY_RESEARCH_TOOL="$HOME/Desktop/psychohistory/skill/character-toolkit/research-wrappers/perplexity.sh"
   ```

4. **给脚本加执行权限**：

   ```bash
   chmod +x "$HOME/Desktop/psychohistory/skill/character-toolkit/research-wrappers/"*.sh
   ```

5. **用简单的提示词测试**：

   ```bash
   echo "What is the population of Iceland as of 2025?" | "$PSYCHOHISTORY_RESEARCH_TOOL"
   ```

   你应该看到一段文本答案（不是错误信息）。如果失败，看 stderr 里的错误信息定位问题。

6. **重载 shell**（`source ~/.zshrc` 或打开新终端），然后正常调用 `character-toolkit/SKILL.md`。研究阶段会自动走 wrapper。

## ⚠️ 真正使用前需要验证

这些 wrapper 脚本是**基于 2025-05 时候的 API 形态写的参考模板**。LLM API 格式会随时间演进；在用于真实项目之前，你应该：

1. **检查你选定服务商的当前 API 文档**——端点、auth header、模型名、请求/响应结构都可能已经变了
2. **跑一下上面第 5 步的测试命令**
3. **确认输出是真实的答案**，不是错误转储

按服务商列出的"易失点"：

- **Perplexity** —— 模型名（`sonar-pro` 在 2025 年有效；注意改名）
- **Anthropic** —— `web_search` 工具类型（`web_search_20250305`）和模型名（`claude-sonnet-4-5`）；两者都会有新版本
- **OpenAI** —— `gpt-4o-search-preview` 可用性变动较大；可能需要切到 Responses API 配合显式 `web_search` 工具，或换到新的搜索能力模型
- **Gemini** —— `google_search` grounding 格式和模型名（`gemini-2.5-pro`）；Google 的 API 比其他家变动更频繁

如果发现某个脚本需要更新，直接编辑它——脚本都被刻意写得很短（< 100 行），自包含。考虑把更新贡献回仓库。

## 成本和 rate limit 提醒

每次调用 wrapper 都是一次**真实的付费 API 调用**。单张卡的研究（2-5K 输出 token）粗略估算：

| 服务商 | 单卡大致成本 |
|---|---|
| Perplexity Sonar Pro | $0.01 – $0.03 |
| Claude Sonnet 4.5 + web_search | $0.05 – $0.15（tool-use 循环成本更高） |
| GPT-4o-search-preview | $0.02 – $0.08 |
| Gemini 2.5 Pro + grounding | $0.02 – $0.06 |

批量研究时（见 `character-toolkit/SKILL.md` §Step 5.3 Batch Research Collection），成本大致线性或略低于线性。

Rate limit：每家服务商各有自己的限额。日常用（每天几张卡）基本不会碰到限额；批量生成几十张卡时先查一下你的配额。

## Wrapper 契约

`character-toolkit/SKILL.md` 对 `PSYCHOHISTORY_RESEARCH_TOOL` 指向的可执行文件**只期待 3 件事**：

1. **从 stdin 读研究提示词**（纯文本，可能含多行 markdown）
2. **把研究结果写到 stdout**（纯文本或 markdown）
3. **成功时退出码 0**，失败时非零（错误细节走 stderr）

就这么多。**你可以写自己的 wrapper**——不必用这 4 个模板。可能的变体：

- 本地 Ollama 实例 + 搜索插件（Perplexica 式）
- RAG 管线对接你的私有研究语料
- 链式调用（单独的搜索 API → 单独的合成 LLM）
- 带缓存的 wrapper：按提示词哈希缓存结果，仅在 miss 时调 API
- 多服务商 wrapper：先试 Perplexity，失败时 fallback 到 Anthropic

只要你的 wrapper 遵守上面的契约，skill 就能用它。

## 为什么不是默认自动调用

skill 是 **CLI-first** 设计，刻意要在不同 CLI agent 之间保持可移植。如果强制要求某个特定工具（像 Claude Code 的 `WebFetch`）或特定的 MCP server 配置，就破坏了这个可移植性。`PSYCHOHISTORY_RESEARCH_TOOL` 环境变量是一个**opt-in 的逃逸通道**：想要自动化的用户配置它；不想配的用户继续用标准 Research Hand-off（手动复制粘贴）。两条路径产出的 references.md 质量完全一样——区别只在于"有没有人工的环节"。

关于 MCP 集成和 engine 阶段的直接 API 集成，见 `../README_CN.md` §CLI-first 设计 和 [`../../../engine/README_CN.md`](../../../engine/README_CN.md) §规划中的能力 §4。
