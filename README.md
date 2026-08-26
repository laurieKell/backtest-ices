# backtest-ices

Historical backtest of ICES Category 1 advice for six Northeast Atlantic
stocks (Irish Sea cod and whiting; Celtic Sea cod, whiting and haddock;
Northeast Atlantic mackerel).

| | |
|--|--|
| **Repo** | https://github.com/laurieKell/backtest-ices |
| **Shared FLR engine** | [FLBacktest](https://github.com/laurieKell/FLBacktest) |
| **Sibling app** | [BIM-Resilience](https://github.com/laurieKell/BIM-Resilience) |

Formerly *blueMarine*. Follow **Virgin machine test** below on a clean PC.

---

## Virgin machine test

Do these steps **in order** from a shell, with working directory = the clone root.

### 1. Prerequisites

| Need | Notes |
|------|--------|
| **R** | **4.6.1** (must match `renv.lock`) |
| **Rtools** (Windows) | **Rtools45** — needed to compile FLR / TMB |
| **Git** | Access to this repo + `laurieKell/FLBacktest` + `flr/*` |
| **Network** | CRAN, GitHub, [stockassessment.org](https://www.stockassessment.org) (SAM step) |

In RStudio: set the R version to **4.6.1**, then open this project folder.

### 2. Clone

```bash
git clone https://github.com/laurieKell/backtest-ices.git
cd backtest-ices
```

(SSH: `git clone git@github.com:laurieKell/backtest-ices.git`)

### 3. Install packages

```bash
Rscript -e "install.packages('renv', repos = 'https://cloud.r-project.org')"
Rscript -e "renv::restore()"
```

First restore can take a long time (FLR + TMB compile).

If `renv::restore()` fails on FLR packages:

```r
install.packages(c("remotes", "devtools"), repos = "https://cloud.r-project.org")
remotes::install_github(c(
  "flr/FLCore@devel", "flr/FLBRP", "flr/FLasher", "flr/ggplotFL",
  "flr/icesdata", "flr/FLRebuild", "flr/FLfse",
  "laurieKell/FLBacktest",
  "fishfollower/SAM/stockassessment"
))
renv::restore()
```

### 4. Build SAM FLStocks

The repo ships only two FLStocks (Irish Sea cod, NEA mackerel).  
Build the four SAM stocks before the pipeline:

```bash
Rscript scripts/build_flstock_from_sam.R
```

Needs `stockassessment` and `FLfse`. Optional cache of raw fits:

```bash
Rscript scripts/build_flstock_from_sam.R --cache-fit
```

### 5. Smoke checks

```bash
Rscript scripts/run_pipeline.R --list
```

```r
source("R/paths.R")
stopifnot(nzchar(bm_root()))
stopifnot(file.exists(file.path(bm_root(), "data/reference/stocks.csv")))
stopifnot(file.exists(file.path(bm_root(), "data/WGCSE/cod.27.7a.RData")))
stopifnot(file.exists(file.path(bm_root(), "data/WGCSE/mac.27.nea.RData")))
stopifnot(file.exists(file.path(bm_root(), "data/WGCSE/had.27.7b-k.RData")))
stopifnot(requireNamespace("FLBacktest", quietly = TRUE))
stopifnot(requireNamespace("icesdata", quietly = TRUE))
message("Smoke OK")
```

### 6. Run the pipeline

```bash
# Default: OM → gate → open/closed → rebuild → digest → cases → report
Rscript scripts/run_pipeline.R

# Include screening as well
Rscript scripts/run_pipeline.R --all
```

Useful variants:

```bash
Rscript scripts/run_pipeline.R --only om
Rscript scripts/run_pipeline.R --from gate
Rscript scripts/run_pipeline.R --only report
```

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

`04.*` stops if the long-term OM gate fails (`require_om_gate()`).

After a successful run, open `Rmd/06.0_report.html`.

---

## What is / isn’t on GitHub

| On GitHub | Local only (gitignored) |
|-----------|-------------------------|
| `data/reference/`, `data/WGCSE/cod.27.7a.RData`, `data/WGCSE/mac.27.nea.RData` | `data/om/`, `data/results/`, `data/interim/`, `data/sdGraphs/`, `data/WGCSE/sam/`, SAM FLStocks |
| `R/`, `Rmd/`, `scripts/run_pipeline.R`, `scripts/setup_renv.R`, `scripts/build_flstock_from_sam.R` | Knitted `Rmd/*.html`, `Rmd/cache/` |
| `renv.lock` | `docs/`, `tex/` |

Knit order notes: [`Rmd/README.md`](Rmd/README.md).  
Supplement index: [`Rmd/00_supplement.Rmd`](Rmd/00_supplement.Rmd).

---

## Optional — LaTeX PDFs

`tex/` is local-only. Needs **XeLaTeX** and fonts under `tex/imperial/Fonts/` if present:

```bash
cd tex
xelatex paper.tex && bibtex paper && xelatex paper.tex && xelatex paper.tex
```

---

## Design rules (short)

- **Package = generic engine** ([FLBacktest](https://github.com/laurieKell/FLBacktest)).  
  **Application = data, conditioning, narrative** (this repo).
- Prefer package generics over local copies.
- Fail loud: knitr `error = FALSE`; do not wrap `fwd` / `hcrICES` in silent `try()`.

### Refreshing `renv.lock` (working machine only)

```bash
Rscript scripts/setup_renv.R
```

Commit the updated `renv.lock` so the next PC can `renv::restore()`.
