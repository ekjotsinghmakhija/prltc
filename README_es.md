<p align="center">
  
</p>

<p align="center">
  <strong>Proxy CLI de alto rendimiento que reduce el consumo de tokens LLM en un 60-90%</strong>
</p>

<p align="center">
  <a href="https://github.com/ekjotsinghmakhija/prltc/actions"></a>
  <a href="https://github.com/ekjotsinghmakhija/prltc/releases"></a>
  <a href="https://opensource.org/licenses/MIT"></a>
  
  <a href="https://formulae.brew.sh/formula/prltc"></a>
</p>

<p align="center">
  <a href="https://www.github.com/ekjotsinghmakhija/prltc">Sitio web</a> &bull;
  <a href="#instalacion">Instalar</a> &bull;
  <a href="docs/TROUBLESHOOTING.md">Solucion de problemas</a> &bull;
  <a href="docs/contributing/ARCHITECTURE.md">Arquitectura</a> &bull;
  
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

prltc filtra y comprime las salidas de comandos antes de que lleguen al contexto de tu LLM. Binario Rust unico, cero dependencias, <10ms de overhead.

## Ahorro de tokens (sesion de 30 min en Claude Code)

| Operacion | Frecuencia | Estandar | prltc | Ahorro |
|-----------|------------|----------|-----|--------|
| `ls` / `tree` | 10x | 2,000 | 400 | -80% |
| `cat` / `read` | 20x | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8x | 16,000 | 3,200 | -80% |
| `git status` | 10x | 3,000 | 600 | -80% |
| `cargo test` / `npm test` | 5x | 25,000 | 2,500 | -90% |
| **Total** | | **~118,000** | **~23,900** | **-80%** |

## Instalacion

### Homebrew (recomendado)

```bash
brew install prltc
```

### Instalacion rapida (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

### Cargo

```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
```

### Verificacion

```bash
prltc --version   # Debe mostrar "prltc 0.27.x"
prltc gain        # Debe mostrar estadisticas de ahorro
```

## Inicio rapido

```bash
# 1. Instalar hook para Claude Code (recomendado)
prltc init --global

# 2. Reiniciar Claude Code, luego probar
git status  # Automaticamente reescrito a prltc git status
```

## Como funciona

```
  Sin prltc:                                         Con prltc:

  Claude  --git status-->  shell  -->  git          Claude  --git status-->  PRLTC  -->  git
    ^                                   |             ^                      |          |
    |        ~2,000 tokens (crudo)      |             |   ~200 tokens        | filtro   |
    +-----------------------------------+             +------- (filtrado) ---+----------+
```

Cuatro estrategias:

1. **Filtrado inteligente** - Elimina ruido (comentarios, espacios, boilerplate)
2. **Agrupacion** - Agrega elementos similares (archivos por directorio, errores por tipo)
3. **Truncamiento** - Mantiene contexto relevante, elimina redundancia
4. **Deduplicacion** - Colapsa lineas de log repetidas con contadores

## Comandos

### Archivos
```bash
prltc ls .                        # Arbol de directorios optimizado
prltc read file.rs                # Lectura inteligente
prltc find "*.rs" .               # Resultados compactos
prltc grep "pattern" .            # Busqueda agrupada por archivo
```

### Git
```bash
prltc git status                  # Estado compacto
prltc git log -n 10               # Commits en una linea
prltc git diff                    # Diff condensado
prltc git push                    # -> "ok main"
```

### Tests
```bash
prltc test cargo test             # Solo fallos (-90%)
prltc vitest run                  # Vitest compacto
prltc pytest                      # Tests Python (-90%)
prltc go test                     # Tests Go (-90%)
```

### Build & Lint
```bash
prltc lint                        # ESLint agrupado por regla
prltc tsc                         # Errores TypeScript agrupados
prltc cargo build                 # Build Cargo (-80%)
prltc ruff check                  # Lint Python (-80%)
```

### Analiticas
```bash
prltc gain                        # Estadisticas de ahorro
prltc gain --graph                # Grafico ASCII (30 dias)
prltc discover                    # Descubrir ahorros perdidos
```

## Documentacion

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Resolver problemas comunes
- **[INSTALL.md](INSTALL.md)** - Guia de instalacion detallada
- **[ARCHITECTURE.md](docs/contributing/ARCHITECTURE.md)** - Arquitectura tecnica

## Contribuir

Las contribuciones son bienvenidas. Abre un issue o PR en [GitHub](https://github.com/ekjotsinghmakhija/prltc).

Unete a la comunidad en .

## Licencia

Licencia MIT - ver [LICENSE](LICENSE) para detalles.

## Descargo de responsabilidad

Ver [DISCLAIMER.md](DISCLAIMER.md).
