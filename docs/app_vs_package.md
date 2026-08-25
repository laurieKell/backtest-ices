# blueMarine application vs FLBacktest package

**Project phase (2026):** screening complete; pipeline scaffolded. Remaining
work is running `01`–`06`, validation, and report drafting — see
[`STATUS.md`](STATUS.md).

Comparison after the Celtic Sea cod worked example, checked against
`C:/active/shortcut-full/erp_clean`.

## What lives where

| Concern | **FLBacktest** (`C:/active/flr/backtest`) | **blueMarine** (this project) |
|---------|-------------------------------------------|-------------------------------|
| ICES hockey-stick HCR loop | `hcrICES()` | Call it |
| Scenario grid MSE | `runMSE()` | Build `scen` / `omIters` / `eqs` |
| Trajectory summary | `backtestResults()` | Plot / tables for report |
| Short-cut assessment error | `shortCutErr()` | Supply bias series from retros |
| Stock cleaning for `fwd` | `cleanStock()` | Call it |
| Open-loop start year | `openloop_start()` | Call it |
| SRR / FLBRP conditioning | — | `icesdata::eql` + `addBenchmark` in `02.0` |
| Official refs (Fmsy, Blim, MSYBtrigger) | `hcrParams()` | SAG row → `FLPar` |
| F-target benchmark projection | `fwdFbar()` / `fwdFmsy()` | `04.1` historical `years`; `02.1` `nyears` ahead |
| Perfect-info HCR rebuild | `project_hcr()` / `years_to()` | Knit `04.3`; Table B in `06.0` |
| FLPar labels on plots | **ggplotFL** `geom_flpar_lab()` | Call it in `06.0` |
| Long-term `fwd` vs FLBRP | `ltermEq()` | Knit `02.1` (gate) / compact table in `02.2` |
| SAG extract & advice–TAC mismatch | — | screening notebooks |
| Stock file I/O | — | `R/loadStocks.R` (`loadFLStock`; stocks.csv) |
| Methods / supp. text | vignette + `inst/methods/*.tex` + `inst/rmd/*.Rmd` | Case-study Methods only |
| Locate shared files | `backtestMaterials()` | — |

## Design rule

**Package = generic engine.**  
**Application = data, conditioning, case studies, contract deliverables.**

Do **not** put stock-specific cleaning, SAG parsing, or report narrative into
`FLBacktest`. Do **not** re-implement `hcrICES` / `runMSE` / `fwdFbar` in
blueMarine.

The same rule applies to the sibling app
[BIM-Resilience](https://github.com/laurieKell/BIM-Resilience): TAC scenario
labels stay in the app; constant-\(F\) projection uses `fwdFbar`.

## SRR / TMB: `icesdata` vs `FLRebuild`

Both packages used to export `ftmb` / `ftmb2`. The TMB templates are **not**
the same: FLRebuild’s DLL has `use_b0` / `b0yr`; icesdata’s does not.
Public names are now:

| Function | Package | Role |
|----------|---------|------|
| `ftmb` | **icesdata** | TMB SRR, year-varying SPR0 |
| `ftmb2` | **icesdata** | TMB SRR, scalar / mean SPR0; used by `eql()` |
| `ftmb3` | **icesdata** | iterates `ftmb2` when the FLSR has iters |
| `eql` / `eqlFn` | **icesdata** | FLBRP from `ftmb2` / `ftmb` |
| `b0dyn` | **icesdata** | dynamic B0 from `FLStock` + prior `FLSR` |
| `ftmb_b0dyn` | **FLRebuild** | TMB SRR with year-specific \(v_t\) |

FLRebuild still compiles a private `ftmb2` for its own DLL; it is **not
exported**. Notebooks attach icesdata after FLRebuild so `eql` / `ftmb`
resolve to icesdata. FLasher is attached last so `fwd()` is not masked.

blueMarine production OM (`eqlsFn`) calls `icesdata::eql` (`ftmb2`).
Dynamic \(B_0\) in `02.0` is `rec * spr0Yr` — no SRR, not `ftmb_b0dyn`.

## Lessons from the Celtic Sea cod example

1. **FLBRP without a scaled SRR** (`rec ~ a` with `a = 1`) gives nonsense Bmsy.
   Application must fit `geomean` / BH (or inject SAG refs) before calling the package.
2. **Incomplete discard/landings slots** break FLasher inside `hcrICES`.
   Application must `clean_stock()` first.
3. **`err = NULL`** is perfect information (true OM status and STF with
   recruitment deviations). An `FLQuant` or `FLIndex` is the OEM; do not pass
   `perfect`.
4. **Benchmark at target F** is a simple FLasher projection — keep it in the app;
   closed-loop advice belongs in `hcrICES`.

## Verification vs erp_clean

| erp_clean pattern | blueMarine |
|-------------------|------------|
| `01_MSE.Rmd` computes & `save()`s | `01`–`06` write `data/results/*.RData` |
| `02_paper.Rmd` loads & plots | `06.0_report.Rmd` loads & plots |
| Sources local `hcrICESV4Sam.R` | Loads packaged `FLBacktest` |
| `par` from `refs` FLQuants | `hcrPar()` in `04.2_closedLoop.Rmd` |
| `omIters` / `eqs` / `sr_deviances` | Single-stock for now; `runMSE` when multi-OM |
| `Fig` / `Tab` captions | Same in report Rmds |
| `fig.path` under `output/figs` | `tex/figs/` |

**Verdict:** Structure matches erp_clean. The main upgrade is using the
**packaged** HCR instead of a copied `source/` script. Application code that
remains (and should remain) is everything erp_clean did outside `hcrICES`:
OM build, refs, plotting, and paper assembly.

## Suggested next package improvements (upstream)

- `icesdata::fwdFmsy` delegates to `FLBacktest::fwdFbar` when `sr` is supplied;
  prefer `FLBacktest::fwdFmsy(stock, eql, years = ...)`
- Document expected `FLPar` names: `ftar`, `fmin`, `btrig`, `bmin`, `blim`
- Performance statistics (`aav`) still live in `05.1` — move when the
  metrics tables are turned on
