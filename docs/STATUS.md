# Project status

**Phase:** finalisation — reproducible repo, package generics, deliverables.

**Last updated:** 25 August 2026.

## Workplan mapping

| Plan task | Status | Primary outputs |
|-----------|--------|-----------------|
| 1. Screening & reference projections | **Done** | `01_screening.Rmd`, `tex/backtest_screening.tex` |
| 2. Assessment reconstruction | Prototype | Optional `04.4` SAM OEM; full peels not base case |
| 3. Counterfactual simulation | **Done** (deterministic) | `02.0`–`04.3`; open + closed loop; Future rebuild |
| 4. Analysis & reporting | **Draft freeze** | `06.0` / `06.1` / `06.2`; `tex/{paper,exec_summary,beamer}.tex` |

## Pipeline

```
01_screening.Rmd       → data/results/01_screening.RData
02.0_condition_om.Rmd  → data/om/{oms,eqls,sag,recDevs}.RData
02.1_lterm_eq.Rmd      → data/results/03.3_lterm_eq.RData   [gate]
02.2_dynamics.Rmd      → data/results/03.0_om.RData          [gate]
04.1_openLoop.Rmd      → data/results/03.1_openLoop.RData
04.2_closedLoop.Rmd    → data/results/03.2_closedLoop.RData
04.3_rebuild.Rmd       → data/results/04.3_rebuild.RData
05.0_digest.Rmd        → all-stock terminal digest
06.1_TwoStocks.Rmd     → funder cases (whg.27.7a scn2; cod.27.7e-k scn0)
06.2_generic.Rmd       → remaining stocks, scn2
06.0_report.Rmd        → contract report (loads results only)
```

Driver: `scripts/run_pipeline.R`. Index: `Rmd/00_supplement.Rmd`.

## Package versions

| Package | Version | Role | GitHub |
|---------|---------|------|--------|
| FLBacktest | **0.1.5** | `hcrICES`, `openloop_start`, `ltermEq`, `project_hcr`, … | [laurieKell/FLBacktest](https://github.com/laurieKell/FLBacktest) |
| icesdata | 0.2.x | `eql`, `ftmb2`, `b0dyn`, `checkVariation`, `processError` | flr/icesdata |
| ggplotFL | current | `geom_flpar_lab`, `plot(FLStocks)` | flr/ggplotFL |

Production OM: `icesdata::eql`. Gate: `FLBacktest::ltermEq` / `ltermPass`.

## Deliverables checklist

- [x] Screening summary + PDF
- [x] Reproducible notebook pipeline + `run_pipeline.R`
- [x] Conditioned OMs (six stocks; six SRR + scn0–scn2)
- [x] Open-loop \(F_{\mathrm{target}}\) and closed-loop HCR
- [x] Future rebuild (`project_hcr` / `years_to`)
- [x] Contract report draft (`docs/report_draft.md`, `Rmd/06.0`, `tex/paper.tex`)
- [x] Executive summary (`tex/exec_summary.tex`)
- [x] Beamer (`tex/beamer.tex`)
- [x] Supplement index (`Rmd/00_supplement.Rmd`)
- [x] Peer-review outline (`docs/paper_outline.md`)
- [ ] Align `06.0` figures to scn2 (currently bh3 reference panels)
- [ ] Stochastic \(P(\mathrm{SSB}<B_{\lim})\)
- [ ] Contemporaneous SAM peels (optional robustness)

## Outstanding issues

| Issue | Severity | Mitigation |
|-------|----------|------------|
| Mackerel benchmark break | High | Flagged; candidate for removal from final funder pack |
| Closed-loop base case is perfect-info (`err = NULL`) | Medium | SAM OEM in `04.4` as sensitivity |
| `06.0` Future tables are bh3; `06.1`/`06.2` are scn2/scn0 | Medium | Captions state scenario; align when re-knitting report |
| SAG lacks historical survey inputs | Accepted | No full Task-2 peels in base case |

## What stays in blueMarine

`R/loadStocks.R`, `R/om.R` (`load_om`, `require_om_gate`), `R/plot_theme.R`,
`R/advice_sheets.R`. Stock-specific narrative in `06.1` / `06.2`.
