# Notebooks (clean tree)

Contract + paper chain only. Knit with `scripts/run_pipeline.R` from `clean/`.

| Order | File | Writes (under **clean/data/**) |
|-------|------|--------------------------------|
| 1 | `01.0_condition_om.Rmd` | `data/om/oms.RData`, `eqls.RData`, `sag.RData` |
| 2 | `01.1_lterm_eq.Rmd` | `data/results/01.1_lterm_eq.RData` |
| 3 | `01.2_dynamics.Rmd` | `data/results/01.2_dynamics.RData` (+ `data/interim/01.2_dynamics/`) |
| 4 | `02.1_openLoop.Rmd` | `data/results/02.1_openLoop.RData` |
| 5 | `02.2_closedLoop.Rmd` | `data/results/02.2_closedLoop.RData` (perfect info; **bh3** default) |
| 6 | `02.3_closedLoop_shortcut.Rmd` | `data/results/02.3_closedLoop_shortcut.RData` (`--only shortcut`) |
| 7a | `02.4.1_sam.Rmd` | `data/results/02.4.1_sam.RData` (`--only sam_fit`) |
| 7b | `02.4.2_closedLoop_sam.Rmd` | `data/results/02.4.2_closedLoop_sam.RData` (`--only sam_loop`; needs 7a) |
| 8 | `02.5_rebuild.Rmd` | `data/results/02.5_rebuild.RData` |
| 9 | `03.0_digest.Rmd` | `data/results/03.0_digest.RData` |
| 10 | `04.0_paper_figures.Rmd` | figures under `clean/tex/figs/` (+ `advice_catch_casestudy.R`, `main_traj_facet.R` in pipeline `paper` step) |
| 11 | `04.1_multiSRR_review.Rmd` | `data/results/04.1_multiSRR_review.RData` (optional peer-review) |

Result `.RData` stems match the notebook stem. HTML and knitr cache go under
`clean/`. Index: `00_supplement.Rmd` (funder = perfect-info `02.2`; peer-review
closed loop = `02.4.1` / `02.4.2` SAM; short-cut = `02.3`).
