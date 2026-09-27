# ICES Category 1 backtest — clean tree

A **new** code tree for (i) the funder contract and (ii) a peer-review paper.
It does **not** replace `C:\active\blueMarine`. Parent notebooks, `tex/`, and
`renv` stay as they are.

## Aims

1. Finish the funder contract (`tex/report.tex` + short-cut perfect-info HCR).
2. Support a peer-review paper (same chain + multi-SRR / OM \(F_{\mathrm{MSY}}\)).
3. Fail loud: knitr `error = FALSE` (stop the knit); missing objects `stop()`.
4. Generic methods live in **FLBacktest** (`hcrICES`, `fwdFbar`, `load_om`,
   `project_hcr`, `years_to`, …). See `FLBacktest-NOTES.md`.
5. Paper figures: `ggplot2` + `facet_*`. Diagnostic `FLStock` plots:
   `FLCore::plot` (lattice). **`FLCore` has no `ggplot` generic** on the
   installed 2.6.32.9004; do not load `ggplotFL` here.
6. Minimise helpers: no `style_traj` / `share_facet_y` / `theme_bluemarine`.

SAM-MP is two notebooks; short-cut OEM is
[`Rmd/02.3_closedLoop_shortcut.Rmd`](Rmd/02.3_closedLoop_shortcut.Rmd).
Neither is in the default funder knit.

1. [`Rmd/02.4.1_sam.Rmd`](Rmd/02.4.1_sam.Rmd) — OEM survey and one SAM fit
   per SAM stock, compared with the OM. Check this first.
2. [`Rmd/02.4.2_closedLoop_sam.Rmd`](Rmd/02.4.2_closedLoop_sam.Rmd) —
   `hcrICES` with that OEM; `BM_SAM_STAGE=loop` (default, **bh3**) or `srr`
   (all six SRRs).

Short-cut: `Rscript scripts/run_pipeline.R --only shortcut`
(`eqSimErr` SSB error). SAM: `--only sam_fit`, then `--only sam_loop`
(`--only sam` runs both).

## Paths

| Function | Points at |
|----------|-----------|
| `data_root()` | This folder (`clean/data/…`) |
| `clean_root()` | This folder |

Override with `ICES_BACKTEST_DATA` / `ICES_BACKTEST_CLEAN`. Knitting writes
`om`, `results` and `interim` under **`clean/data/`**, not the parent
`blueMarine/data/`. Seed inputs (`reference`, `WGCSE`, …) from the parent
once; thereafter the clean tree is self-contained. For paper figures only,
start at `--from paper` (loads existing `clean/data/results`).

## File map

```
clean/
  README.md
  FLBacktest-NOTES.md
  R/paths.R          data_root / clean_root → clean/data
  R/constants.R      case_sids, TAC bounds, theme_paper(), paper_cols
  R/om.R             thin wrappers → FLBacktest
  R/loadStocks.R     stocks.csv I/O
  data/              reference, WGCSE, om, results (local to clean/)
  Rmd/               contract + paper chain only
  scripts/run_pipeline.R
  scripts/advice_catch_casestudy.R   ASD vs SAG catch figure
  scripts/main_traj_facet.R          published traj_facet.pdf
  scripts/compute_openloop_metrics.R
  scripts/metrics_backtest_window.R
  tex/               report, manuscript, abstract, supplementary, refs
```

## Knit

From `clean/`, with FLBacktest + FLR installed (parent `renv` is fine):

```bash
Rscript scripts/run_pipeline.R --list
Rscript scripts/run_pipeline.R --from paper    # figures only
# Full re-run (overwrites clean/data/om and clean/data/results):
# Rscript scripts/run_pipeline.R
```

| Step | Notebook / script | Role |
|------|-------------------|------|
| om | `01.0_condition_om.Rmd` | Condition OMs, six SRRs |
| gate | `01.1_lterm_eq.Rmd`, `01.2_dynamics.Rmd` | `require_om_gate()` |
| open | `02.1_openLoop.Rmd` | ICES \(F_{\mathrm{tar}}\) + OM \(F_{\mathrm{MSY}}\) (six SRRs) |
| closed | `02.2_closedLoop.Rmd` | `hcrICES` perfect info from 2015 (**bh3**; `BM_CLOSED_SRR=all` for six) |
| rebuild | `02.5_rebuild.Rmd` | 20-year Future, `bh3` |
| digest | `03.0_digest.Rmd` | All-stock table |
| paper | `04.0_paper_figures.Rmd` + `advice_catch_casestudy.R` + `main_traj_facet.R` | Funder figures |
| review | `04.1_multiSRR_review.Rmd` | Peer-review SRR panel |
| `--only shortcut` | `02.3_closedLoop_shortcut.Rmd` | EqSim short-cut OEM |
| `--only sam_fit` | `02.4.1_sam.Rmd` | SAM fit to the OM (check before loop) |
| `--only sam_loop` | `02.4.2_closedLoop_sam.Rmd` | SAM closed loop |
| `--only sam` | both of the above | |

Funder draft stays **bh3** / perfect information. Multi-SRR open loop is always
run; multi-SRR closed loop needs `BM_CLOSED_SRR=all` before `closed` / `review`.

## Dropped from parent (on purpose)

Screening-of-six, `01.cod_*`, `06.1_TwoStocks`, `06.2_generic`,
`07_srr_*`, `06.0_report.Rmd` (replaced by
`04.0_paper_figures.Rmd`), `R/plot_theme.R` kitchen-sink, `si_*.R` plot
scripts, renv library, cache, beamer, Imperial letterhead, stale `paper.tex`.

## LaTeX

```bash
cd tex
xelatex report.tex && bibtex report && xelatex report.tex && xelatex report.tex
```

`report.tex` / `manuscript.tex` expect `figs/traj_facet.pdf` and
`figs/advice_catch_casestudy.pdf` under `clean/tex/figs/`. Both are written
by the paper pipeline step (`scripts/advice_catch_casestudy.R`,
`scripts/main_traj_facet.R`). Regenerate alone with:

```bash
Rscript scripts/advice_catch_casestudy.R   # needs ASD network + sag.RData
Rscript scripts/main_traj_facet.R
```
