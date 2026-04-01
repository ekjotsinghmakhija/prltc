<p align="center">
  
</p>

<p align="center">
  <strong>高性能 CLI 代理，将 LLM token 消耗降低 60-90%</strong>
</p>

<p align="center">
  <a href="https://github.com/ekjotsinghmakhija/prltc/actions"></a>
  <a href="https://github.com/ekjotsinghmakhija/prltc/releases"></a>
  <a href="https://opensource.org/licenses/MIT"></a>
  
  <a href="https://formulae.brew.sh/formula/prltc"></a>
</p>

<p align="center">
  <a href="https://www.github.com/ekjotsinghmakhija/prltc">官网</a> &bull;
  <a href="#安装">安装</a> &bull;
  <a href="docs/TROUBLESHOOTING.md">故障排除</a> &bull;
  <a href="docs/contributing/ARCHITECTURE.md">架构</a> &bull;
  
</p>

<p align="center">
  <a href="README.md">English</a> &bull;
  <a href="README_fr.md">Francais</a> &bull;
  <a href="README_zh.md">中文</a> &bull;
  <a href="README_ja.md">日本語</a> &bull;
  <a href="README_ko.md">한국어</a> &bull;
  <a href="README_es.md">Espanol</a>
</p>

---

prltc 在命令输出到达 LLM 上下文之前进行过滤和压缩。单一 Rust 二进制文件，零依赖，<10ms 开销。

## Token 节省（30 分钟 Claude Code 会话）

| 操作 | 频率 | 标准 | prltc | 节省 |
|------|------|------|-----|------|
| `ls` / `tree` | 10x | 2,000 | 400 | -80% |
| `cat` / `read` | 20x | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8x | 16,000 | 3,200 | -80% |
| `git status` | 10x | 3,000 | 600 | -80% |
| `git diff` | 5x | 10,000 | 2,500 | -75% |
| `cargo test` / `npm test` | 5x | 25,000 | 2,500 | -90% |
| **总计** | | **~118,000** | **~23,900** | **-80%** |

## 安装

### Homebrew（推荐）

```bash
brew install prltc
```

### 快速安装（Linux/macOS）

```bash
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

### Cargo

```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
```

### 验证

```bash
prltc --version   # 应显示 "prltc 0.27.x"
prltc gain        # 应显示 token 节省统计
```

## 快速开始

```bash
# 1. 为 Claude Code 安装 hook（推荐）
prltc init --global

# 2. 重启 Claude Code，然后测试
git status  # 自动重写为 prltc git status
```

## 工作原理

```
  没有 prltc：                                      使用 prltc：

  Claude  --git status-->  shell  -->  git         Claude  --git status-->  PRLTC  -->  git
    ^                                   |            ^                      |          |
    |        ~2,000 tokens（原始）       |            |   ~200 tokens        | 过滤     |
    +-----------------------------------+            +------- （已过滤）-----+----------+
```

四种策略：

1. **智能过滤** - 去除噪音（注释、空白、样板代码）
2. **分组** - 聚合相似项（按目录分文件，按类型分错误）
3. **截断** - 保留相关上下文，删除冗余
4. **去重** - 合并重复日志行并计数

## 命令

### 文件
```bash
prltc ls .                        # 优化的目录树
prltc read file.rs                # 智能文件读取
prltc find "*.rs" .               # 紧凑的查找结果
prltc grep "pattern" .            # 按文件分组的搜索结果
```

### Git
```bash
prltc git status                  # 紧凑状态
prltc git log -n 10               # 单行提交
prltc git diff                    # 精简 diff
prltc git push                    # -> "ok main"
```

### 测试
```bash
prltc test cargo test             # 仅显示失败（-90%）
prltc vitest run                  # Vitest 紧凑输出
prltc pytest                      # Python 测试（-90%）
prltc go test                     # Go 测试（-90%）
```

### 构建 & 检查
```bash
prltc lint                        # ESLint 按规则分组
prltc tsc                         # TypeScript 错误分组
prltc cargo build                 # Cargo 构建（-80%）
prltc ruff check                  # Python lint（-80%）
```

### 容器
```bash
prltc docker ps                   # 紧凑容器列表
prltc docker logs <container>     # 去重日志
prltc kubectl pods                # 紧凑 Pod 列表
```

### 分析
```bash
prltc gain                        # 节省统计
prltc gain --graph                # ASCII 图表（30 天）
prltc discover                    # 发现遗漏的节省机会
```

## 文档

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - 解决常见问题
- **[INSTALL.md](INSTALL.md)** - 详细安装指南
- **[ARCHITECTURE.md](docs/contributing/ARCHITECTURE.md)** - 技术架构

## 贡献

欢迎贡献！请在 [GitHub](https://github.com/ekjotsinghmakhija/prltc) 上提交 issue 或 PR。

加入  社区。

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。

## 免责声明

详见 [DISCLAIMER.md](DISCLAIMER.md)。
