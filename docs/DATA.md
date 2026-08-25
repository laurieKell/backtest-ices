# Pipeline data layout

## Directories

| Path | Role |
|------|------|
| `data/reference/` | Static inputs. **`stocks.csv`** is the single stock list (`sid`, `name`, `rdata`, `object`, area, advice year). |
| `data/WGCSE/` | Local `FLStock` `.RData` inputs (+ optional `sam/` fits). |
| `data/om/` | **Conditioned Operating Models** from `02.0`: `oms.RData`, `eqls.RData`, `sag.RData`, `recDevs.RData`. |
| `data/interim/` | Knit checkpoints (`03.0_om/`, advice PDF text, SAG cache). Gitignored. |
| `data/results/` | Notebook deliverables. Gitignored — regenerate with `scripts/run_pipeline.R`. |
| `tex/figs/` | Knitr figures for the LaTeX report. |

## Results deliverables (pipeline order)

| File | Notebook | Main objects |
|------|----------|--------------|
| `01_screening.RData` | `01_screening.Rmd` | `screening` |
| `data/om/*.RData` | `02.0_condition_om.Rmd` | `oms`, `eqls`, `sag`, `recDevs` |
| `03.3_lterm_eq.RData` | `02.1_lterm_eq.Rmd` | `lterm_eq` (gate) |
| `03.0_om.RData` | `02.2_dynamics.Rmd` | dynamics / realised status |
| `03.1_openLoop.RData` | `04.1_openLoop.Rmd` | `openLoop` (six SRR branches) |
| `03.2_closedLoop.RData` | `04.2_closedLoop.Rmd` | `closedLoop` |
| `04.3_rebuild.RData` | `04.3_rebuild.Rmd` | Future window (`project_hcr`) |
| `04.4_closedLoop_sam.RData` | `04.4_closedLoop_sam.Rmd` | optional SAM OEM |

`06.0_report.Rmd` **loads** `data/om` and `data/results` only; it does not re-run simulations.

## Reproducing without a full re-knit

1. Keep `data/reference/stocks.csv` and `data/WGCSE/*.RData` (committed).
2. Knit `02.0` → populates `data/om/` (small; useful to commit once for report-only builds).
3. Run `Rscript scripts/run_pipeline.R --from gate` for gate → report.

See [`STATUS.md`](STATUS.md) and [`Rmd/README.md`](../Rmd/README.md).
