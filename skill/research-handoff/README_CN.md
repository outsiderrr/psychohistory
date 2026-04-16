# Research Hand-off（研究代理协议）

[English](./README.md) · **中文**

> 可移植的外部研究委托协议——把研究任务交给用户偏好的带搜索能力的对话 AI 执行。独立的原子 skill——可以单独安装使用，也可以被更大的 skill 组合调用。

## 做什么

当一个 AI skill 需要超出训练知识的最新信息时，本 skill：

1. 生成结构化的研究提示词（从调用方 skill 提供的模板）
2. 可选：通过 wrapper 脚本走 API 全自动执行
3. 无 wrapper 时：输出提示词让用户复制粘贴到偏好的对话 AI
4. 校验返回内容（粘贴合法性检查 + 格式容错）
5. 把结构化的研究结果返回给调用方 skill

## 安装

本 skill 在 Psychohistory monorepo 的 `skill/research-handoff/` 目录下。单独使用时，把整个目录复制到你的项目 skill 目录即可。

*社区有需求时会发布为独立 repo，支持 `npx skills add`。*

## 核心特性

- **跨 CLI agent 可移植**：Claude Code / Cline / Aider / goose / OpenClaw 等都能用
- **不依赖 WebFetch**：研究在用户的对话 AI 里执行，不走 agent 专属工具
- **Wrapper 自动化**：可选，通过 `PSYCHOHISTORY_RESEARCH_TOOL` 环境变量配置
- **粘贴合法性检查**：捕获 Gemini Canvas / ChatGPT Canvas / Claude Artifacts 的占位符问题
- **批量模式**：多个研究请求合并成一次复制粘贴
- **多语言支持**：`output_language` 参数控制返回语言；§N 编号保持英文确保结构识别
- **格式容错**：严格识别章节，宽松处理子结构

## 被谁使用

- `character-toolkit` —— 角色卡生成的研究阶段
- `news-interpreter` —— 新闻解读的上下文收集和交叉验证（规划中）
- `theory-test` —— 理论检验的交叉验证证据收集（规划中）
- 任何需要外部研究的自定义 skill

## 参考 wrapper 脚本

`wrappers/` 下有 Perplexity / Anthropic Claude / OpenAI / Gemini 的预置脚本。详见 `wrappers/README.md`。
