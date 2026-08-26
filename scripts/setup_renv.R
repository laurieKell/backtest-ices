#!/usr/bin/env Rscript
# Snapshot the current R library into renv.lock (no mass reinstall).
# Run once on the machine where the pipeline already works.
# renv 1.0.7: renv::record(list(Pkg = "user/repo")) works;
# string forms like "Pkg@github::user/repo" do not.
if (!requireNamespace("renv", quietly = TRUE))
  stop("Install renv: install.packages('renv')", call. = FALSE)

root <- normalizePath(".", winslash = "/")
if (!file.exists(file.path(root, "renv.lock")))
  renv::init(bare = TRUE, restart = FALSE)

# Explicit GitHub remotes for packages that may lack Remote* metadata when installed locally
github <- list(
  FLCore     = "flr/FLCore@devel",
  FLBRP      = "flr/FLBRP",
  FLasher    = "flr/FLasher",
  ggplotFL   = "flr/ggplotFL",
  FLBacktest = "laurieKell/FLBacktest",
  icesdata   = "flr/icesdata",
  FLRebuild  = "flr/FLRebuild"
)

deps <- unique(c(
  unlist(renv::dependencies(file.path(root, "Rmd"), quiet = TRUE)$Package),
  unlist(renv::dependencies(file.path(root, "scripts"), quiet = TRUE)$Package),
  unlist(renv::dependencies(file.path(root, "R"), quiet = TRUE)$Package),
  names(github),
  "rmarkdown", "knitr", "plyr", "ggplot2", "patchwork", "openxlsx",
  "doParallel", "foreach", "reshape2", "data.table", "jsonlite",
  "kableExtra", "devtools", "remotes"
))
deps <- deps[!is.na(deps) & nzchar(deps)]

# Snapshot from library first, then re-apply GitHub remotes so packages
# installed without Remote* metadata are not left as Source: unknown.
renv::snapshot(packages = deps, prompt = FALSE, force = TRUE)
renv::record(github)
message("Wrote ", file.path(root, "renv.lock"), " (renv ", packageVersion("renv"), ")")