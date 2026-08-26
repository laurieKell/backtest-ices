#!/usr/bin/env Rscript
# Download SAM fits from stockassessment.org and write FLStock .RData
# into data/WGCSE/ using names from data/reference/stocks.csv.
#
# Usage (from repo root):
#   Rscript scripts/build_flstock_from_sam.R
#   Rscript scripts/build_flstock_from_sam.R --sid whg.27.7a
#   Rscript scripts/build_flstock_from_sam.R --cache-fit   # also save fit under data/WGCSE/sam/
#
# Requires: stockassessment, FLfse, FLCore (and remotes to install if missing).
# Non-SAM stocks (empty sam_web) are skipped — keep those FLStocks by hand.

args <- commandArgs(trailingOnly = TRUE)
only_sid <- {
  i <- match("--sid", args)
  if (!is.na(i) && i < length(args)) args[[i + 1L]] else NULL
}
cache_fit <- "--cache-fit" %in% args

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/build_flstock_from_sam.R")) {
  normalizePath("scripts", winslash = "/")
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(dirname(script_dir), "R", "paths.R"))
root <- bm_root(start = c(getwd(), dirname(script_dir)))

need <- c("stockassessment", "FLfse", "FLCore")
miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) {
  stop(
    "Missing packages: ", paste(miss, collapse = ", "), "\n",
    "Install e.g.\n",
    "  remotes::install_github(c('fishfollower/SAM/stockassessment', 'flr/FLfse'))\n",
    "  install.packages('FLCore')  # or flr/FLCore@devel\n",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(FLCore)
  library(FLfse)
  library(stockassessment)
})

stocks <- read.csv(
  file.path(root, "data/reference/stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA")
)
if (!"sam_web" %in% names(stocks))
  stop("stocks.csv needs a sam_web column (stockassessment.org key).", call. = FALSE)

sam_rows <- stocks[
  !is.na(stocks$sam_web) & nzchar(as.character(stocks$sam_web)),
  ,
  drop = FALSE
]
if (!is.null(only_sid)) {
  sam_rows <- sam_rows[sam_rows$sid == only_sid, , drop = FALSE]
  if (!nrow(sam_rows))
    stop("No sam_web row for sid=", only_sid, call. = FALSE)
}
if (!nrow(sam_rows))
  stop("No stocks with sam_web set in stocks.csv.", call. = FALSE)

out_dir <- file.path(root, "data/WGCSE")
sam_dir <- file.path(out_dir, "sam")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (cache_fit)
  dir.create(sam_dir, recursive = TRUE, showWarnings = FALSE)

message("Root: ", root)
message("Building ", nrow(sam_rows), " FLStock(s) from stockassessment.org")

for (i in seq_len(nrow(sam_rows))) {
  row <- sam_rows[i, , drop = FALSE]
  sid <- as.character(row$sid)
  web <- as.character(row$sam_web)
  obj <- as.character(row$object)
  rdata <- as.character(row$rdata)
  yr_end <- suppressWarnings(as.integer(row$end[1]))

  message("\n==> ", sid, "  fitfromweb(\"", web, "\")")
  fit <- tryCatch(
    stockassessment::fitfromweb(web),
    error = function(e) {
      stop("fitfromweb(\"", web, "\") failed: ", conditionMessage(e), call. = FALSE)
    }
  )

  if (cache_fit) {
    fit_file <- file.path(sam_dir, paste0("sam_", web, ".RData"))
    save(fit, file = fit_file)
    message("    cached fit -> ", fit_file)
  }

  stk <- FLfse::SAM2FLStock(fit)
  if (is.finite(yr_end))
    stk <- FLCore::window(stk, end = yr_end)

  assign(obj, stk)
  out_file <- file.path(out_dir, rdata)
  save(list = obj, file = out_file)
  message("    wrote ", out_file, "  object=", obj,
          "  dims=", paste(dim(stk), collapse = "x"))
  rm(list = obj)
}

message("\nDone. Non-SAM stocks (empty sam_web) were not changed.")
message("Next: Rscript scripts/run_pipeline.R")
