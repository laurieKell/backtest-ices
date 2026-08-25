# Generic FLR methods (verifiable)

Application notebooks call **package generics**, not local copies.
Knitr `error = FALSE` so a failed chunk stops the notebook.
`FLBacktest::backtest(..., tryIt = FALSE)` is the default: a failed stock
stops the run. `fwdFbar` does not wrap `FLasher::fwd` in `tryCatch`.

## Generics and where they are tested

| Generic | Package | Tests | Used in |
|---------|---------|-------|---------|
| `cleanStock` | FLBacktest | `tests/testthat/test-condition.R` | 02.0 |
| `openloop_start` | FLBacktest | conditioning helpers | 04.1, 06.* |
| `fwdFbar`, `fwdFmsy` | FLBacktest | `test-condition.R` | 02.1 via `ltermEq` |
| `ltermEq`, `ltermPass` | FLBacktest | `test-condition.R` | 02.1 gate |
| `srResiduals`, `recDevs` | FLBacktest | helpers | 02.0, 04.1, 04.2 |
| `fwd` at \(F_{\mathrm{target}}\) | FLasher | FLasher | 04.1 |
| `hcrICES`, `hcrParams` | FLBacktest | `test-hcrICES.R`, `test-shortcut.R` | 04.2 |
| `backtest` | FLBacktest | `test-condition.R` (`tryIt` default) | scenario grids |
| `project_hcr`, `years_to` | FLBacktest | `test-rebuild.R` | 04.3, 06.* Future |
| `eql`, `addBenchmark`, `b0dyn` | icesdata | icesdata | 02.0, 06.1 |
| `checkVariation`, `processError`, `covarFn`, `abi` | icesdata | icesdata | 02.2 |
| `plot`, `geom_flpar_lab` | ggplotFL | ggplotFL | 04–06 |
| `samIndex`, `hcrICES` with `FLIndex` | FLBacktest + FLfse | SAM tests | **04.4 only** |

## How to verify

From `C:/active/flr/backtest`:

```r
devtools::test()
```

From this repo, a stock must fail loudly:

1. Knit `02.1` / `02.2`. If `lterm_eq$pass$pass` is FALSE,
   `require_om_gate()` in `04.1` / `04.2` / `04.3` / `05.0` / `06.1` stops.
2. Do not wrap `fwd` / `hcrICES` / `processError` in `try(..., silent = TRUE)`.
3. Methods text for papers: FLBacktest vignette
   `vignettes/methods-backtest.Rmd`.

## What stays in blueMarine

`R/loadStocks.R` (stocks.csv I/O), `R/plot_theme.R`, `R/om.R`
(`load_om`, `require_om_gate`), `R/advice_sheets.R`. Stock-specific narrative
lives in `06.1` / `06.2`, not in the generic runner.

Sibling application using the same FLBacktest engine:
[BIM-Resilience](https://github.com/laurieKell/BIM-Resilience)
(TAC productivity scenarios; see that repo’s `docs/app_vs_package.md`).

## Empirical productivity (not climate)

Historical `fwd` / `hcrICES` replay assessment life history and recruitment
residuals [@Trochta2026mseeco; after @punt2014mseclimate]. Variance split of
dynamic \(B_0\): [@Lindmark2026productivity].
