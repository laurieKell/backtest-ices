# backtest-ices

Historical backtest of ICES Category 1 advice for six Northeast Atlantic
stocks (Irish Sea cod and whiting; Celtic Sea cod, whiting and haddock;
Northeast Atlantic mackerel).

| | |
|--|--|
| **Repo** | https://github.com/laurieKell/backtest-ices |
| **Shared FLR engine** | [FLBacktest](https://github.com/laurieKell/FLBacktest) |
| **Sibling app** | [BIM-Resilience](https://github.com/laurieKell/BIM-Resilience) |

Formerly *blueMarine*. This README is the checklist for **installing and re-running on a new PC**.

---

## 0. Prerequisites

| Need | Notes |
|------|--------|
| **R** | **4.6.1** (matches `renv.lock`; project library under `renv/library/.../R-4.6/`) |
| **Git** | SSH or HTTPS access to this repo and to `laurieKell/FLBacktest` |
| **Rtools** (Windows) | **Rtools45** (works with R 4.6.x) to compile FLR / TMB packages |
| **Network** | CRAN + GitHub (`flr/*`, `laurieKell/FLBacktest`) |
| **Optional** | XeLaTeX + Imperial fonts under `tex/imperial/Fonts/` — only for PDF / Beamer |

---

## 1. Clone

```bash
git clone git@github.com:laurieKell/backtest-ices.git
cd backtest-ices
```

HTTPS:

```bash
git clone https://github.com/laurieKell/backtest-ices.git
cd backtest-ices
```

Open the project at this folder (the one with `README.md` / `renv.lock`).

---

## 2. Install R packages (renv)

From the **project root**:

```bash
Rscript -e "install.packages('renv', repos = 'https://cloud.r-project.org')"
Rscript -e "renv::restore()"
```

Or in R:

```r
install.packages("renv", repos = "https://cloud.r-project.org")
renv::restore()
```

`renv::restore()` installs everything in `renv.lock` (CRAN + GitHub FLR packages,
including FLBacktest). First restore can take a long time.

### If restore fails

Install the FLR stack by hand, then retry:

```r
install.packages(c("remotes", "devtools"), repos = "https://cloud.r-project.org")
remotes::install_github(c(
  "flr/FLCore@devel", "flr/FLBRP", "flr/FLasher", "flr/ggplotFL",
  "flr/icesdata", "flr/FLRebuild",
  "laurieKell/FLBacktest"
))
# then:
renv::restore()
```

---

## 3. Smoke test

From the **project root**:

```bash
Rscript scripts/run_pipeline.R --list
```

In R:

```r
source("R/paths.R")
bm_root()                              # should print this clone’s path
file.exists(file.path(bm_root(), "data/reference/stocks.csv"))
file.exists(file.path(bm_root(), "data/om/oms.RData"))
library(FLBacktest)
library(icesdata)
```

If `bm_root()` fails, set the working directory to the repo root (or knit from `Rmd/`).

---

## 4. Re-run the analysis

`data/results/` is **gitignored** — you must knit (or run the pipeline) to rebuild it.
`data/WGCSE/` and `data/om/` are in the repo so you can start from OM conditioning
or from the gate without re-downloading assessments.

### Full pipeline (recommended)

```bash
# Default: OM → gate → open/closed loop → rebuild → digest → cases → report
Rscript scripts/run_pipeline.R

# Include screening from the start
Rscript scripts/run_pipeline.R --all

# One step or from a named step
Rscript scripts/run_pipeline.R --only gate
Rscript scripts/run_pipeline.R --from closed
Rscript scripts/run_pipeline.R --list
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

`04.*` **stops** if the long-term OM gate fails (`require_om_gate()`).

Knit order and notes: [`Rmd/README.md`](Rmd/README.md).  
Supplement index: [`Rmd/00_supplement.Rmd`](Rmd/00_supplement.Rmd).

### Report-only (after results exist)

```bash
Rscript scripts/run_pipeline.R --only report
```

Or open `Rmd/06.0_report.Rmd` and Knit (working directory = project root or `Rmd/`).

---

## 5. Optional — LaTeX PDFs

Needs **XeLaTeX** and fonts under `tex/imperial/Fonts/`:

```bash
cd tex
xelatex paper.tex && bibtex paper && xelatex paper.tex && xelatex paper.tex
xelatex exec_summary.tex
xelatex beamer.tex
```

---

## 6. What is / isn’t on GitHub

| On GitHub | Local only (gitignored) |
|-----------|-------------------------|
| `data/reference/`, `data/WGCSE/`, `data/om/` | `data/results/`, `data/interim/` |
| `R/`, `Rmd/`, `scripts/`, `tex/` sources | Knitted `Rmd/*.html`, `Rmd/cache/` |
| `renv.lock` | `docs/` (status notes, drafts, advice PDFs, literature) |
| | `backUp/` |

---

## 7. Deliverables (after a successful run)

| Item | Location |
|------|----------|
| Contract report (HTML) | `Rmd/06.0_report.html` |
| Working paper | `tex/paper.tex` → PDF |
| Executive summary | `tex/exec_summary.tex` |
| Beamer | `tex/beamer.tex` |
| Supplement | `Rmd/00_supplement.Rmd` + knit chain |

Draft markdown / status notes under local `docs/` are not published with the repo.

---

## Design rules (short)

- **Package = generic engine** ([FLBacktest](https://github.com/laurieKell/FLBacktest)).  
  **Application = data, conditioning, narrative** (this repo).
- Prefer package generics (`hcrICES`, `ltermEq`, `openloop_start`, `geom_flpar_lab`, …) over local copies.
- Fail loud: knitr `error = FALSE`; do not wrap `fwd` / `hcrICES` in silent `try()`.

### Refreshing `renv.lock` (on a machine that already works)

```bash
Rscript scripts/setup_renv.R
```

Then commit the updated `renv.lock` so the next PC can `renv::restore()`.
