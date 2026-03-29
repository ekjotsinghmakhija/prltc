# PRLTC - Documentation fonctionnelle complete

> **prltc (Rust Token Killer)** -- Proxy CLI haute performance qui reduit la consommation de tokens LLM de 60 a 90%.

Binaire Rust unique, zero dependances externes, overhead < 10ms par commande.

---

## Table des matieres

1. [Vue d'ensemble](#vue-densemble)
2. [Drapeaux globaux](#drapeaux-globaux)
3. [Commandes Fichiers](#commandes-fichiers)
4. [Commandes Git](#commandes-git)
5. [Commandes GitHub CLI](#commandes-github-cli)
6. [Commandes Test](#commandes-test)
7. [Commandes Build et Lint](#commandes-build-et-lint)
8. [Commandes Formatage](#commandes-formatage)
9. [Gestionnaires de paquets](#gestionnaires-de-paquets)
10. [Conteneurs et orchestration](#conteneurs-et-orchestration)
11. [Donnees et reseau](#donnees-et-reseau)
12. [Cloud et bases de donnees](#cloud-et-bases-de-donnees)
13. [Stacked PRs (Graphite)](#stacked-prs-graphite)
14. [Analytique et suivi](#analytique-et-suivi)
15. [Systeme de hooks](#systeme-de-hooks)
16. [Configuration](#configuration)
17. [Systeme Tee (recuperation de sortie)](#systeme-tee)
18. [Telemetrie](#telemetrie)

---

## Vue d'ensemble

prltc agit comme un proxy entre un LLM (Claude Code, Gemini CLI, etc.) et les commandes systeme. Quatre strategies de filtrage sont appliquees selon le type de commande :

| Strategie | Description | Exemple |
|-----------|-------------|---------|
| **Filtrage intelligent** | Supprime le bruit (commentaires, espaces, boilerplate) | `ls -la` -> arbre compact |
| **Regroupement** | Agregation par repertoire, par type d'erreur, par regle | Tests groupes par fichier |
| **Troncature** | Conserve le contexte pertinent, supprime la redondance | Diff condense |
| **Deduplication** | Fusionne les lignes de log repetees avec compteurs | `error x42` |

### Mecanisme de fallback

Si prltc ne reconnait pas une sous-commande, il execute la commande brute (passthrough) et enregistre l'evenement dans la base de suivi. Cela garantit que prltc est **toujours sur** a utiliser -- aucune commande ne sera bloquee.

---

## Drapeaux globaux

Ces drapeaux s'appliquent a **toutes** les sous-commandes :

| Drapeau | Court | Description |
|---------|-------|-------------|
| `--verbose` | `-v` | Augmenter la verbosite (-v, -vv, -vvv). Montre les details de filtrage. |
| `--ultra-compact` | `-u` | Mode ultra-compact : icones ASCII, format inline. Economies supplementaires. |
| `--skip-env` | -- | Definit `SKIP_ENV_VALIDATION=1` pour les processus enfants (Next.js, tsc, lint, prisma). |

**Exemples :**

```bash
prltc -v git status          # Status compact + details de filtrage sur stderr
prltc -vvv cargo test        # Verbosite maximale (debug)
prltc -u git log             # Log ultra-compact, icones ASCII
prltc --skip-env next build  # Desactive la validation d'env de Next.js
```

---

## Commandes Fichiers

### `prltc ls` -- Listage de repertoire

**Objectif :** Remplace `ls` et `tree` avec une sortie optimisee en tokens.

**Syntaxe :**
```bash
prltc ls [args...]
```

Tous les drapeaux natifs de `ls` sont supportes (`-l`, `-a`, `-h`, `-R`, etc.).

**Economies :** ~80% de reduction de tokens

**Avant / Apres :**
```
# ls -la (45 lignes, ~800 tokens)          # prltc ls (12 lignes, ~150 tokens)
drwxr-xr-x  15 user staff 480 ...          my-project/
-rw-r--r--   1 user staff 1234 ...          +-- src/ (8 files)
-rw-r--r--   1 user staff 567 ...           |   +-- main.rs
...40 lignes de plus...                     +-- Cargo.toml
                                            +-- README.md
```

---

### `prltc tree` -- Arbre de repertoire

**Objectif :** Proxy vers `tree` natif avec sortie filtree.

**Syntaxe :**
```bash
prltc tree [args...]
```

Supporte tous les drapeaux natifs de `tree` (`-L`, `-d`, `-a`, etc.).

**Economies :** ~80%

---

### `prltc read` -- Lecture de fichier

**Objectif :** Remplace `cat`, `head`, `tail` avec un filtrage intelligent du contenu.

**Syntaxe :**
```bash
prltc read <fichier> [options]
prltc read - [options]          # Lecture depuis stdin
```

**Options :**

| Option | Court | Defaut | Description |
|--------|-------|--------|-------------|
| `--level` | `-l` | `minimal` | Niveau de filtrage : `none`, `minimal`, `aggressive` |
| `--max-lines` | `-m` | illimite | Nombre maximum de lignes |
| `--line-numbers` | `-n` | non | Afficher les numeros de ligne |

**Niveaux de filtrage :**

| Niveau | Description | Economies |
|--------|-------------|-----------|
| `none` | Aucun filtrage, sortie brute | 0% |
| `minimal` | Supprime commentaires et lignes vides excessives | ~30% |
| `aggressive` | Signatures uniquement (supprime les corps de fonctions) | ~74% |

**Avant / Apres (mode aggressive) :**
```
# cat main.rs (~200 lignes)                # prltc read main.rs -l aggressive (~50 lignes)
fn main() -> Result<()> {                   fn main() -> Result<()> { ... }
    let config = Config::load()?;           fn process_data(input: &str) -> Vec<u8> { ... }
    let data = process_data(&input);        struct Config { ... }
    for item in data {                      impl Config { fn load() -> Result<Self> { ... } }
        println!("{}", item);
    }
    Ok(())
}
...
```

**Langages supportes pour le filtrage :** Rust, Python, JavaScript, TypeScript, Go, C, C++, Java, Ruby, Shell.

---

### `prltc smart` -- Resume heuristique

**Objectif :** Genere un resume technique de 2 lignes pour un fichier source.

**Syntaxe :**
```bash
prltc smart <fichier> [--model heuristic] [--force-download]
```

**Economies :** ~95%

**Exemple :**
```
$ prltc smart src/tracking.rs
SQLite-based token tracking system for command executions.
Records input/output tokens, savings %, execution times with 90-day retention.
```

---

### `prltc find` -- Recherche de fichiers

**Objectif :** Remplace `find` et `fd` avec une sortie compacte groupee par repertoire.

**Syntaxe :**
```bash
prltc find [args...]
```

Supporte a la fois la syntaxe PRLTC et la syntaxe native `find` (`-name`, `-type`, etc.).

**Economies :** ~80%

**Avant / Apres :**
```
# find . -name "*.rs" (30 lignes)           # prltc find "*.rs" . (8 lignes)
./src/main.rs                                src/ (12 .rs)
./src/git.rs                                   main.rs, git.rs, config.rs
./src/config.rs                                tracking.rs, filter.rs, utils.rs
./src/tracking.rs                              ...6 more
./src/filter.rs                              tests/ (3 .rs)
./src/utils.rs                                 test_git.rs, test_ls.rs, test_filter.rs
...24 lignes de plus...
```

---

### `prltc grep` -- Recherche dans le contenu

**Objectif :** Remplace `grep` et `rg` avec une sortie groupee par fichier, tronquee.

**Syntaxe :**
```bash
prltc grep <pattern> [chemin] [options]
```

**Options :**

| Option | Court | Defaut | Description |
|--------|-------|--------|-------------|
| `--max-len` | `-l` | 80 | Longueur maximale de ligne |
| `--max` | `-m` | 50 | Nombre maximum de resultats |
| `--context-only` | `-c` | non | Afficher uniquement le contexte du match |
| `--file-type` | `-t` | tous | Filtrer par type (ts, py, rust, etc.) |
| `--line-numbers` | `-n` | oui | Numeros de ligne (toujours actif) |

Les arguments supplementaires sont transmis a `rg` (ripgrep).

**Economies :** ~80%

**Avant / Apres :**
```
# rg "fn run" (20 lignes)                   # prltc grep "fn run" (10 lignes)
src/git.rs:45:pub fn run(...)                src/git.rs
src/git.rs:120:fn run_status(...)              45: pub fn run(...)
src/ls.rs:12:pub fn run(...)                   120: fn run_status(...)
src/ls.rs:25:fn run_tree(...)                src/ls.rs
...                                            12: pub fn run(...)
                                               25: fn run_tree(...)
```

---

### `prltc diff` -- Diff condense

**Objectif :** Diff ultra-condense entre deux fichiers (uniquement les lignes modifiees).

**Syntaxe :**
```bash
prltc diff <fichier1> <fichier2>
prltc diff <fichier1>              # Stdin comme second fichier
```

**Economies :** ~60%

---

### `prltc wc` -- Comptage compact

**Objectif :** Remplace `wc` avec une sortie compacte (supprime les chemins et le padding).

**Syntaxe :**
```bash
prltc wc [args...]
```

Supporte tous les drapeaux natifs de `wc` (`-l`, `-w`, `-c`, etc.).

---

## Commandes Git

### Vue d'ensemble

Toutes les sous-commandes git sont supportees. Les commandes non reconnues sont transmises directement a git (passthrough).

**Options globales git :**

| Option | Description |
|--------|-------------|
| `-C <path>` | Changer de repertoire avant execution |
| `-c <key=value>` | Surcharger une config git |
| `--git-dir <path>` | Chemin vers le repertoire .git |
| `--work-tree <path>` | Chemin vers le working tree |
| `--no-pager` | Desactiver le pager |
| `--no-optional-locks` | Ignorer les locks optionnels |
| `--bare` | Traiter comme repo bare |
| `--literal-pathspecs` | Pathspecs literals |

---

### `prltc git status` -- Status compact

**Economies :** ~80%

```bash
prltc git status [args...]    # Supporte tous les drapeaux git status
```

**Avant / Apres :**
```
# git status (~20 lignes, ~400 tokens)      # prltc git status (~5 lignes, ~80 tokens)
On branch main                               main | 3M 1? 1A
Your branch is up to date with               M src/main.rs
  'origin/main'.                              M src/git.rs
                                              M tests/test_git.rs
Changes not staged for commit:                ? new_file.txt
  (use "git add <file>..." to update)        A staged_file.rs
  modified:   src/main.rs
  modified:   src/git.rs
  ...
```

---

### `prltc git log` -- Historique compact

**Economies :** ~80%

```bash
prltc git log [args...]    # Supporte --oneline, --graph, --all, -n, etc.
```

**Avant / Apres :**
```
# git log (50+ lignes)                      # prltc git log -n 5 (5 lignes)
commit abc123def... (HEAD -> main)           abc123 Fix token counting bug
Author: User <user@email.com>               def456 Add vitest support
Date:   Mon Jan 15 10:30:00 2024            789abc Refactor filter engine
                                             012def Update README
    Fix token counting bug                   345ghi Initial commit
...
```

---

### `prltc git diff` -- Diff compact

**Economies :** ~75%

```bash
prltc git diff [args...]    # Supporte --stat, --cached, --staged, etc.
```

**Avant / Apres :**
```
# git diff (~100 lignes)                    # prltc git diff (~25 lignes)
diff --git a/src/main.rs b/src/main.rs      src/main.rs (+5/-2)
index abc123..def456 100644                    +  let config = Config::load()?;
--- a/src/main.rs                              +  config.validate()?;
+++ b/src/main.rs                              -  // old code
@@ -10,6 +10,8 @@                              -  let x = 42;
   fn main() {                               src/git.rs (+1/-1)
+    let config = Config::load()?;              ~  format!("ok {}", branch)
...30 lignes de headers et contexte...
```

---

### `prltc git show` -- Show compact

**Economies :** ~80%

```bash
prltc git show [args...]
```

Affiche le resume du commit + stat + diff compact.

---

### `prltc git add` -- Add ultra-compact

**Economies :** ~92%

```bash
prltc git add [args...]    # Supporte -A, -p, --all, etc.
```

**Sortie :** `ok` (un seul mot)

---

### `prltc git commit` -- Commit ultra-compact

**Economies :** ~92%

```bash
prltc git commit -m "message" [args...]    # Supporte -a, --amend, --allow-empty, etc.
```

**Sortie :** `ok abc1234` (confirmation + hash court)

---

### `prltc git push` -- Push ultra-compact

**Economies :** ~92%

```bash
prltc git push [args...]    # Supporte -u, remote, branch, etc.
```

**Avant / Apres :**
```
# git push (15 lignes, ~200 tokens)         # prltc git push (1 ligne, ~10 tokens)
Enumerating objects: 5, done.                ok main
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
...
```

---

### `prltc git pull` -- Pull ultra-compact

**Economies :** ~92%

```bash
prltc git pull [args...]
```

**Sortie :** `ok 3 files +10 -2`

---

### `prltc git branch` -- Branches compact

```bash
prltc git branch [args...]    # Supporte -d, -D, -m, etc.
```

Affiche branche courante, branches locales, branches distantes de facon compacte.

---

### `prltc git fetch` -- Fetch compact

```bash
prltc git fetch [args...]
```

**Sortie :** `ok fetched (N new refs)`

---

### `prltc git stash` -- Stash compact

```bash
prltc git stash [list|show|pop|apply|drop|push] [args...]
```

---

### `prltc git worktree` -- Worktree compact

```bash
prltc git worktree [add|remove|prune|list] [args...]
```

---

### Passthrough git

Toute sous-commande git non listee ci-dessus est executee directement :

```bash
prltc git rebase main        # Execute git rebase main
prltc git cherry-pick abc    # Execute git cherry-pick abc
prltc git tag v1.0.0         # Execute git tag v1.0.0
```

---

## Commandes GitHub CLI

### `prltc gh` -- GitHub CLI compact

**Objectif :** Remplace `gh` avec une sortie optimisee.

**Syntaxe :**
```bash
prltc gh <sous-commande> [args...]
```

**Sous-commandes supportees :**

| Commande | Description | Economies |
|----------|-------------|-----------|
| `prltc gh pr list` | Liste des PRs compacte | ~80% |
| `prltc gh pr view <num>` | Details d'une PR + checks | ~87% |
| `prltc gh pr checks` | Status des checks CI | ~79% |
| `prltc gh issue list` | Liste des issues compacte | ~80% |
| `prltc gh run list` | Status des workflow runs | ~82% |
| `prltc gh api <endpoint>` | Reponse API compacte | ~26% |

**Avant / Apres :**
```
# gh pr list (~30 lignes)                   # prltc gh pr list (~10 lignes)
Showing 10 of 15 pull requests in org/repo   #42 feat: add vitest (open, 2d)
                                              #41 fix: git diff crash (open, 3d)
#42  feat: add vitest support                 #40 chore: update deps (merged, 5d)
  user opened about 2 days ago                #39 docs: add guide (merged, 1w)
  ... labels: enhancement
...
```

---

## Commandes Test

### `prltc test` -- Wrapper de tests generique

**Objectif :** Execute n'importe quelle commande de test et affiche uniquement les echecs.

**Syntaxe :**
```bash
prltc test <commande...>
```

**Economies :** ~90%

**Exemple :**
```bash
prltc test cargo test
prltc test npm test
prltc test bun test
prltc test pytest
```

**Avant / Apres :**
```
# cargo test (200+ lignes en cas d'echec)   # prltc test cargo test (~20 lignes)
running 15 tests                             FAILED: 2/15 tests
test utils::test_parse ... ok                  test_edge_case: assertion failed
test utils::test_format ... ok                 test_overflow: panic at utils.rs:18
test utils::test_edge_case ... FAILED
...150 lignes de backtrace...
```

---

### `prltc err` -- Erreurs/avertissements uniquement

**Objectif :** Execute une commande et ne montre que les erreurs et avertissements.

**Syntaxe :**
```bash
prltc err <commande...>
```

**Economies :** ~80%

**Exemple :**
```bash
prltc err npm run build
prltc err cargo build
```

---

### `prltc cargo test` -- Tests Rust

**Economies :** ~90%

```bash
prltc cargo test [args...]
```

N'affiche que les echecs. Supporte tous les arguments de `cargo test`.

---

### `prltc cargo nextest` -- Tests Rust (nextest)

```bash
prltc cargo nextest [run|list|--lib] [args...]
```

Filtre la sortie de `cargo nextest` pour n'afficher que les echecs.

---

### `prltc vitest run` -- Tests Vitest

**Economies :** ~99.5%

```bash
prltc vitest run [args...]
```

---

### `prltc playwright test` -- Tests E2E Playwright

**Economies :** ~94%

```bash
prltc playwright [args...]
```

---

### `prltc pytest` -- Tests Python

**Economies :** ~90%

```bash
prltc pytest [args...]
```

---

### `prltc go test` -- Tests Go

**Economies :** ~90%

```bash
prltc go test [args...]
```

Utilise le streaming JSON NDJSON de Go pour un filtrage precis.

---

## Commandes Build et Lint

### `prltc cargo build` -- Build Rust

**Economies :** ~80%

```bash
prltc cargo build [args...]
```

Supprime les lignes "Compiling...", ne conserve que les erreurs et le resultat final.

---

### `prltc cargo check` -- Check Rust

**Economies :** ~80%

```bash
prltc cargo check [args...]
```

Supprime les lignes "Checking...", ne conserve que les erreurs.

---

### `prltc cargo clippy` -- Clippy Rust

**Economies :** ~80%

```bash
prltc cargo clippy [args...]
```

Regroupe les avertissements par regle de lint.

---

### `prltc cargo install` -- Install Rust

```bash
prltc cargo install [args...]
```

Supprime la compilation des dependances, ne conserve que le resultat d'installation et les erreurs.

---

### `prltc tsc` -- TypeScript Compiler

**Economies :** ~83%

```bash
prltc tsc [args...]
```

Regroupe les erreurs TypeScript par fichier et par code d'erreur.

**Avant / Apres :**
```
# tsc --noEmit (50 lignes)                  # prltc tsc (15 lignes)
src/api.ts(12,5): error TS2345: ...          src/api.ts (3 errors)
src/api.ts(15,10): error TS2345: ...           TS2345: Argument type mismatch (x2)
src/api.ts(20,3): error TS7006: ...            TS7006: Parameter implicitly has 'any'
src/utils.ts(5,1): error TS2304: ...         src/utils.ts (1 error)
...                                            TS2304: Cannot find name 'foo'
```

---

### `prltc lint` -- ESLint / Biome

**Economies :** ~84%

```bash
prltc lint [args...]
prltc lint biome [args...]
```

Regroupe les violations par regle et par fichier. Auto-detecte le linter.

---

### `prltc prettier` -- Verification du formatage

**Economies :** ~70%

```bash
prltc prettier [args...]    # ex: prltc prettier --check .
```

Affiche uniquement les fichiers necessitant un formatage.

---

### `prltc format` -- Formateur universel

```bash
prltc format [args...]
```

Auto-detecte le formateur du projet (prettier, black, ruff format) et applique un filtre compact.

---

### `prltc next build` -- Build Next.js

**Economies :** ~87%

```bash
prltc next [args...]
```

Sortie compacte avec metriques de routes.

---

### `prltc ruff` -- Linter/formateur Python

**Economies :** ~80%

```bash
prltc ruff check [args...]
prltc ruff format --check [args...]
```

Sortie JSON compressee.

---

### `prltc mypy` -- Type checker Python

```bash
prltc mypy [args...]
```

Regroupe les erreurs de type par fichier.

---

### `prltc golangci-lint` -- Linter Go

**Economies :** ~85%

```bash
prltc golangci-lint run [args...]
```

Sortie JSON compressee.

---

## Commandes Formatage

### `prltc prettier` -- Prettier

```bash
prltc prettier --check .
prltc prettier --write src/
```

---

### `prltc format` -- Detecteur universel

```bash
prltc format [args...]
```

Detecte automatiquement : prettier, black, ruff format, rustfmt. Applique un filtre compact unifie.

---

## Gestionnaires de paquets

### `prltc pnpm` -- pnpm

| Commande | Description | Economies |
|----------|-------------|-----------|
| `prltc pnpm list [-d N]` | Arbre de dependances compact | ~70% |
| `prltc pnpm outdated` | Paquets obsoletes : `pkg: old -> new` | ~80% |
| `prltc pnpm install [pkgs...]` | Filtre les barres de progression | ~60% |
| `prltc pnpm build` | Delegue au filtre Next.js | ~87% |
| `prltc pnpm typecheck` | Delegue au filtre tsc | ~83% |

Les sous-commandes non reconnues sont transmises directement a pnpm (passthrough).

---

### `prltc npm` -- npm

```bash
prltc npm [args...]    # ex: prltc npm run build
```

Filtre le boilerplate npm (barres de progression, en-tetes, etc.).

---

### `prltc npx` -- npx avec routage intelligent

```bash
prltc npx [args...]
```

Route intelligemment vers les filtres specialises :
- `prltc npx tsc` -> filtre tsc
- `prltc npx eslint` -> filtre lint
- `prltc npx prisma` -> filtre prisma
- Autres -> passthrough filtre

---

### `prltc pip` -- pip / uv

```bash
prltc pip list              # Liste des paquets (auto-detecte uv)
prltc pip outdated          # Paquets obsoletes
prltc pip install <pkg>     # Installation
```

Auto-detecte `uv` si disponible et l'utilise a la place de `pip`.

---

### `prltc deps` -- Resume des dependances

**Objectif :** Resume compact des dependances du projet.

```bash
prltc deps [chemin]    # Defaut: repertoire courant
```

Auto-detecte : `Cargo.toml`, `package.json`, `pyproject.toml`, `go.mod`, `Gemfile`, etc.

**Economies :** ~70%

---

### `prltc prisma` -- ORM Prisma

| Commande | Description |
|----------|-------------|
| `prltc prisma generate` | Generation du client (supprime l'ASCII art) |
| `prltc prisma migrate dev [--name N]` | Creer et appliquer une migration |
| `prltc prisma migrate status` | Status des migrations |
| `prltc prisma migrate deploy` | Deployer en production |
| `prltc prisma db-push` | Push du schema |

---

## Conteneurs et orchestration

### `prltc docker` -- Docker

| Commande | Description | Economies |
|----------|-------------|-----------|
| `prltc docker ps` | Liste compacte des conteneurs | ~80% |
| `prltc docker images` | Liste compacte des images | ~80% |
| `prltc docker logs <conteneur>` | Logs dedupliques | ~70% |
| `prltc docker compose ps` | Services Compose compacts | ~80% |
| `prltc docker compose logs [service]` | Logs Compose dedupliques | ~70% |
| `prltc docker compose build [service]` | Resume du build | ~60% |

Les sous-commandes non reconnues sont transmises directement (passthrough).

**Avant / Apres :**
```
# docker ps (lignes longues, ~30 tokens/ligne)    # prltc docker ps (~10 tokens/ligne)
CONTAINER ID   IMAGE          COMMAND     ...      web  nginx:1.25 Up 2d (healthy)
abc123def456   nginx:1.25     "/dock..."  ...      db   postgres:16 Up 2d (healthy)
789012345678   postgres:16    "docker..."           redis redis:7 Up 1d
```

---

### `prltc kubectl` -- Kubernetes

| Commande | Description | Options |
|----------|-------------|---------|
| `prltc kubectl pods [-n ns] [-A]` | Liste compacte des pods | Namespace ou tous |
| `prltc kubectl services [-n ns] [-A]` | Liste compacte des services | Namespace ou tous |
| `prltc kubectl logs <pod> [-c container]` | Logs dedupliques | Container specifique |

Les sous-commandes non reconnues sont transmises directement (passthrough).

---

## Donnees et reseau

### `prltc json` -- Structure JSON

**Objectif :** Affiche la structure d'un fichier JSON sans les valeurs.

```bash
prltc json <fichier> [--depth N]    # Defaut: profondeur 5
prltc json -                         # Depuis stdin
```

**Economies :** ~60%

**Avant / Apres :**
```
# cat package.json (50 lignes)              # prltc json package.json (10 lignes)
{                                            {
  "name": "my-app",                            name: string
  "version": "1.0.0",                         version: string
  "dependencies": {                            dependencies: { 15 keys }
    "react": "^18.2.0",                        devDependencies: { 8 keys }
    "next": "^14.0.0",                         scripts: { 6 keys }
    ...15 dependances...                     }
  },
  ...
}
```

---

### `prltc env` -- Variables d'environnement

```bash
prltc env                    # Toutes les variables (sensibles masquees)
prltc env -f AWS             # Filtrer par nom
prltc env --show-all         # Inclure les valeurs sensibles
```

Les variables sensibles (tokens, secrets, mots de passe) sont masquees par defaut : `AWS_SECRET_ACCESS_KEY=***`.

---

### `prltc log` -- Logs dedupliques

**Objectif :** Filtre et deduplique la sortie de logs.

```bash
prltc log <fichier>     # Depuis un fichier
prltc log               # Depuis stdin (pipe)
```

Les lignes repetees sont fusionnees : `[ERROR] Connection refused (x42)`.

**Economies :** ~60-80% (selon la repetitivite)

---

### `prltc curl` -- HTTP avec detection JSON

```bash
prltc curl [args...]
```

Auto-detecte les reponses JSON et affiche le schema au lieu du contenu complet.

---

### `prltc wget` -- Telechargement compact

```bash
prltc wget <url> [args...]
prltc wget -O - <url>           # Sortie vers stdout
```

Supprime les barres de progression et le bruit.

---

### `prltc summary` -- Resume heuristique

**Objectif :** Execute une commande et genere un resume heuristique de la sortie.

```bash
prltc summary <commande...>
```

Utile pour les commandes longues dont la sortie n'a pas de filtre dedie.

---

### `prltc proxy` -- Passthrough avec suivi

**Objectif :** Execute une commande **sans filtrage** mais enregistre l'utilisation pour le suivi.

```bash
prltc proxy <commande...>
```

Utile pour le debug : comparer la sortie brute avec la sortie filtree.

---

## Cloud et bases de donnees

### `prltc aws` -- AWS CLI

```bash
prltc aws <service> [args...]
```

Force la sortie JSON et compresse le resultat. Supporte tous les services AWS (sts, s3, ec2, ecs, rds, cloudformation, etc.).

---

### `prltc psql` -- PostgreSQL

```bash
prltc psql [args...]
```

Supprime les bordures de tableaux et compresse la sortie.

---

## Stacked PRs (Graphite)

### `prltc gt` -- Graphite

| Commande | Description |
|----------|-------------|
| `prltc gt log` | Stack log compact |
| `prltc gt submit` | Submit compact |
| `prltc gt sync` | Sync compact |
| `prltc gt restack` | Restack compact |
| `prltc gt create` | Create compact |
| `prltc gt branch` | Branch info compact |

Les sous-commandes non reconnues sont transmises directement ou detectees comme passthrough git.

---

## Analytique et suivi

### Systeme de tracking

PRLTC enregistre chaque execution de commande dans une base SQLite :

- **Emplacement :** `~/.local/share/prltc/tracking.db` (Linux), `~/Library/Application Support/prltc/tracking.db` (macOS)
- **Retention :** 90 jours automatique
- **Metriques :** tokens entree/sortie, pourcentage d'economies, temps d'execution, projet

---

### `prltc gain` -- Statistiques d'economies

```bash
prltc gain                        # Resume global
prltc gain -p                     # Filtre par projet courant
prltc gain --graph                # Graphe ASCII (30 derniers jours)
prltc gain --history              # Historique recent des commandes
prltc gain --daily                # Ventilation jour par jour
prltc gain --weekly               # Ventilation par semaine
prltc gain --monthly              # Ventilation par mois
prltc gain --all                  # Toutes les ventilations
prltc gain --quota -t pro         # Estimation d'economies sur le quota mensuel
prltc gain --failures             # Log des echecs de parsing (commandes en fallback)
prltc gain --format json          # Export JSON (pour dashboards)
prltc gain --format csv           # Export CSV
```

**Options :**

| Option | Court | Description |
|--------|-------|-------------|
| `--project` | `-p` | Filtrer par repertoire courant |
| `--graph` | `-g` | Graphe ASCII des 30 derniers jours |
| `--history` | `-H` | Historique recent des commandes |
| `--quota` | `-q` | Estimation d'economies sur le quota mensuel |
| `--tier` | `-t` | Tier d'abonnement : `pro`, `5x`, `20x` (defaut: `20x`) |
| `--daily` | `-d` | Ventilation quotidienne |
| `--weekly` | `-w` | Ventilation hebdomadaire |
| `--monthly` | `-m` | Ventilation mensuelle |
| `--all` | `-a` | Toutes les ventilations |
| `--format` | `-f` | Format de sortie : `text`, `json`, `csv` |
| `--failures` | `-F` | Affiche les commandes en fallback |

**Exemple de sortie :**
```
$ prltc gain
PRLTC Token Savings Summary
  Total commands:     1,247
  Total input:        2,341,000 tokens
  Total output:       468,200 tokens
  Total saved:        1,872,800 tokens (80%)
  Avg per command:    1,501 tokens saved

Top commands:
  git status    312x  -82%
  cargo test    156x  -91%
  git diff       98x  -76%
```

---

### `prltc discover` -- Opportunites manquees

**Objectif :** Analyse l'historique Claude Code pour trouver les commandes qui auraient pu etre optimisees par prltc.

```bash
prltc discover                          # Projet courant, 30 derniers jours
prltc discover --all --since 7          # Tous les projets, 7 derniers jours
prltc discover -p /chemin/projet        # Filtrer par projet
prltc discover --limit 20              # Max commandes par section
prltc discover --format json            # Export JSON
```

**Options :**

| Option | Court | Description |
|--------|-------|-------------|
| `--project` | `-p` | Filtrer par chemin de projet |
| `--limit` | `-l` | Max commandes par section (defaut: 15) |
| `--all` | `-a` | Scanner tous les projets |
| `--since` | `-s` | Derniers N jours (defaut: 30) |
| `--format` | `-f` | Format : `text`, `json` |

---

### `prltc learn` -- Apprendre des erreurs

**Objectif :** Analyse l'historique d'erreurs CLI de Claude Code pour detecter les corrections recurrentes.

```bash
prltc learn                             # Projet courant
prltc learn --all --since 7             # Tous les projets
prltc learn --write-rules               # Generer .claude/rules/cli-corrections.md
prltc learn --min-confidence 0.8        # Seuil de confiance (defaut: 0.6)
prltc learn --min-occurrences 3         # Occurrences minimales (defaut: 1)
prltc learn --format json               # Export JSON
```

---

### `prltc cc-economics` -- Analyse economique Claude Code

**Objectif :** Compare les depenses Claude Code (via ccusage) avec les economies PRLTC.

```bash
prltc cc-economics                      # Resume
prltc cc-economics --daily              # Ventilation quotidienne
prltc cc-economics --weekly             # Ventilation hebdomadaire
prltc cc-economics --monthly            # Ventilation mensuelle
prltc cc-economics --all                # Toutes les ventilations
prltc cc-economics --format json        # Export JSON
```

---

### `prltc hook-audit` -- Metriques du hook

**Prerequis :** Necessite `PRLTC_HOOK_AUDIT=1` dans l'environnement.

```bash
prltc hook-audit                        # 7 derniers jours (defaut)
prltc hook-audit --since 30             # 30 derniers jours
prltc hook-audit --since 0              # Tout l'historique
```

---

## Systeme de hooks

### Fonctionnement

Le hook PRLTC intercepte les commandes Bash dans Claude Code **avant leur execution** et les reecrit automatiquement en equivalent PRLTC.

**Flux :**
```
Claude Code "git status"
    |
    v
settings.json -> PreToolUse hook
    |
    v
prltc-rewrite.sh (bash)
    |
    v
prltc rewrite "git status"  ->  "prltc git status"
    |
    v
Claude Code execute "prltc git status"
    |
    v
Sortie filtree retournee a Claude (~10 tokens vs ~200)
```

**Points cles :**
- Claude ne voit jamais la recriture -- il recoit simplement une sortie optimisee
- Le hook est un delegateur leger (~50 lignes bash) qui appelle `prltc rewrite`
- Toute la logique de recriture est dans le registre Rust (`src/discover/registry.rs`)
- Les commandes deja prefixees par `prltc` passent sans modification
- Les heredocs (`<<`) ne sont pas modifies
- Les commandes non reconnues passent sans modification

### Installation

```bash
prltc init -g                     # Installation recommandee (hook + PRLTC.md)
prltc init -g --auto-patch        # Non-interactif (CI/CD)
prltc init -g --hook-only         # Hook seul, sans PRLTC.md
prltc init --show                 # Verifier l'installation
prltc init -g --uninstall         # Desinstaller
```

### Fichiers installes

| Fichier | Description |
|---------|-------------|
| `~/.claude/hooks/prltc-rewrite.sh` | Script hook (delegue a `prltc rewrite`) |
| `~/.claude/PRLTC.md` | Instructions minimales pour le LLM |
| `~/.claude/settings.json` | Enregistrement du hook PreToolUse |

### `prltc rewrite` -- Recriture de commande

Commande interne utilisee par le hook. Imprime la commande reecrite sur stdout (exit 0) ou sort avec exit 1 si aucun equivalent PRLTC n'existe.

```bash
prltc rewrite "git status"           # -> "prltc git status" (exit 0)
prltc rewrite "terraform plan"       # -> (exit 1, pas de recriture)
prltc rewrite "prltc git status"       # -> "prltc git status" (exit 0, inchange)
```

### `prltc verify` -- Verification d'integrite

Verifie l'integrite du hook installe via un controle SHA-256.

```bash
prltc verify
```

### Commandes reecrites automatiquement

| Commande brute | Reecrite en |
|----------------|-------------|
| `git status/diff/log/add/commit/push/pull` | `prltc git ...` |
| `gh pr/issue/run` | `prltc gh ...` |
| `cargo test/build/clippy/check` | `prltc cargo ...` |
| `cat/head/tail <fichier>` | `prltc read <fichier>` |
| `rg/grep <pattern>` | `prltc grep <pattern>` |
| `ls` | `prltc ls` |
| `tree` | `prltc tree` |
| `wc` | `prltc wc` |
| `vitest/jest` | `prltc vitest run` |
| `tsc` | `prltc tsc` |
| `eslint/biome` | `prltc lint` |
| `prettier` | `prltc prettier` |
| `playwright` | `prltc playwright` |
| `prisma` | `prltc prisma` |
| `ruff check/format` | `prltc ruff ...` |
| `pytest` | `prltc pytest` |
| `mypy` | `prltc mypy` |
| `pip list/install` | `prltc pip ...` |
| `go test/build/vet` | `prltc go ...` |
| `golangci-lint` | `prltc golangci-lint` |
| `docker ps/images/logs` | `prltc docker ...` |
| `kubectl get/logs` | `prltc kubectl ...` |
| `curl` | `prltc curl` |
| `pnpm list/outdated` | `prltc pnpm ...` |

### Exclusion de commandes

Pour empecher certaines commandes d'etre reecrites, ajoutez-les dans `config.toml` :

```toml
[hooks]
exclude_commands = ["curl", "playwright"]
```

---

## Configuration

### Fichier de configuration

**Emplacement :** `~/.config/prltc/config.toml` (Linux) ou `~/Library/Application Support/prltc/config.toml` (macOS)

**Commandes :**
```bash
prltc config                # Afficher la configuration actuelle
prltc config --create       # Creer le fichier avec les valeurs par defaut
```

### Structure complete

```toml
[tracking]
enabled = true              # Activer/desactiver le suivi
history_days = 90           # Jours de retention (nettoyage automatique)
database_path = "/custom/path/tracking.db"  # Chemin personnalise (optionnel)

[display]
colors = true               # Sortie coloree
emoji = true                # Utiliser les emojis
max_width = 120             # Largeur maximale de sortie

[filters]
ignore_dirs = [".git", "node_modules", "target", "__pycache__", ".venv", "vendor"]
ignore_files = ["*.lock", "*.min.js", "*.min.css"]

[tee]
enabled = true              # Activer la sauvegarde de sortie brute
mode = "failures"           # "failures" (defaut), "always", ou "never"
max_files = 20              # Rotation : garder les N derniers fichiers
# directory = "/custom/tee/path"  # Chemin personnalise (optionnel)

[telemetry]
enabled = true              # Telemetrie anonyme (1 ping/jour, opt-out possible)

[hooks]
exclude_commands = []       # Commandes a exclure de la recriture automatique
```

### Variables d'environnement

| Variable | Description |
|----------|-------------|
| `PRLTC_TEE_DIR` | Surcharge le repertoire tee |
| `PRLTC_TELEMETRY_DISABLED=1` | Desactiver la telemetrie |
| `PRLTC_HOOK_AUDIT=1` | Activer l'audit du hook |
| `SKIP_ENV_VALIDATION=1` | Desactiver la validation d'env (Next.js, etc.) |

---

## Systeme Tee

### Recuperation de sortie brute

Quand une commande echoue, PRLTC sauvegarde automatiquement la sortie brute complete dans un fichier log. Cela permet au LLM de lire la sortie sans re-executer la commande.

**Fonctionnement :**
1. La commande echoue (exit code != 0)
2. PRLTC sauvegarde la sortie brute dans `~/.local/share/prltc/tee/`
3. Le chemin du fichier est affiche dans la sortie filtree
4. Le LLM peut lire le fichier si besoin de plus de details

**Sortie :**
```
FAILED: 2/15 tests
[full output: ~/.local/share/prltc/tee/1707753600_cargo_test.log]
```

**Configuration :**

| Parametre | Defaut | Description |
|-----------|--------|-------------|
| `tee.enabled` | `true` | Activer/desactiver |
| `tee.mode` | `"failures"` | `"failures"`, `"always"`, `"never"` |
| `tee.max_files` | `20` | Rotation : garder les N derniers |
| Taille min | 500 octets | Les sorties trop courtes ne sont pas sauvegardees |
| Taille max fichier | 1 Mo | Troncature au-dela |

---

## Telemetrie

PRLTC envoie un ping anonyme une fois par jour (23h d'intervalle) pour des statistiques d'utilisation.

**Donnees envoyees :** hash de device, version, OS, architecture, nombre de commandes/24h, top commandes, pourcentage d'economies.

**Desactiver :**
```bash
# Via variable d'environnement
export PRLTC_TELEMETRY_DISABLED=1

# Via config.toml
[telemetry]
enabled = false
```

Aucune donnee personnelle, aucun contenu de commande, aucun chemin de fichier n'est transmis.

---

## Resume des economies par categorie

| Categorie | Commandes | Economies typiques |
|-----------|-----------|-------------------|
| **Fichiers** | ls, tree, read, find, grep, diff | 60-80% |
| **Git** | status, log, diff, show, add, commit, push, pull | 75-92% |
| **GitHub** | pr, issue, run, api | 26-87% |
| **Tests** | cargo test, vitest, playwright, pytest, go test | 90-99% |
| **Build/Lint** | cargo build, tsc, eslint, prettier, next, ruff, clippy | 70-87% |
| **Paquets** | pnpm, npm, pip, deps, prisma | 60-80% |
| **Conteneurs** | docker, kubectl | 70-80% |
| **Donnees** | json, env, log, curl, wget | 60-80% |
| **Analytique** | gain, discover, learn, cc-economics | N/A (meta) |

---

## Nombre total de commandes

PRLTC supporte **45+ commandes** reparties en 9 categories, avec passthrough automatique pour les sous-commandes non reconnues. Cela en fait un proxy universel : il est toujours sur a utiliser en prefixe.
