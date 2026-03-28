<p align="center">
  
</p>

<p align="center">
  <strong>LLM トークン消費を 60-90% 削減する高性能 CLI プロキシ</strong>
</p>

<p align="center">
  <a href="https://github.com/ekjotsinghmakhija/prltc/actions"></a>
  <a href="https://github.com/ekjotsinghmakhija/prltc/releases"></a>
  <a href="https://opensource.org/licenses/MIT"></a>
  
  <a href="https://formulae.brew.sh/formula/prltc"></a>
</p>

<p align="center">
  <a href="https://www.github.com/ekjotsinghmakhija/prltc">ウェブサイト</a> &bull;
  <a href="#インストール">インストール</a> &bull;
  <a href="docs/TROUBLESHOOTING.md">トラブルシューティング</a> &bull;
  <a href="ARCHITECTURE.md">アーキテクチャ</a> &bull;
  
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

prltc はコマンド出力を LLM コンテキストに届く前にフィルタリング・圧縮します。単一の Rust バイナリ、依存関係ゼロ、オーバーヘッド 10ms 未満。

## トークン節約（30分の Claude Code セッション）

| 操作 | 頻度 | 標準 | prltc | 節約 |
|------|------|------|-----|------|
| `ls` / `tree` | 10x | 2,000 | 400 | -80% |
| `cat` / `read` | 20x | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8x | 16,000 | 3,200 | -80% |
| `git status` | 10x | 3,000 | 600 | -80% |
| `cargo test` / `npm test` | 5x | 25,000 | 2,500 | -90% |
| **合計** | | **~118,000** | **~23,900** | **-80%** |

## インストール

### Homebrew（推奨）

```bash
brew install prltc
```

### クイックインストール（Linux/macOS）

```bash
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

### Cargo

```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
```

### 確認

```bash
prltc --version   # "prltc 0.27.x" と表示されるはず
prltc gain        # トークン節約統計が表示されるはず
```

## クイックスタート

```bash
# 1. Claude Code 用フックをインストール（推奨）
prltc init --global

# 2. Claude Code を再起動してテスト
git status  # 自動的に prltc git status に書き換え
```

## 仕組み

```
  prltc なし：                                       prltc あり：

  Claude  --git status-->  shell  -->  git          Claude  --git status-->  PRLTC  -->  git
    ^                                   |             ^                      |          |
    |        ~2,000 tokens（生出力）     |             |   ~200 tokens        | フィルタ |
    +-----------------------------------+             +------- （圧縮済）----+----------+
```

4つの戦略：

1. **スマートフィルタリング** - ノイズを除去（コメント、空白、ボイラープレート）
2. **グルーピング** - 類似項目を集約（ディレクトリ別ファイル、タイプ別エラー）
3. **トランケーション** - 関連コンテキストを保持、冗長性をカット
4. **重複排除** - 繰り返しログ行をカウント付きで統合

## コマンド

### ファイル
```bash
prltc ls .                        # 最適化されたディレクトリツリー
prltc read file.rs                # スマートファイル読み取り
prltc find "*.rs" .               # コンパクトな検索結果
prltc grep "pattern" .            # ファイル別グループ化検索
```

### Git
```bash
prltc git status                  # コンパクトなステータス
prltc git log -n 10               # 1行コミット
prltc git diff                    # 圧縮された diff
prltc git push                    # -> "ok main"
```

### テスト
```bash
prltc test cargo test             # 失敗のみ表示（-90%）
prltc vitest run                  # Vitest コンパクト
prltc pytest                      # Python テスト（-90%）
prltc go test                     # Go テスト（-90%）
```

### ビルド & リント
```bash
prltc lint                        # ESLint ルール別グループ化
prltc tsc                         # TypeScript エラーグループ化
prltc cargo build                 # Cargo ビルド（-80%）
prltc ruff check                  # Python リント（-80%）
```

### 分析
```bash
prltc gain                        # 節約統計
prltc gain --graph                # ASCII グラフ（30日間）
prltc discover                    # 見逃した節約機会を発見
```

## ドキュメント

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - よくある問題の解決
- **[INSTALL.md](INSTALL.md)** - 詳細インストールガイド
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 技術アーキテクチャ

## コントリビュート

コントリビューション歓迎！[GitHub](https://github.com/ekjotsinghmakhija/prltc) で issue または PR を作成してください。

 コミュニティに参加。

## ライセンス

MIT ライセンス - 詳細は [LICENSE](LICENSE) を参照。
