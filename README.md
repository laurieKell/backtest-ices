# blueMarine

Historical backtest of ICES Category 1 advice for six Northeast Atlantic
stocks (Irish Sea cod and whiting; Celtic Sea cod, whiting and haddock;
Northeast Atlantic mackerel).

**Application repo:** case-study data, Operating Model conditioning, knitted
notebooks, and contract deliverables.  
**Generic engine:** [FLBacktest](https://github.com/laurieKell/FLBacktest)
(`hcrICES`, `fwdFbar`, `ltermEq`, `project_hcr`, `openloop_start`, …).

## Quick start

```bash
# Install FLR stack (once)
Rscript -e "remotes::install_github('laurieKell/FLBacktest')"
# Also need FLCore, FLBRP, FLasher, ggplotFL, icesdata (FLR / flr org)

# Knit the analysis chain (default starts at OM conditioning)
Rscript scripts/run_pipeline.R

# Full chain including screening
Rscript scripts/run_pipeline.R --all

# One step
Rscript scripts/run_pipeline.R --only gate
Rscript scripts/run_pipeline.R --list
```

Compile LaTeX from `tex/` with **XeLaTeX** (Imperial Sans fonts under
`tex/imperial/Fonts/`):

```bash
cd tex
xelatex paper.tex && bibtex paper && xelatex paper.tex && xelatex paper.tex
xelatex exec_summary.tex
xelatex beamer.tex
```

## Pipeline

| Step | Notebook | Writes |
|------|----------|--------|
| screening | `01_screening.Rmd` | `data/results/01_screening.RData` |
| om | `02.0_condition_om.Rmd` | `data/om/{oms,eqls,sag,recDevs}.RData` |
| gate | `02.1_lterm_eq.Rmd`, `02.2_dynamics.Rmd` | `03.3_lterm_eq.RData`, `03.0_om.RData` |
| open | `04.1_openLoop.Rmd` | `03.1_openLoop.RData` |
| closed | `04.2_closedLoop.Rmd` | `03.2_closedLoop.RData` |
| rebuild | `04.3_rebuild.Rmd` | `04.3_rebuild.RData` |
| digest | `05.0_digest.Rmd` | tables in HTML |
| cases | `06.1_TwoStocks.Rmd` | funder case studies |
| generic | `06.2_generic.Rmd` | remaining stocks (scn2) |
| report | `06.0_report.Rmd` | contract figures (loads results only) |

Knit order and notes: [`Rmd/README.md`](Rmd/README.md). Supplement index:
[`Rmd/00_supplement.Rmd`](Rmd/00_supplement.Rmd).  
`04.*` **stops** if the long-term OM gate fails (`require_om_gate()`).

## Layout

```
blueMarine/
├── data/
│   ├── reference/     # stocks.csv (canonical list)
│   ├── WGCSE/         # FLStock inputs
│   ├── om/            # Conditioned OMs from 02.0
│   ├── interim/       # Knit checkpoints (gitignored)
│   └── results/       # Notebook deliverables (gitignored; re-knit)
├── R/                 # App I/O only (loadStocks, om gate, plot theme)
├── Rmd/               # Methods notebooks = supplementary material
├── scripts/           # run_pipeline.R
├── tex/               # paper, exec_summary, beamer, screening
└── docs/              # STATUS, DATA, report draft, paper outline
```

Archival copies live under `backUp/` (not part of the runnable pipeline).

## Deliverables

| Item | Location |
|------|----------|
| Technical report (HTML) | `Rmd/06.0_report.Rmd` → `06.0_report.html` |
| Working paper (LaTeX) | `tex/paper.tex` |
| Executive summary | `tex/exec_summary.tex` |
| Beamer briefing | `tex/beamer.tex` |
| Supplement | `Rmd/00_supplement.Rmd` + knit chain |
| Report draft (markdown) | `docs/report_draft.md` |
| Peer-review outline | `docs/paper_outline.md` |

## Design rule

**Package = generic engine. Application = data, conditioning, narrative.**  
Do not re-implement `hcrICES` / `ltermEq` / `geom_flpar_lab` here. See
[`docs/FLR_methods.md`](docs/FLR_methods.md) and
[`docs/app_vs_package.md`](docs/app_vs_package.md).

Failed projections stop the notebook (`error = FALSE` in knitr;
`FLBacktest::backtest(..., tryIt = FALSE)`).
