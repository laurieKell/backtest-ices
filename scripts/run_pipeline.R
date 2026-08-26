#!/usr/bin/env Rscript
# Knit the blueMarine analysis chain in dependency order.
# Notebook index: Rmd/README.md and Rmd/00_supplement.Rmd
#
# Usage (from repo root or anywhere):
#   Rscript scripts/run_pipeline.R              # gate → backtest → report
#   Rscript scripts/run_pipeline.R --all        # include screening
#   Rscript scripts/run_pipeline.R --from gate  # from named step
#   Rscript scripts/run_pipeline.R --only open  # one step
#   Rscript scripts/run_pipeline.R --list

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/run_pipeline.R")) {
  normalizePath("scripts", winslash = "/")
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(dirname(script_dir), "R", "paths.R"))
root <- bm_root(start = c(getwd(), dirname(script_dir)))

# Logical pipeline (matches Rmd/README.md)
steps <- c(
  "screening", # 01
  "om",        # 02.0
  "gate",      # 02.1 + 02.2 (hard stop for 04.*)
  "open",      # 04.1
  "closed",    # 04.2
  "rebuild",   # 04.3
  "digest",    # 05.0
  "cases",     # 06.1
  "generic",   # 06.2
  "report"     # 06.0 (loads results only)
)

# Default: skip screening (already done) and start at OM
from <- "om"
only <- NULL

if ("--list" %in% args) {
  message("Pipeline steps:\n  ", paste(steps, collapse = "\n  "))
  quit(save = "no", status = 0)
}
if ("--all" %in% args) from <- "screening"
if ("--from" %in% args) {
  i <- match("--from", args)
  if (i < length(args)) from <- args[[i + 1L]]
}
if ("--only" %in% args) {
  i <- match("--only", args)
  if (i < length(args)) only <- args[[i + 1L]]
}

if (!requireNamespace("rmarkdown", quietly = TRUE))
  stop("Install rmarkdown to knit notebooks.", call. = FALSE)

render <- function(rmd) {
  path <- file.path(root, "Rmd", rmd)
  if (!file.exists(path))
    stop("Missing notebook: ", path, call. = FALSE)
  message("\n=== Knitting ", rmd, " ===")
  ok <- tryCatch({
    rmarkdown::render(path, quiet = FALSE, envir = new.env(parent = globalenv()))
    TRUE
  }, error = function(e) {
    message("FAILED: ", rmd, "\n", conditionMessage(e))
    stop("Pipeline stopped at ", rmd, ": ", conditionMessage(e), call. = FALSE)
  })
  invisible(path)
}

run_step <- function(step) {
  switch(step,
    screening = render("01_screening.Rmd"),
    om        = render("02.0_condition_om.Rmd"),
    gate = {
      render("02.1_lterm_eq.Rmd")
      render("02.2_dynamics.Rmd")
    },
    open    = render("04.1_openLoop.Rmd"),
    closed  = render("04.2_closedLoop.Rmd"),
    rebuild = render("04.3_rebuild.Rmd"),
    digest  = render("05.0_digest.Rmd"),
    cases   = render("06.1_TwoStocks.Rmd"),
    generic = render("06.2_generic.Rmd"),
    report  = render("06.0_report.Rmd"),
    stop("Unknown step: ", step,
         "\nChoose from: ", paste(steps, collapse = ", "),
         call. = FALSE)
  )
}

if (!is.null(only)) {
  if (!only %in% steps)
    stop("--only must be one of: ", paste(steps, collapse = ", "),
         call. = FALSE)
  run_step(only)
} else {
  if (!from %in% steps)
    stop("--from must be one of: ", paste(steps, collapse = ", "),
         call. = FALSE)
  todo <- steps[seq(match(from, steps), length(steps))]
  for (s in todo) run_step(s)
}

message("\nPipeline complete.")
message("Contract report HTML: Rmd/06.0_report.html")
message("LaTeX: cd tex && xelatex paper.tex && bibtex paper && xelatex paper.tex")
