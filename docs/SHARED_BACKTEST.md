# Shared FLBacktest materials

This paper uses the common backtest stack from **FLBacktest**
(`C:/active/flr/backtest`). See package [`SHARED.md`](file:///C:/active/flr/backtest/SHARED.md).

| Layer | Location |
|-------|----------|
| Code | `library(FLBacktest)` — `hcrICES`, `backtest`, `shortcut`, … |
| Methods | `backtestMaterials("methods")` → `.tex`; vignette `methods-backtest` |
| Supp. Rmd | `backtestMaterials("rmd")` → conditioning / OEM / MP / performance |

**Do not** maintain a parallel local `hcrICES*.R` / `samIndices.R` once migrated.
Keep here: stock cleaning, SAG/refs, scenarios, figures, paper-specific metrics.
