# 使用指南 · 在各类 AI 工具中调用这份档案

> 核心思路只有一条：**档案放在公网可读的固定链接上，任何 AI 只要能读网页，就能「认识你」。**
> 读不了网页的工具，就用「粘贴一次 + 长期保存」的方式落地。

## 先拿到你的 raw 链接

仓库建好后，两个链接是关键：

```text
# 精简版（日常对话用，约 1 屏）
https://raw.githubusercontent.com/<用户名>/my-personal-ai-archive/main/ai-context-pack.md

# 完整指令版（配置自定义指令用）
https://raw.githubusercontent.com/<用户名>/my-personal-ai-archive/main/05-custom-instructions.md
```

> `raw.githubusercontent.com` 是纯文本，AI 抓取最稳。
> 浏览器打开如果是下载而不是显示，说明链接对；复制地址栏那条即可。

---

## 1. ChatGPT

**方式 A：Projects（推荐，长期有效）**
1. 左侧栏 → Projects → 新建项目，命名「我」。
2. 项目设置里「添加文件」→ 上传 `ai-context-pack.md`、`02-work-style.md`、`05-custom-instructions.md`。
3. 项目自定义指令里贴 `05-custom-instructions.md` 的「通用版」。
4. 以后所有跟自己的对话都在这个项目里开，不用再自我介绍。

**方式 B：全局自定义指令**
设置 → 个性化 → 自定义指令，「关于我」贴基础信息+风格，「如何回应」贴通用版规则。

**方式 C：临时对话**
直接发：「读一下这个链接再回答：<raw 链接>」

## 2. Claude

**Projects** 是最佳载体：
1. Claude → Projects → New Project。
2. 「Project knowledge」上传：`ai-context-pack.md`、`03-experience.md`、`05-custom-instructions.md`。
3. 「Set project instructions」贴「通用版」。
4. 每个长期主题建一个项目（写作、代码、学习），共用同一套 knowledge。

**Claude Code / API**：把 `05-custom-instructions.md` 的内容作为 `system` 参数，或放进项目根目录 `CLAUDE.md`。

## 3. Gemini

**Gems（自定义角色）**：
1. Gemini → Gems → 新建 Gem，命名「我的助理」。
2. 指令框贴「通用版」，并在末尾加一句：`如可联网，请先读取 <raw 链接>`。
3. 保存后，所有对话选这个 Gem。

**NotebookLM**：新建笔记本，把整份档案作为来源导入，可做「基于我的档案提问」。

## 4. DeepSeek / 通义 / Kimi / 豆包

这类工具多数没有长期自定义指令，做法是：
1. 把「通用版」存成手机备忘录 / 输入法快捷短语。
2. 每次开新对话第一条粘贴，或者把 `ai-context-pack.md` 直接拖进对话框当附件（支持文件上传的都优先用附件）。
3. Kimi / 豆包支持长文本，直接传全文模块文件效果更好。

## 5. Cursor / Windsurf / VS Code AI

在项目根目录建规则文件，AI 会自动加载：

```text
.cursor/rules/profile.mdc        # Cursor
.windsurf/rules/profile.md       # Windsurf
.github/copilot-instructions.md  # GitHub Copilot
CLAUDE.md                        # Claude Code
AGENTS.md                        # 通用 Agent 约定
```

内容直接复制 `05-custom-instructions.md` 的「通用版 + 技术任务加强版」。

## 6. API / 自建 Agent

```python
import requests

PROFILE_URL = "https://raw.githubusercontent.com/<用户名>/my-personal-ai-archive/main/ai-context-pack.md"
profile = requests.get(PROFILE_URL, timeout=10).text

messages = [
    {"role": "system", "content": f"以下是用户档案，请始终遵循：\n\n{profile}"},
    {"role": "user", "content": "帮我把这周的会议纪要整理成周报"},
]
```

要点：
1. 启动时拉一次，缓存在内存，别每次请求都抓。
2. 加 10 秒超时 + 失败降级（用本地缓存副本）。
3. 结构化场景优先读 `profile.json`，自然语言场景读 `ai-context-pack.md`。

## 7. 手机端 / 语音助手

- **iOS 快捷指令**：做一个「喂档案」动作，把 raw 链接内容复制到剪贴板，打开任意 AI App 时自动粘贴。
- **Android**：用 Tasker / 剪贴板工具做同样的自动化。
- **微信 / 飞书机器人**：把 `ai-context-pack.md` 作为机器人的系统提示词前缀。

---

## 日常使用节奏

```text
开新对话  → 贴一句「读取 <raw 链接>」+ 你的具体任务
          → AI 回复质量明显更「像给你量身定做的」

做完任务  → 把有效结论丢进 sync/inbox/YYYY-MM-DD.md
          → 运行 sync/sync.ps1 提交推送

每周五    → 花 10 分钟把 inbox 提炼进 02/03/04 模块
```

## 常见问题

**Q：AI 说读不了链接怎么办？**
直接把 `ai-context-pack.md` 的内容整段粘进对话。或者改用支持文件上传的方式（附件优先级高于链接）。

**Q：档案太长会不会占满上下文？**
所以分了层。日常只用 `ai-context-pack.md`（约 600 字），深度任务才加载 `03-experience.md` 等全文。

**Q：公开仓库安全吗？**
只要遵守「联系方式只放公开渠道 + 不写公司内部信息」就没问题。真要放敏感内容，另建一个 private 仓库，用同样的结构，只是不能给外部 AI 读链接。

**Q：更新档案后，旧的对话会同步吗？**
不会。旧对话保留的是旧上下文。新开对话才会读到新版本——这也是「开新对话先说一句读链接」的原因。

**Q：多个 AI 各自记的东西不一样怎么办？**
这正是这个仓库存在的意义：仓库是唯一事实源。任何 AI 生成的、值得留下的内容，都回流到 `sync/inbox/`，再由你决定是否并入正式模块。
