# Finish package install for R 4.6.1 (run with R 4.6.1 Rscript --vanilla)
options(
  repos = c(
    CRAN = "https://cloud.r-project.org",
    FLR = "https://flr.r-universe.dev"
  ),
  Ncpus = max(1L, parallel::detectCores() - 1L),
  pkgType = "both"
)

lib <- "C:/active/blueMarine/renv/library/windows/R-4.6/x86_64-w64-mingw32"
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
Sys.setenv(RENV_CONFIG_SYNCHRONIZED_CHECK = "FALSE")

message("R: ", R.version.string)
message("lib: ", lib)

if (!requireNamespace("renv", quietly = TRUE))
  install.packages("renv")
library(renv)

needed <- c(
  "reshape2", "doParallel", "foreach", "ggh4x", "jsonlite", "kableExtra",
  "knitr", "rmarkdown", "openxlsx", "yaml", "dplyr", "plyr", "scales",
  "ggplot2", "ggrepel", "patchwork", "cowplot", "gridExtra", "data.table",
  "TMB", "Rcpp", "RcppEigen", "remotes", "devtools", "pak", "testthat",
  "iterators", "RColorBrewer", "viridisLite", "labeling", "farver",
  "isoband", "withr", "lifecycle", "rlang", "cli", "glue", "vctrs",
  "magrittr", "tibble", "tidyselect", "pillar", "stringr", "stringi"
)

message("\n=== renv::install needed CRAN packages ===")
renv::install(needed, prompt = FALSE)

message("\n=== GitHub / FLR packages ===")
if (!requireNamespace("remotes", quietly = TRUE))
  renv::install("remotes", prompt = FALSE)

gh <- c(
  "flr/FLCore@devel",
  "flr/FLBRP",
  "flr/FLasher",
  "flr/ggplotFL",
  "flr/FLRebuild",
  "flr/icesdata",
  "laurieKell/FLBacktest"
)
for (pkg in gh) {
  message("-> ", pkg)
  tryCatch(
    remotes::install_github(pkg, upgrade = "never", quiet = FALSE),
    error = function(e) message("FAILED ", pkg, ": ", conditionMessage(e))
  )
}

message("\n=== FLFishery from r-universe ===")
tryCatch(
  install.packages("FLFishery", repos = "https://flr.r-universe.dev"),
  error = function(e) message("FLFishery failed: ", conditionMessage(e))
)

message("\n=== Snapshot ===")
# Avoid broken Rmd breaking dependency discovery
Sys.setenv(RENV_PATHS_LIBRARY = lib)
tryCatch(
  renv::snapshot(type = "all", prompt = FALSE, force = TRUE),
  error = function(e) message("snapshot error: ", conditionMessage(e))
)

message("\n=== Check ===")
pkgs <- c(
  "FLCore", "FLBRP", "FLasher", "FLBacktest", "ggplotFL", "FLRebuild",
  "ggh4x", "icesdata", "reshape2", "knitr", "ggplot2", "TMB"
)
for (p in pkgs)
  message(sprintf("%-12s %s", p, requireNamespace(p, quietly = TRUE)))
message("n pkgs: ", length(list.files(lib)))
message("Done.")
