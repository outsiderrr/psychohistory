# 心理史学 · 角色卡生成工具包（总索引）

[English](./README.md) · **中文**

> 本工具包包含生成心理史学所有类型角色卡的标准提示词。
> 根据你要生成的角色类型，选择对应的提示词文件。

---

## 角色类型路由

```
你要生成什么？
│
├── 一个具体的人物？（特朗普、内塔尼亚胡、鲍威尔）
│   └── 👉 使用 prompt-01-personal-entity.md（调用女娲skill）
│
├── 一个组织/机构？（美联储、革命卫队、苹果公司、伊朗政府）
│   └── 👉 使用 prompt-02-org-entity.md
│
├── 一个群体？（MAGA选民、美股投资者、伊朗民众）
│   └── 👉 使用 prompt-03-collective.md
│
└── 角色之间的关系？（特朗普与万斯、伊朗政府与革命卫队）
    └── 👉 使用 prompt-04-relationship.md
```

---

## 文件清单

| 文件 | 用途 | 输出格式 |
|------|------|---------|
| `prompt-01-personal-entity.md` | 个人实体角色卡（调用女娲skill） | `[agent_id].json` |
| `prompt-02-org-entity.md` | 组织实体角色卡（政府/公司/军事组织） | `[agent_id].json` |
| `prompt-03-collective.md` | 群体角色画像 | `[agent_id].json` |
| `prompt-04-relationship.md` | 角色间关系定义 | `[rel_id].json` |

---

## CLI-first 设计

本工具包**默认在 CLI 环境**下运行，且**在 CLI agent 之间可移植**（Claude Code / Cline / Aider / goose / continue.dev / OpenClaw / Manus 等）。所有 phase-based prompt 和 `SKILL.md` 都假设以下能力可用：

- 文件系统读写
- `git rev-parse --show-toplevel` 用于自动定位项目根目录
- `python3` + `jsonschema` 用于自动 schema 校验（首次使用前：`python3 -m venv .venv && source .venv/bin/activate && pip install jsonschema`；macOS 3.12+ 遇到 PEP 668 可用 `pip install --break-system-packages jsonschema`；详见 `SKILL.md` §Step 4）
- **用户有一个带搜索能力的对话 AI**（Perplexity / ChatGPT with Search / Gemini Deep Research / Claude.ai / Kimi / 豆包 / 元宝 等）—— 用于研究阶段的 **Research Hand-off** 协议

### Research Hand-off（替代 WebFetch）

本工具包**有意不依赖** Claude Code 的 `WebFetch` 或其他 CLI-agent 专有的 web 抓取工具。研究阶段通过复制粘贴协议委托给用户的对话 AI：

1. `SKILL.md` 识别到某个 Phase 需要外部研究
2. 从对应 `prompt-0X` 文件的 `## Appendix: Research Hand-off Template` 生成参数化的研究提示词
3. 用户复制提示词到偏好的带搜索能力的对话 AI
4. 对话 AI 执行研究，返回结构化结果
5. 用户把结果粘回 CLI，工具包将其整合到 `references.md`

这让本工具包在 CLI agent 之间可移植——任何能读写文件、能跑 Python 的 CLI agent 都能用——同时产出的研究质量**高于单 URL 抓取**，因为带搜索能力的对话 AI 会做多步骤研究、交叉验证、引用追踪。

### 对话 AI 作为逃逸通道（Export 模式）

如果你想**整张卡**都在对话 AI 里生成（不用 CLI），在 CLI 里调用 `SKILL.md` 的 **Export 模式**。它会输出一段适配过的自包含提示词，你复制到 ChatGPT / Claude.ai / Trae / Gemini 等里执行。完成后把 references.md + JSON 内容带回 CLI 做校验和落盘。

### 通过 wrapper 脚本自动化研究（已可用）

`research-wrappers/` 子目录提供了一组参考 Bash 脚本，通过直接调用有搜索能力的 LLM API 来自动化 Research Hand-off 的复制粘贴步骤。用户把 `PSYCHOHISTORY_RESEARCH_TOOL` 环境变量设置为 wrapper 脚本的路径，`SKILL.md` Step 3.1.0 就会自动把研究提示词通过 wrapper 路由——**完全跳过手动复制粘贴**。

支持的 wrapper（参考模板）：

- **Perplexity** (`perplexity.sh`) —— 专用研究型 LLM，推荐默认
- **Anthropic Claude** (`anthropic.sh`) —— 用 Claude + `web_search` 工具
- **OpenAI** (`openai.sh`) —— 用 `gpt-4o-search-preview`
- **Google Gemini** (`gemini.sh`) —— 用 Gemini 2.5 Pro + `google_search` grounding

**主要为自带 API 密钥的 CLI agent 用户准备**（OpenClaw / Cline / Aider / goose / continue.dev 等）—— 这类用户正常使用 CLI agent 就需要在环境变量里配 API 密钥。Claude Code 用户也能用，只需要独立配一个专门用于研究步骤的 API 密钥即可。

如果 wrapper 执行失败（非零退出码、空输出、超时），skill 会降级到标准 Research Hand-off。不配置 `PSYCHOHISTORY_RESEARCH_TOOL` 的用户继续用 Research Hand-off，工作流不变。

详见 [`research-wrappers/README_CN.md`](./research-wrappers/README_CN.md)——配置步骤、wrapper 契约、成本估算、验证指南。**所有 wrapper 脚本都是基于 2025-05 API 形态写的参考模板——真实使用前请先对照当前服务商文档验证。**

### 可选增强：MCP 集成（当前未开发）

如果你的 CLI agent 支持 **MCP（Model Context Protocol）** 且配置了搜索类 MCP server（如 Perplexity MCP / Brave Search MCP），Research Hand-off 的复制粘贴步骤理论上可以被 MCP 工具调用替代——skill 直接调用 MCP 工具、收到研究结果，跳过用户的手动粘贴。

**这个功能当前未实现。** 如果 MCP 搜索服务器变得广泛可用和标准化，未来可能加进来。当前 skill 阶段 Research Hand-off 复制粘贴是唯一的研究路径。

### 未来：engine 阶段的 API 集成（当前未开发）

在未来的 `engine/` 模块（见 [`../../engine/README_CN.md`](../../engine/README_CN.md)），Research Hand-off 的复制粘贴流程可以被**直接 API 调用**替代——engine 可以调用 Perplexity API / OpenAI Search API / Gemini API 等带搜索能力的 LLM API。用户一次性配好 API 密钥，engine 自动路由研究请求。Research Hand-off 仍会作为 fallback 保留，服务于：不想配 API 密钥的用户、需要 chat UI 特有功能的用户、API 错误时的降级。

**这是 engine 阶段的功能，不是 skill 阶段的。** 它不会加进 skill——这正是 engine 模块存在的目的。

---

## 通用规则

以下规则适用于所有类型的角色卡：

1. **所有JSON必须通过标准解析器验证** — 不允许有语法错误
2. **所有文本内容使用英文** — name、description等字段一律英文
3. **日期格式一律 YYYY-MM-DD** — 不接受不完整日期
4. **agent_id 一律小写字母+连字符** — 如 `us-federal-reserve`、`maga-base`
5. **每张卡必须有 honesty_boundaries** — 明确说明这张卡做不到什么

---

## 方法论原则（v1.1）

以下 5 条原则贯穿所有 **phase-based prompts**（prompt-02 / 03 / 04），是整个角色卡生成方法论的基础。prompt-01（个人实体）因为依赖 Nuwa 的多阶段蒸馏管线，继承了其中的原则 1、3、4、5；原则 2 同样适用。

1. **两阶段最少** — 研究阶段先行、结构化阶段在后。绝不允许从空白直接跳 JSON
2. **references.md 是主产物** — JSON 是它的压缩索引。先写笔记 → 按它编译 JSON → 验证每个 JSON 字段都能指回 references.md 中的具体证据
3. **证据强度分级** — 每条结论标注 `strength: high / medium / low`。`high` 要有多案例支撑，`low` 可用但必须显式标明
4. **显式认知边界** — `honesty_boundaries` 必须包含类型专属声明：
   - 组织：派系分化声明
   - 群体：内部异质性声明
   - 关系：场景绑定声明
5. **历史先例优先** — 有历史案例支撑的推理排在纯理论推理前面；无先例的推论标 `strength: low`

这 5 条是**硬性要求**，不是建议。任何 phase-based prompt 执行后产出的 JSON 如果违反其中任何一条，必须回到对应 Phase 补充证据或修正分级。

---

## 保存路径

| 类型 | 路径 |
|------|------|
| 女娲原始数据 | `characters/nuwa/[agent_id].md` |
| 个人实体JSON | `characters/psychohistory/[agent_id].json` |
| 组织实体JSON | `characters/psychohistory/[agent_id].json` |
| 群体角色JSON | `characters/psychohistory/[agent_id].json` |
| 关系定义JSON | `characters/relationships/[rel_id].json` |
| 索引文件（论证过程） | 与对应JSON同目录，后缀为 `.references.md` |

每张角色卡和每份关系定义都必须同时生成一份索引文件（`.references.md`），记录每个结论的证据链条。索引文件是给需要验证或修改结论的用户看的，不影响引擎运行。

---

## 快速判断：这个角色是实体还是群体？

问自己一个问题：**这个角色有没有一个"最终拍板人"？**

- 有 → 实体（entity）。即使组织很大，只要有一个人或一个小班子能拍板，就是实体。
- 没有 → 群体（collective）。没有人能代表整体做出决定，行为是统计性的涌现结果。

**灰色地带怎么办？**

有些角色介于两者之间，比如"伊朗最高安全委员会"——它有集体决策机制但没有单一独裁者。这种情况下建议按**组织实体**建模，但在卡片中特别标注内部决策机制的特殊性。
