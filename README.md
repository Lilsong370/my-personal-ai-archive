# 我的 AI 个人档案 · My Personal AI Archive

> 把「我是谁、我怎么工作、我做过什么、我要往哪走」写成一份**任何 AI 都能直接读**的档案。
> 换模型、换电脑、换账号，只要一个链接，AI 就能立刻「认识你」，不用每次重新自我介绍。

**仓库**：https://github.com/Lilsong370/my-personal-ai-archive

> 第一次使用前，先把各模块里的 `<填写：...>` 换成你自己的内容。Actions 会每天提醒还剩几处没填。

---

## 30 秒上手

把这句话直接发给任何 AI（ChatGPT / Claude / Gemini / Cursor / 通义 / DeepSeek 都行）：

```text
请先读取这个文件，并把它作为我的个人背景档案：
https://cdn.jsdelivr.net/gh/Lilsong370/my-personal-ai-archive@main/ai-context-pack.md

读完不要复述全文。之后所有回答都基于这份档案，
并在回答开头用一行标注「档案已加载」。
```

> 用 jsDelivr 的 CDN 地址，不要用 `raw.githubusercontent.com`——国内经常读不到。
> 如果还是失败，见 [MIRRORS.md](MIRRORS.md) 里的备用地址，或直接把文件内容整段粘贴过去。

如果需要完整细节（而不只是精简包），把 `ai-context-pack.md` 换成 `README.md` 或具体模块文件。

---

## 目录结构

| 文件 | 内容 | 什么时候用 |
|---|---|---|
| `ai-context-pack.md` | **精简上下文包**（约 1 页，AI 首选） | 每次开新对话，先喂这个 |
| `profile.json` | 机器可读的结构化档案 | 需要程序化读取 / 接入自动化 |
| `01-basic-info.md` | 基础信息：姓名、职业、核心技能、联系方式 | AI 需要知道「你是谁」 |
| `02-work-style.md` | 工作风格与沟通偏好：回复速度、文档格式、沟通语气 | AI 输出「不像你」的时候 |
| `03-experience.md` | 过往经验与项目沉淀：关键项目、方法论、踩坑记录 | 让 AI 复用你的经验，而不是从零编 |
| `04-learning.md` | 持续学习与成长：学习计划、阅读清单、思考笔记 | 让 AI 帮你排学习节奏、做知识串联 |
| `05-custom-instructions.md` | 自定义指令：AI 协作规则、输出要求、避坑提醒 | 直接粘进各工具的 Custom Instructions |
| `AI-USAGE-GUIDE.md` | 各 AI 工具的具体调用方法 | 第一次配置时看 |
| `MIRRORS.md` | 国内可用的镜像地址（raw 域名被墙时用） | 链接读不到时看 |
| `journal/` | 和 AI 的对话记录，按月按天归档 | 想存下「聊出来的东西」时 |
| `sync/` | 回流脚本与方案（capture / sync / 导出导入） | 想把记录自动推回 GitHub 时 |
| `.github/workflows/` | 仓库自动化：结构校验、每日体检 | 不用管，配好就自动跑 |

---

## 设计原则

1. **分层**：`ai-context-pack.md` 是摘要，模块文件是全文。摘要给日常对话，全文给深度任务。
2. **可机读**：`profile.json` 提供结构化字段，方便脚本和其他 Agent 直接消费。
3. **只增不改**：历史模块用追加方式演进，保留「当时的判断」，方便日后复盘。
4. **单一事实源**：所有 AI 工具都从这里取信息，不再各存一份互相矛盾的「记忆」。
5. **脱敏**：公开仓库不放手机号、身份证、公司内部机密。联系方式只放可公开的渠道。

---

## 维护节奏

- 每周五 10 分钟：把本周 AI 对话里的有效结论写进 `journal/`，运行一次 `sync/sync.ps1`。
- 每月最后一天：把 journal 里的碎片提炼进对应模块，不必删除原料。
- 每季度：重读 `03-experience.md` 和 `04-learning.md`，删掉过期的野心，留下真正的教训。

---

## 许可证

内容为个人档案，采用 [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/deed.zh) 授权：可参考结构，不可商用转载本人信息。
