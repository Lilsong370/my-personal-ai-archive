# 自动同步方案

> 先说清一件事：**没有任何 AI 会主动往你的 GitHub 仓库里写东西。**
> ChatGPT、Claude、Gemini 都没有「同步到 GitHub」的开关。所谓自动同步，指的是：**你复制一下，剩下的交给脚本。**

内容只有一个去处：`journal/YYYY-MM/YYYY-MM-DD.md`。

---

## 方案 A：一条命令回流（推荐，已经装好）

原理：你把 AI 的输出丢进去，脚本负责写文件、commit、push。

```powershell
cd C:\Users\<你>\my-personal-ai-archive

# 方式一：读剪贴板（最快，复制完直接跑）
.\sync\capture.ps1 -Tag chatgpt -Title "客诉话术"

# 方式二：命令行直接给内容
.\sync\capture.ps1 -Text "AI 的输出" -Tag claude -Title "周报模板"

# 方式三：Python 版，功能一样，支持从文件读
python sync\archive-chat.py --file note.md --tag gemini --title "外语句型"
```

跑完就自动提交推送，GitHub 上立刻能看到。

### 装一次，之后更省事

- 桌面快捷方式，目标：
  `powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\my-personal-ai-archive\sync\capture.ps1"`
- 或者把 `sync` 目录加进 PATH，任何地方敲 `capture` 就能用。

---

## 方案 B：定时批量同步（无人值守）

适合「我先丢一堆，晚上统一推」。

### Windows 任务计划程序

1. 打开「任务计划程序」→ 创建基本任务。
2. 触发器：每天 22:00 + 登录时。
3. 操作：启动程序
   - 程序：`powershell.exe`
   - 参数：`-NoProfile -ExecutionPolicy Bypass -File "C:\Users\<你>\my-personal-ai-archive\sync\sync.ps1" -Message "auto sync"`
   - 起始于：`C:\Users\<你>\my-personal-ai-archive`
4. 取消勾选「仅在交流电源时运行」。

脚本自带「无变更就跳过」，不会产生空提交。

---

## 方案 C：整段导出，一次性归档

ChatGPT 和 Claude 都能导出全部对话，导进来就是完整的历史记录。

### ChatGPT

1. 设置 → 数据控制 → 导出数据 → 确认。
2. 几分钟后邮箱收到下载链接，解压得到 `conversations.json`。
3. 归档：

```powershell
python sync\archive-chat.py --export conversations.json --tag chatgpt --sync
```

脚本会自动按对话日期拆到你对应的 `journal/2026-10/` 里，system 消息和空消息会被跳过。

### Claude

1. 设置 → 隐私 → 导出数据。
2. 拿到 JSON 后同样一条命令，`--tag claude`。

> 注意：导出文件可能很大（几十 MB）。第一次建议先不加 `--sync`，看一眼生成的文件再推。

---

## 方案 D：全自动（任何工具 → GitHub）

只要那个工具能发 HTTP 请求（Zapier、n8n、飞书机器人、iOS 快捷指令、自己写的脚本），就能直接写进仓库：

```bash
curl -X POST https://api.github.com/repos/Lilsong370/my-personal-ai-archive/dispatches \
  -H "Authorization: Bearer <PAT>" \
  -H "Accept: application/vnd.github+json" \
  -d '{"event_type":"capture","client_payload":{"text":"要存的内容","tag":"claude","title":"主题"}}'
```

仓库里的 `.github/workflows/capture.yml` 会接住，写进当天的 journal 文件并提交。

配置成本：需要一个 Fine-grained PAT（只给 Contents: Read and write + Actions: write）。

---

## 四种方案怎么选

| 你的情况 | 用哪个 |
|---|---|
| 偶尔存一次，电脑前 | A，复制完跑一条命令 |
| 每天都用，懒得点 | B，晚上自动推 |
| 想把历史对话一次搬进来 | C，导出 JSON 批量导入 |
| 手机上用，或者接自动化 | D，webhook |

---

## Token 怎么建（只给方案 D 需要）

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens。
2. Repository access 只选这一个仓库。
3. Permissions 只给 Contents: Read and write；要用 dispatch 再加 Actions: write。
4. 有效期 90 天，到期换新。
5. **不要把 token 写进仓库任何文件。** 本地用 Git Credential Manager 存，CI 用 GitHub Secrets。

## 冲突与回滚

- 脚本用 `git pull --rebase --autostash`，多设备同时改不会炸。
- 真冲突：`git status` 看冲突文件 → 手动合并 → `git rebase --continue`。
- 误提交敏感信息：`git rm --cached <文件>` 提交后，**当作已泄露去换凭据**。历史记录仍能翻到，必要时 `git filter-repo` 重写。
