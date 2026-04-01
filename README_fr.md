<p align="center">
  
</p>

<p align="center">
  <strong>Proxy CLI haute performance qui reduit la consommation de tokens LLM de 60-90%</strong>
</p>

<p align="center">
  <a href="https://github.com/ekjotsinghmakhija/prltc/actions"></a>
  <a href="https://github.com/ekjotsinghmakhija/prltc/releases"></a>
  <a href="https://opensource.org/licenses/MIT"></a>
  
  <a href="https://formulae.brew.sh/formula/prltc"></a>
</p>

<p align="center">
  <a href="https://www.github.com/ekjotsinghmakhija/prltc">Site web</a> &bull;
  <a href="#installation">Installer</a> &bull;
  <a href="docs/TROUBLESHOOTING.md">Depannage</a> &bull;
  <a href="docs/contributing/ARCHITECTURE.md">Architecture</a> &bull;
  
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

prltc filtre et compresse les sorties de commandes avant qu'elles n'atteignent le contexte de votre LLM. Binaire Rust unique, zero dependance, <10ms d'overhead.

## Economies de tokens (session Claude Code de 30 min)

| Operation | Frequence | Standard | prltc | Economies |
|-----------|-----------|----------|-----|-----------|
| `ls` / `tree` | 10x | 2 000 | 400 | -80% |
| `cat` / `read` | 20x | 40 000 | 12 000 | -70% |
| `grep` / `rg` | 8x | 16 000 | 3 200 | -80% |
| `git status` | 10x | 3 000 | 600 | -80% |
| `git diff` | 5x | 10 000 | 2 500 | -75% |
| `git log` | 5x | 2 500 | 500 | -80% |
| `git add/commit/push` | 8x | 1 600 | 120 | -92% |
| `cargo test` / `npm test` | 5x | 25 000 | 2 500 | -90% |
| **Total** | | **~118 000** | **~23 900** | **-80%** |

> Estimations basees sur des projets TypeScript/Rust de taille moyenne.

## Installation

### Homebrew (recommande)

```bash
brew install prltc
```

### Installation rapide (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

### Cargo

```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
```

### Verification

```bash
prltc --version   # Doit afficher "prltc 0.27.x"
prltc gain        # Doit afficher les statistiques d'economies
```

> **Attention** : Un autre projet "prltc" (Rust Type Kit) existe sur crates.io. Si `prltc gain` echoue, vous avez le mauvais package.

## Demarrage rapide

```bash
# 1. Installer le hook pour Claude Code (recommande)
prltc init --global
# Suivre les instructions pour enregistrer dans ~/.claude/settings.json

# 2. Redemarrer Claude Code, puis tester
git status  # Automatiquement reecrit en prltc git status
```

Le hook reecrit de maniere transparente les commandes (ex: `git status` -> `prltc git status`) avant execution.

## Comment ca marche

```
  Sans prltc :                                       Avec prltc :

  Claude  --git status-->  shell  -->  git          Claude  --git status-->  PRLTC  -->  git
    ^                                   |             ^                      |          |
    |        ~2 000 tokens (brut)       |             |   ~200 tokens        | filtre   |
    +-----------------------------------+             +------- (filtre) -----+----------+
```

Quatre strategies appliquees par type de commande :

1. **Filtrage intelligent** - Supprime le bruit (commentaires, espaces, boilerplate)
2. **Regroupement** - Agregat d'elements similaires (fichiers par dossier, erreurs par type)
3. **Troncature** - Conserve le contexte pertinent, coupe la redondance
4. **Deduplication** - Fusionne les lignes de log repetees avec compteurs

## Commandes

### Fichiers
```bash
prltc ls .                        # Arbre de repertoires optimise
prltc read file.rs                # Lecture intelligente
prltc read file.rs -l aggressive  # Signatures uniquement
prltc find "*.rs" .               # Resultats compacts
prltc grep "pattern" .            # Resultats groupes par fichier
prltc diff file1 file2            # Diff condense
```

### Git
```bash
prltc git status                  # Status compact
prltc git log -n 10               # Commits sur une ligne
prltc git diff                    # Diff condense
prltc git add                     # -> "ok"
prltc git commit -m "msg"         # -> "ok abc1234"
prltc git push                    # -> "ok main"
```

### Tests
```bash
prltc test cargo test             # Echecs uniquement (-90%)
prltc vitest run                  # Vitest compact
prltc pytest                      # Tests Python (-90%)
prltc go test                     # Tests Go (-90%)
prltc cargo test                  # Tests Cargo (-90%)
```

### Build & Lint
```bash
prltc lint                        # ESLint groupe par regle
prltc tsc                         # Erreurs TypeScript groupees
prltc cargo build                 # Build Cargo (-80%)
prltc cargo clippy                # Clippy (-80%)
prltc ruff check                  # Linting Python (-80%)
```

### Conteneurs
```bash
prltc docker ps                   # Liste compacte
prltc docker logs <container>     # Logs dedupliques
prltc kubectl pods                # Pods compacts
```

### Analytics
```bash
prltc gain                        # Statistiques d'economies
prltc gain --graph                # Graphique ASCII (30 jours)
prltc discover                    # Trouver les economies manquees
```

## Configuration

```toml
# ~/.config/prltc/config.toml
[tracking]
database_path = "/chemin/custom.db"

[hooks]
exclude_commands = ["curl", "playwright"]

[tee]
enabled = true
mode = "failures"
```

## Documentation

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Resoudre les problemes courants
- **[INSTALL.md](INSTALL.md)** - Guide d'installation detaille
- **[ARCHITECTURE.md](docs/contributing/ARCHITECTURE.md)** - Architecture technique

## Contribuer

Les contributions sont les bienvenues ! Ouvrez une issue ou une PR sur [GitHub](https://github.com/ekjotsinghmakhija/prltc).

Rejoignez la communaute sur .

## Licence

Licence MIT - voir [LICENSE](LICENSE) pour les details.

## Avertissement

Voir [DISCLAIMER.md](DISCLAIMER.md).
