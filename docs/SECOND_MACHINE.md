# Second-machine checklist

Follow the project **[README](../README.md)** (sections 0–4). Condensed copy:

## Clone + restore

```bash
git clone git@github.com:laurieKell/blueMarine.git
cd blueMarine
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

- R 4.4.x recommended (matches `renv.lock`)
- Access to this **private** repo and GitHub installs of `flr/*` + `laurieKell/FLBacktest`
- Windows: Rtools if packages need compiling
- XeLaTeX only if compiling `tex/*.tex`

## Refresh the lock (working machine only)

```bash
Rscript scripts/setup_renv.R
```

Commit `renv.lock` afterward so other PCs can restore.
