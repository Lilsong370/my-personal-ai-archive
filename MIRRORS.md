# 镜像地址（中国大陆可用）

`raw.githubusercontent.com` 在国内经常被污染，AI 抓不到。下面这些是实测可用的替代地址，任选一个。

## 主推荐：jsDelivr CDN

```text
https://cdn.jsdelivr.net/gh/Lilsong370/my-personal-ai-archive@main/ai-context-pack.md
https://cdn.jsdelivr.net/gh/Lilsong370/my-personal-ai-archive@main/05-custom-instructions.md
```

特点：全球 CDN，国内直连可用，响应快，返回纯文本。

注意：jsDelivr 有缓存，仓库更新后最长 12 小时才刷新。要立刻生效，打开一次：

```text
https://purge.jsdelivr.net/gh/Lilsong370/my-personal-ai-archive@main/ai-context-pack.md
```

或者用带版本号的地址（`@main` 换成 commit sha）绕过缓存。

## 备用一：gh-proxy

```text
https://gh-proxy.com/https://raw.githubusercontent.com/Lilsong370/my-personal-ai-archive/main/ai-context-pack.md
```

特点：实时转发，无缓存延迟，适合「刚改完就要用」。

## 备用二：ghproxy.net

```text
https://ghproxy.net/https://raw.githubusercontent.com/Lilsong370/my-personal-ai-archive/main/ai-context-pack.md
```

特点：同上，速度稍慢，作为兜底。

## 备用三：GitHub 网页版

```text
https://github.com/Lilsong370/my-personal-ai-archive/blob/main/ai-context-pack.md
```

特点：`github.com` 主站国内一般可访问，只有 `raw.` 子域被墙。部分 AI 能读网页版 HTML。

## 都不行的时候

直接把文件内容整段粘贴给 AI。这正是 `ai-context-pack.md` 控制在 1 屏以内的原因——它本来就是为「粘贴」设计的。

---

_实测时间：2026-10-26 · 测试环境：中国大陆家宽_
