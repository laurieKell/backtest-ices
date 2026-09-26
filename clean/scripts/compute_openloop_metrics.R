#!/usr/bin/env Rscript
# Paper-1 backtest-window metrics. Four case studies, reference OM bh3.
# Writes clean/data/results/02.1_metrics.RData
#
#   Rscript --vanilla scripts/compute_openloop_metrics.R

suppressPackageStartupMessages({
  library(FLCore)
  library(FLBRP)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/compute_openloop_metrics.R")) {
  normalizePath("scripts", winslash = "/")
} else {
  normalizePath(".", winslash = "/")
}
root_guess <- dirname(script_dir)
source(file.path(root_guess, "R", "paths.R"))
source(file.path(root_guess, "R", "constants.R"))
here <- clean_root(start = c(getwd(), root_guess))
root <- data_root(start = c(getwd(), here))

need <- function(path) {
  if (!file.exists(path)) stop("Missing ", path, call. = FALSE)
}
need(file.path(root, "data/om/oms.RData"))
need(file.path(root, "data/om/eqls.RData"))
need(file.path(root, "data/results/02.1_openLoop.RData"))
need(file.path(root, "data/results/02.2_closedLoop.RData"))

load(file.path(root, "data/om/oms.RData"))
load(file.path(root, "data/om/eqls.RData"))
load(file.path(root, "data/results/02.1_openLoop.RData"))
load(file.path(root, "data/results/02.2_closedLoop.RData"))

if (!srr_om %in% names(openLoop[["SRR"]]))
  stop("openLoop$SRR$", srr_om, " missing.", call. = FALSE)
if (!srr_om %in% names(closedLoop[["SRR"]]))
  stop("closedLoop$SRR$", srr_om, " missing.", call. = FALSE)
if (is.null(openLoop[["OM_FMSY"]]) || !srr_om %in% names(openLoop[["OM_FMSY"]]))
  stop("openLoop$OM_FMSY$", srr_om, " missing.", call. = FALSE)
eqs <- eqls[["bh1"]]

win_mean_F <- function(stk, y0 = startYr_ar) {
  yT <- dims(stk)$maxyear
  y0 <- max(as.integer(dims(stk)$minyear), as.integer(y0))
  mean(c(fbar(window(stk, start = y0, end = yT))))
}

term_ssb <- function(stk) {
  yr <- dims(stk)$maxyear
  c(ssb(stk)[, ac(yr)])
}

rows <- lapply(case_sids, function(id) {
  hist <- oms[[id]]
  ftar_stk <- openLoop[["SRR"]][[srr_om]][[id]]
  ar_stk   <- closedLoop[["SRR"]][[srr_om]][[id]]
  om_stk   <- openLoop[["OM_FMSY"]][[srr_om]][[id]]
  if (is.null(hist) || is.null(ftar_stk) || is.null(ar_stk) || is.null(om_stk))
    stop("Missing trajectory for ", id, call. = FALSE)
  btrig <- c(refpts(eqs[[id]])["MSYBtrigger", "ssb"])
  ftar  <- c(refpts(eqs[[id]])["FMSY", "harvest"])
  fmsy  <- c(refpts(eqls[[srr_om]][[id]])["msy", "harvest"])
  mk <- function(stk, prefix) {
    Fbar <- win_mean_F(stk)
    list(
      setNames(term_ssb(stk) / btrig, paste0(prefix, "_SSB_Btrig")),
      setNames(Fbar, paste0(prefix, "_F")),
      setNames(Fbar / ftar, paste0(prefix, "_F_Ftar"))
    )
  }
  vals <- c(
    list(stock = unname(case_labs[id]), sid = id,
         Ftar = ftar, Fmsy_om = fmsy),
    unlist(mk(hist, "hist")),
    unlist(mk(ftar_stk, "ftar")),
    unlist(mk(om_stk, "omF")),
    unlist(mk(ar_stk, "ar"))
  )
  as.data.frame(vals, stringsAsFactors = FALSE)
})

metrics <- do.call(rbind, rows)
rownames(metrics) <- NULL
metrics$delta_SSB_Btrig <- metrics$ar_SSB_Btrig - metrics$hist_SSB_Btrig

out <- file.path(root, "data/results/02.1_metrics.RData")
save(metrics, srr_om, startYr_ar, file = out)

fmt <- function(x, d = 2) sprintf(paste0("%.", d, "f"), x)
cat("Reference OM:", srr_om, "\n")
print(metrics, row.names = FALSE, digits = 3)
cat("Saved ", out, "\n", sep = "")
