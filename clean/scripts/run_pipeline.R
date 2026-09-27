#!/usr/bin/env Rscript
# Knit the clean contract + paper chain. Data: clean/data.
# Notebooks and figures: this tree.
#
#   Rscript scripts/run_pipeline.R --list
#   Rscript scripts/run_pipeline.R              # om → … → paper
#   Rscript scripts/run_pipeline.R --from open
#   Rscript scripts/run_pipeline.R --only paper

# renv sandbox hides the user win-library (FLR, FLfse, stockassessment).
# Append only — prepending shadows renv tidyverse binaries (breaks ggplot2/vctrs).
user_lib <- file.path(Sys.getenv("LOCALAPPDATA", unset = ""),
                      "R", "win-library",
                      paste(R.version$major,
                            strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1],
                            sep = "."))
if (!nzchar(user_lib) || !dir.exists(user_lib))
  user_lib <- "C:/Users/lauri/AppData/Local/R/win-library/4.4"
if (dir.exists(user_lib) && !user_lib %in% .libPaths())
  .libPaths(c(.libPaths(), user_lib))

# Locate this script whether run via Rscript or source()'d (e.g. from RStudio).
.args_all <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args_all, value = TRUE)
.script_path <- if (length(.file_arg)) {
  normalizePath(sub("^--file=", "", .file_arg[[1]]), winslash = "/", mustWork = TRUE)
} else {
  .ofile <- NULL
  for (i in seq_len(sys.nframe())) {
    .f <- sys.frame(i)
    if (!is.null(.f$ofile)) {
      .ofile <- .f$ofile
      break
    }
  }
  if (!is.null(.ofile) && nzchar(.ofile)) {
    normalizePath(.ofile, winslash = "/", mustWork = TRUE)
  } else if (file.exists("scripts/run_pipeline.R")) {
    normalizePath("scripts/run_pipeline.R", winslash = "/", mustWork = TRUE)
  } else if (file.exists("clean/scripts/run_pipeline.R")) {
    normalizePath("clean/scripts/run_pipeline.R", winslash = "/", mustWork = TRUE)
  } else {
    stop("Cannot locate clean/scripts/run_pipeline.R. ",
         "Rscript it from clean/, or source() the full path.",
         call. = FALSE)
  }
}
script_dir <- dirname(.script_path)
clean_here <- dirname(script_dir)
source(file.path(clean_here, "R", "paths.R"))
here <- clean_root(start = c(clean_here, getwd()))
root <- data_root(start = c(clean_here, here))

args <- commandArgs(trailingOnly = TRUE)
# Funder default: om → … → paper (no shortcut / SAM).
# Optional OEM steps: --only shortcut | sam_fit | sam_loop | sam | sam_mc
steps <- c(
  "om",      # 01.0
  "gate",    # 01.1 + 01.2
  "open",    # 02.1
  "closed",  # 02.2 perfect info (bh3 default)
  "rebuild", # 02.5
  "digest",  # 03.0
  "paper",   # 04.0_paper_figures + main_traj_facet.R
  "review"   # 04.1 multi-SRR (peer review)
)
optional <- c("shortcut", "sam_fit", "sam_loop", "sam", "sam_mc") # 02.3 eqSimErr OEM; 02.4.1 SAM fit; 02.4.2 SAM loop; sam = both; 02.4.3 SAM iterations

from <- "om"
only <- NULL

if ("--list" %in% args) {
  message("Pipeline steps:\n  ", paste(steps, collapse = "\n  "))
  message("Optional (--only):\n  ", paste(optional, collapse = "\n  "))
  message("data_root:  ", root)
  message("clean_root: ", here)
  quit(save = "no", status = 0)
}
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
  path <- file.path(here, "Rmd", rmd)
  if (!file.exists(path))
    stop("Missing notebook: ", path, call. = FALSE)
  message("\n=== Knitting ", rmd, " ===")
  rmarkdown::render(path, quiet = FALSE, envir = new.env(parent = globalenv()))
  invisible(path)
}

run_step <- function(step) {
  switch(step,
    om      = render("01.0_condition_om.Rmd"),
    gate = {
      render("01.1_lterm_eq.Rmd")
      render("01.2_dynamics.Rmd")
    },
    open    = render("02.1_openLoop.Rmd"),
    closed  = render("02.2_closedLoop.Rmd"),
    rebuild = render("02.5_rebuild.Rmd"),
    digest  = render("03.0_digest.Rmd"),
    paper = {
      render("04.0_paper_figures.Rmd")
      message("=== advice_catch_casestudy.R ===")
      source(file.path(here, "scripts", "advice_catch_casestudy.R"),
             local = new.env(parent = globalenv()))
      message("=== main_traj_facet.R ===")
      # source() (not sys.source) so ofile is set for script-path discovery
      source(file.path(here, "scripts", "main_traj_facet.R"),
             local = new.env(parent = globalenv()))
    },
    review  = render("04.1_multiSRR_review.Rmd"),
    stop("Unknown step: ", step,
         "\nChoose from: ", paste(steps, collapse = ", "),
         call. = FALSE)
  )
}

if (!is.null(only)) {
  if (identical(only, "shortcut")) {
    render("02.3_closedLoop_shortcut.Rmd")
  } else if (identical(only, "sam_fit")) {
    render("02.4.1_sam.Rmd")
  } else if (identical(only, "sam_loop")) {
    render("02.4.2_closedLoop_sam.Rmd")
  } else if (identical(only, "sam_mc")) {
    render("02.4.3_closedLoop_sam_mc.Rmd")
  } else if (identical(only, "sam")) {
    render("02.4.1_sam.Rmd")
    render("02.4.2_closedLoop_sam.Rmd")
  } else if (!only %in% steps) {
    stop("--only must be one of: ",
         paste(c(steps, optional), collapse = ", "),
         call. = FALSE)
  } else {
    run_step(only)
  }
} else {
  if (!from %in% steps)
    stop("--from must be one of: ", paste(steps, collapse = ", "),
         call. = FALSE)
  todo <- steps[seq(match(from, steps), length(steps))]
  for (s in todo) run_step(s)
}

message("\nPipeline complete.")
message("Paper HTML: ", file.path(here, "Rmd", "04.0_paper_figures.html"))
message("LaTeX: cd ", file.path(here, "tex"), " && xelatex report.tex")
