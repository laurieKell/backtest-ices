# Second-machine checklist

Follow the project **[README](../README.md)** (sections 0–4). Condensed copy:

## Clone + restore

```bash
git clone git@github.com:laurieKell/backtest-ices.git
cd backtest-ices
Rscript -e "install.packages('renv', repos='https://cloud.r-project.org')"
Rscript -e "renv::restore()"
```

## Smoke test + pipeline

```bash
Rscript scripts/run_pipeline.R --list
Rscript scripts/run_pipeline.R          # om → report
# Rscript scripts/run_pipeline.R --all  # include screening
```

## Requirements

- R **4.6.1** (matches `renv.lock`) + Rtools45 on Windows
- Access to this repo and GitHub installs of `flr/*` + `laurieKell/FLBacktest`
- XeLaTeX only if compiling `tex/*.tex`

## Refresh the lock (working machine only)

```bash
Rscript scripts/setup_renv.R
```

Commit `renv.lock` afterward so other PCs can restore.
