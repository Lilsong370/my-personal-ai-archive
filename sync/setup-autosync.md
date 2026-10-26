# 自动同步方案

> 先说清一件事：**ChatGPT / Claude / Gemini 没有「直接写入你的 GitHub」的开关。**
> 所谓「自动同步」，在这套方案里指的是：把你从任何 AI 得到的内容，用一条命令（或一个快捷指令）沉到仓库里，不需要手动整理文件。

这里有三个层级的方案，按投入从低到高。

---

## 方案 A：一条命令回流（推荐，5 分钟装好）

原理：内容先进 `sync/inbox/`，脚本负责 commit + push。你只管「产出 → 丢进来 → 跑一下」。

### 安装

1. 装 Git for Windows：<https://git-scm.com/download/win>（或 `winget install Git.Git`）
2. 克隆仓库到本地：

```powershell
git clone https://github.com/Lilsong370/my-personal-ai-archive.git $env:USERPROFILE\my-personal-ai-archive
cd $env:USERPROFILE\my-personal-ai-archive
```

3. 确认能免密推送（第一次 push 会弹出浏览器授权，点一次就好）：

```powershell
git config --global credential.helper manager
git push
```

### 日常两条命令

```powershell
# 把一段 AI 输出追加到今天的收件箱，并自动提交推送
.\sync\capture.ps1 -Text "（粘贴 AI 的内容）" -Tag "chatgpt"

# 或者先把文件丢进 sync\inbox\，再整体同步
.\sync\sync.ps1 -Message "补充：本周复盘"
```

### 让它更省事

- 在桌面建一个快捷方式，目标写：
  `powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\my-personal-ai-archive\sync\sync.ps1"`
- 或者加进 PATH，之后任何目录敲 `sync-archive` 就能同步。

---

## 方案 B：定时自动同步（Windows 任务计划程序）

适用：你经常把内容丢进 `inbox`，但懒得手动跑脚本。

1. 打开「任务计划程序」→ 创建基本任务。
2. 触发器：每天 22:00，以及登录时。
3. 操作：启动程序
   - 程序：`powershell.exe`
   - 参数：`-NoProfile -ExecutionPolicy Bypass -File "C:\Users\<你>\my-personal-ai-archive\sync\sync.ps1" -Message "auto sync"`
   - 起始于：`C:\Users\<你>\my-personal-ai-archive`
4. 条件里勾上「仅在使用交流电源时」取消掉，避免笔记本电池下不跑。

脚本本身带「无变更就跳过」判断，不会产生空提交。

---

## 方案 C：手机 / 其他工具直接把内容写进仓库

场景：你在手机上用 ChatGPT 生成了一段东西，想直接存进档案。

### C1. iOS 快捷指令（无需电脑）

1. 新建快捷指令，加三个动作：
   - 「获取剪贴板」
   - 「获取 URL 内容」，方法 POST
     - URL：`https://api.github.com/repos/Lilsong370/my-personal-ai-archive/contents/sync/inbox/quick-capture.md`
     - 请求头：`Authorization: Bearer <你的 fine-grained PAT>`、`Accept: application/vnd.github+json`
     - 请求体 JSON：`{"message":"capture from iOS","content":"<base64 编码的剪贴板>"}`
   - 「显示结果」
2. 注意：GitHub Contents API 是**覆盖**写入，需要先 GET 拿 `sha` 再 PUT。所以更稳的做法是用 GitHub Actions（见 C2）或把快捷指令改成「先 GET 拼内容 → 再 PUT」。
3. 更简单的替代：用 GitHub 手机 App / 网页版直接编辑 `sync/inbox/quick-capture.md`，两下就能存。

### C2. 任意工具 → Webhook → GitHub Actions（全自动）

在仓库 Settings → Secrets 里配一个 `SYNC_WEBHOOK_TOKEN`，然后用任何支持 webhook 的工具（Zapier、n8n、飞书机器人、iOS 快捷指令）向 `repository_dispatch` 发事件：

```bash
curl -X POST https://api.github.com/repos/Lilsong370/my-personal-ai-archive/dispatches \
  -H "Authorization: Bearer <PAT>" \
  -H "Accept: application/vnd.github+json" \
  -d '{"event_type":"capture","client_payload":{"text":"要存的内容","tag":"claude"}}'
```

配合 `.github/workflows/capture.yml`（本仓库已提供），内容会自动落到 `sync/inbox/YYYY-MM-DD.md` 并提交。

> 这条链路的价值：**任何能发 HTTP 请求的工具，都能往你的档案里写东西**，不需要它原生支持 GitHub。

---

## Token 怎么建（安全做法）

1. GitHub → Settings → Developer settings → Personal access tokens → **Fine-grained tokens**。
2. Repository access 只选这一个仓库。
3. Permissions 只给 **Contents: Read and write**（需要 dispatch 再加 **Actions: write**）。
4. 有效期设 90 天，到期换新。
5. **不要把 token 写进仓库里的任何文件。** 本地用 `git credential manager` 存，CI 用 GitHub Secrets。

---

## 冲突与回滚

- 脚本用 `git pull --rebase --autostash`，多设备同时改不会炸。
- 真冲突了：`git status` 看冲突文件 → 手动合并 → `git rebase --continue`。
- 误提交了敏感信息：立刻 `git rm --cached <文件>` + 提交，然后**当作已经泄露**去换对应凭据。历史记录里仍能翻到，必要时用 `git filter-repo` 重写。
