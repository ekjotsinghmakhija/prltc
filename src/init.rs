/*
 * Titanium Engine Core - prltc
 * Copyright (c) 2026 Ekjot Singh
 * Proprietary Clean Room Implementation
 */

use anyhow::Result;
use std::fs;
use std::path::PathBuf;

const PRLTC_INSTRUCTIONS: &str = r#"# Instructions: Utiliser prltc pour économiser des tokens

## Règle obligatoire
Remplacer les commandes Unix standard par `prltc` pour minimiser la consommation de tokens.

**IMPORTANT:** Même lors du chaînage de commandes avec `&&`, utiliser `prltc`:
```bash
# ❌ Ne pas faire
git add . && git commit -m "msg" && git push

# ✅ Faire
prltc git add && prltc git commit -m "msg" && prltc git push
```

## Substitutions

| ❌ Ne pas utiliser | ✅ Utiliser |
|-------------------|-------------|
| `ls`, `tree` | `prltc ls <path>` |
| `cat`, `head`, `tail` | `prltc read <file>` |
| `cat` pour comprendre du code | `prltc read <file> -l aggressive` |
| `find`, `fd` | `prltc find <pattern>` |
| `diff file1 file2` | `prltc diff <f1> <f2>` |
| `git status` | `prltc git status` |
| `git log` | `prltc git log` |
| `git diff` | `prltc git diff` |
| `git add .` | `prltc git add` |
| `git commit -m "msg"` | `prltc git commit -m "msg"` |
| `git push` | `prltc git push` |
| `git pull` | `prltc git pull` |
| `cargo test`, `pytest`, `npm test` | `prltc test <cmd>` |
| `<cmd> 2>&1 \| grep -i error` | `prltc err <cmd>` |
| `cat file.log` | `prltc log <file>` |
| `cat package.json` | `prltc json <file>` |
| `cat Cargo.toml` (pour deps) | `prltc deps` |
| `env`, `printenv` | `prltc env` |
| `docker ps` | `prltc docker ps` |
| `docker images` | `prltc docker images` |
| `docker logs <c>` | `prltc docker logs <c>` |
| `kubectl get pods` | `prltc kubectl pods` |
| `kubectl logs <pod>` | `prltc kubectl logs <pod>` |
| `grep -rn`, `rg` | `prltc grep <pattern>` |
| `<longue commande>` | `prltc summary <cmd>` |

## Commandes prltc (15 total)

```bash
# Fichiers
prltc ls .                        # Arbre filtré (-82% tokens)
prltc read file.rs -l aggressive  # Signatures seules (-74% tokens)
prltc smart file.rs               # Résumé 2 lignes
prltc find "*.rs" .               # Find compact groupé par dossier
prltc diff f1.txt f2.txt          # Diff ultra-condensé

# Git
prltc git status                  # Status compact
prltc git log -n 10               # 10 commits compacts
prltc git diff                    # Diff compact
prltc git add                     # Add → "ok ✓"
prltc git commit -m "msg"         # Commit → "ok ✓ abc1234"
prltc git push                    # Push → "ok ✓ main"
prltc git pull                    # Pull → "ok ✓ 3 files"
prltc grep "pattern"              # Grep groupé par fichier

# Commandes
prltc test cargo test             # Échecs seuls (-90% tokens)
prltc err npm run build           # Erreurs seules (-80% tokens)
prltc summary <cmd>               # Résumé heuristique
prltc log app.log                 # Logs dédupliqués (erreurs ×N)

# Données
prltc json config.json            # Structure sans valeurs
prltc deps                        # Résumé dépendances
prltc env -f AWS                  # Vars filtrées

# Conteneurs
prltc docker ps                   # Conteneurs compacts
prltc docker images               # Images compactes
prltc docker logs <container>     # Logs dédupliqués
prltc kubectl pods                # Pods compacts
prltc kubectl services            # Services compacts
prltc kubectl logs <pod>          # Logs dédupliqués
```
"#;

pub fn run(global: bool, verbose: u8) -> Result<()> {
    let path = if global {
        dirs::home_dir()
            .map(|h| h.join(".claude").join("CLAUDE.md"))
            .unwrap_or_else(|| PathBuf::from("~/.claude/CLAUDE.md"))
    } else {
        PathBuf::from("CLAUDE.md")
    };

    if global {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
    }

    if verbose > 0 {
        eprintln!("Writing prltc instructions to: {}", path.display());
    }

    // Check if file exists
    if path.exists() {
        let existing = fs::read_to_string(&path)?;

        // Check if prltc instructions already present
        if existing.contains("prltc") && existing.contains("Utiliser prltc") {
            println!("✅ {} already contains prltc instructions", path.display());
            return Ok(());
        }

        // Append to existing file
        let new_content = format!("{}\n\n{}", existing.trim(), PRLTC_INSTRUCTIONS);
        fs::write(&path, new_content)?;
        println!("✅ Added prltc instructions to existing {}", path.display());
    } else {
        // Create new file
        fs::write(&path, PRLTC_INSTRUCTIONS)?;
        println!("✅ Created {} with prltc instructions", path.display());
    }

    if global {
        println!("   Claude Code will now use prltc in all sessions");
    } else {
        println!("   Claude Code will use prltc in this project");
    }

    Ok(())
}

/// Show current prltc configuration
pub fn show_config() -> Result<()> {
    let home_path = dirs::home_dir().map(|h| h.join(".claude").join("CLAUDE.md"));
    let local_path = PathBuf::from("CLAUDE.md");

    println!("📋 prltc Configuration:\n");

    // Check global
    if let Some(hp) = &home_path {
        if hp.exists() {
            let content = fs::read_to_string(hp)?;
            if content.contains("prltc") {
                println!("✅ Global (~/.claude/CLAUDE.md): prltc enabled");
            } else {
                println!("⚪ Global (~/.claude/CLAUDE.md): exists but prltc not configured");
            }
        } else {
            println!("⚪ Global (~/.claude/CLAUDE.md): not found");
        }
    }

    // Check local
    if local_path.exists() {
        let content = fs::read_to_string(&local_path)?;
        if content.contains("prltc") {
            println!("✅ Local (./CLAUDE.md): prltc enabled");
        } else {
            println!("⚪ Local (./CLAUDE.md): exists but prltc not configured");
        }
    } else {
        println!("⚪ Local (./CLAUDE.md): not found");
    }

    println!("\nUsage:");
    println!("  prltc init          # Add prltc to local CLAUDE.md");
    println!("  prltc init --global # Add prltc to global ~/.claude/CLAUDE.md");

    Ok(())
}
