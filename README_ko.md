<p align="center">
  
</p>

<p align="center">
  <strong>LLM 토큰 소비를 60-90% 줄이는 고성능 CLI 프록시</strong>
</p>

<p align="center">
  <a href="https://github.com/ekjotsinghmakhija/prltc/actions"></a>
  <a href="https://github.com/ekjotsinghmakhija/prltc/releases"></a>
  <a href="https://opensource.org/licenses/MIT"></a>
  
  <a href="https://formulae.brew.sh/formula/prltc"></a>
</p>

<p align="center">
  <a href="https://www.github.com/ekjotsinghmakhija/prltc">웹사이트</a> &bull;
  <a href="#설치">설치</a> &bull;
  <a href="docs/TROUBLESHOOTING.md">문제 해결</a> &bull;
  <a href="ARCHITECTURE.md">아키텍처</a> &bull;
  
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

prltc는 명령 출력이 LLM 컨텍스트에 도달하기 전에 필터링하고 압축합니다. 단일 Rust 바이너리, 의존성 없음, 10ms 미만의 오버헤드.

## 토큰 절약 (30분 Claude Code 세션)

| 작업 | 빈도 | 표준 | prltc | 절약 |
|------|------|------|-----|------|
| `ls` / `tree` | 10x | 2,000 | 400 | -80% |
| `cat` / `read` | 20x | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8x | 16,000 | 3,200 | -80% |
| `git status` | 10x | 3,000 | 600 | -80% |
| `cargo test` / `npm test` | 5x | 25,000 | 2,500 | -90% |
| **합계** | | **~118,000** | **~23,900** | **-80%** |

## 설치

### Homebrew (권장)

```bash
brew install prltc
```

### 빠른 설치 (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

### Cargo

```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
```

### 확인

```bash
prltc --version   # "prltc 0.27.x" 표시되어야 함
prltc gain        # 토큰 절약 통계 표시되어야 함
```

## 빠른 시작

```bash
# 1. Claude Code용 hook 설치 (권장)
prltc init --global

# 2. Claude Code 재시작 후 테스트
git status  # 자동으로 prltc git status로 재작성
```

## 작동 원리

```
  prltc 없이:                                        prltc 사용:

  Claude  --git status-->  shell  -->  git          Claude  --git status-->  PRLTC  -->  git
    ^                                   |             ^                      |          |
    |        ~2,000 tokens (원본)        |             |   ~200 tokens        | 필터     |
    +-----------------------------------+             +------- (필터링) -----+----------+
```

네 가지 전략:

1. **스마트 필터링** - 노이즈 제거 (주석, 공백, 보일러플레이트)
2. **그룹화** - 유사 항목 집계 (디렉토리별 파일, 유형별 에러)
3. **잘라내기** - 관련 컨텍스트 유지, 중복 제거
4. **중복 제거** - 반복 로그 라인을 카운트와 함께 통합

## 명령어

### 파일
```bash
prltc ls .                        # 최적화된 디렉토리 트리
prltc read file.rs                # 스마트 파일 읽기
prltc find "*.rs" .               # 컴팩트한 검색 결과
prltc grep "pattern" .            # 파일별 그룹화 검색
```

### Git
```bash
prltc git status                  # 컴팩트 상태
prltc git log -n 10               # 한 줄 커밋
prltc git diff                    # 압축된 diff
prltc git push                    # -> "ok main"
```

### 테스트
```bash
prltc test cargo test             # 실패만 표시 (-90%)
prltc vitest run                  # Vitest 컴팩트
prltc pytest                      # Python 테스트 (-90%)
prltc go test                     # Go 테스트 (-90%)
```

### 빌드 & 린트
```bash
prltc lint                        # ESLint 규칙별 그룹화
prltc tsc                         # TypeScript 에러 그룹화
prltc cargo build                 # Cargo 빌드 (-80%)
prltc ruff check                  # Python 린트 (-80%)
```

### 분석
```bash
prltc gain                        # 절약 통계
prltc gain --graph                # ASCII 그래프 (30일)
prltc discover                    # 놓친 절약 기회 발견
```

## 문서

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - 일반적인 문제 해결
- **[INSTALL.md](INSTALL.md)** - 상세 설치 가이드
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 기술 아키텍처

## 기여

기여를 환영합니다! [GitHub](https://github.com/ekjotsinghmakhija/prltc)에서 issue 또는 PR을 생성해 주세요.

 커뮤니티에 참여하세요.

## 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.
