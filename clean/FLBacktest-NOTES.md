# Candidates to move into FLBacktest

This pass **did not mass-move** functions. The live parent pipeline is
untouched. `clean/R/om.R` remains a stub over existing exports.

Installed FLBacktest already exports: `hcrICES`, `hcrParams`, `project_hcr`,
`years_to`, `load_om`, `require_om_gate`, `openloop_start`, `fwdFbar`,
`fwdFmsy`, `ltermEq`, `ltermPass`, `cleanStock`, `srResiduals`, `recDevs`,
`omIters`, `backtestResults`.

## Do **not** move (application)

| Current | Why |
|---------|-----|
| `R/paths.R` `data_root` / `clean_root` | Repo layout |
| `R/constants.R` `case_sids`, `case_labs` | Paper stock list |
| `R/constants.R` `hcr_tac_bounds` / `hcr_tac_bnd_when` | ICES advice-sheet TAC clause; already passed as `hcrICES(bndTac=, bndWhen=)` |
| `R/loadStocks.R` `loadFLStock` | `stocks.csv` columns (`rdata`, `object`, `end`) |
| `theme_paper` / `paper_cols` | Paper styling; ggplot2 `theme_bw` is enough |

## Move later (generic, small, already duplicated)

| Current location | Proposed name | Notes |
|------------------|---------------|--------|
| Parent `R/om.R` (stub) | already `load_om` etc. | **Done** in package; clean stub only |
| `scripts/main_traj_facet.R` `set_years` / `paste_hist` / `from_hcr` | `FLStock` splice helpers | Generic “overwrite years from another stock”; wait until a second app needs it |
| `04.1` rec/geom-mean residual construction | `recDevs()` | Package already has `recDevs`; notebook still inlines a one-liner — replace in a later knit, do not change parent 04.1 now |
| `05.0` / metrics `win_mean_F` | `windowMean(fbar, start, end)` | Tiny; three copies in clean scripts — optional |
| Parent `R/plot_theme.R` `shade_msy_status` | **drop** | ggplotFL-specific layer hacking |
| Parent `style_traj` / `share_facet_y` | **drop** | Not generic; not in this tree |

## ggplot vs FLCore

`FLCore::plot` exists for `FLStock` and `FLStocks` and returns **lattice**.
`FLCore::ggplot` **does not exist** in FLCore 2.6.32.9004. ggplot methods live
in **ggplotFL**. This clean tree uses FLCore lattice plots for diagnostics and
ggplot2 facets for the paper, without ggplotFL.

## One-file obvious exports (skipped this pass)

Nothing in parent `R/` is a one-file generic unused by the running pipeline
except the existing stubs. Moving `hcr_tac_bounds` into `hcrICES` defaults
would change package API; leave it as an application argument.
