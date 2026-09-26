#!/usr/bin/env Rscript
# Years below Blim / Btrigger, catch totals, catch variability, 2015–terminal.
# Four case studies, bh3. Prints a table (does not write RData).

suppressPackageStartupMessages({
  library(FLCore)
  library(FLBRP)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/metrics_backtest_window.R")) {
  normalizePath("scripts", winslash = "/")
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(dirname(script_dir), "R", "paths.R"))
source(file.path(dirname(script_dir), "R", "constants.R"))
here <- clean_root(start = c(getwd(), dirname(script_dir)))
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

eqs <- eqls[["bh1"]]
ftar_all <- openLoop[["SRR"]][[srr_om]]
omF_all  <- openLoop[["OM_FMSY"]][[srr_om]]
ar_all   <- closedLoop[["SRR"]][[srr_om]]
if (is.null(ftar_all) || is.null(omF_all) || is.null(ar_all))
  stop("Need openLoop$SRR / OM_FMSY and closedLoop$SRR for ", srr_om, call. = FALSE)

as_vec <- function(x) {
  v <- c(x)
  names(v) <- dimnames(x)$year
  v
}

win_vec <- function(stk, fun, y0, yT) {
  yrs <- as.character(y0:yT)
  v <- as_vec(fun(stk))
  miss <- setdiff(yrs, names(v))
  if (length(miss))
    stop("Missing years in series: ", paste(miss, collapse = ", "), call. = FALSE)
  v[yrs]
}

mapc <- function(cvec) {
  cvec <- as.numeric(cvec)
  ok <- is.finite(cvec) & cvec > 0
  if (sum(ok) < 2L)
    stop("Need at least two positive catch values for MAPC.", call. = FALSE)
  cvec <- cvec[ok]
  abs(diff(cvec) / head(cvec, -1L))
}

metrics_one <- function(stk, y0, yT, blim, btrig) {
  if (is.null(stk))
    stop("NULL stock in metrics_one.", call. = FALSE)
  ssbv <- win_vec(stk, ssb, y0, yT)
  cv   <- win_vec(stk, catch, y0, yT)
  pc <- mapc(cv)
  list(
    n = length(ssbv),
    y0 = y0,
    yT = yT,
    yrs_blim = sum(ssbv < blim),
    yrs_btrig = sum(ssbv < btrig),
    cum_c = sum(cv),
    mean_c = mean(cv),
    cv_c = stats::sd(cv) / mean(cv),
    mapc = mean(pc),
    ssb_2015 = unname(ssbv[as.character(y0)]),
    ssb_term = unname(ssbv[as.character(yT)])
  )
}

out <- list()
for (sid in case_sids) {
  yT <- as.integer(dims(oms[[sid]])$maxyear)
  y0 <- max(as.integer(dims(oms[[sid]])$minyear), startYr_ar)
  rp <- refpts(eqs[[sid]])
  blim  <- c(rp["Blim", "ssb"])
  btrig <- c(rp["MSYBtrigger", "ssb"])
  arms <- list(
    Historical    = oms[[sid]],
    `OL F_target` = ftar_all[[sid]],
    `OL OM F_MSY` = omF_all[[sid]],
    `Advice rule` = ar_all[[sid]]
  )
  for (arm in names(arms)) {
    m <- metrics_one(arms[[arm]], y0, yT, blim, btrig)
    out[[length(out) + 1L]] <- data.frame(
      stock = unname(case_labs[[sid]]), sid = sid, arm = arm,
      y0 = y0, yT = yT, n = m$n,
      yrs_blim = m$yrs_blim, yrs_btrig = m$yrs_btrig,
      cum_c = m$cum_c, mean_c = m$mean_c, cv_c = m$cv_c, mapc = m$mapc,
      ssb_2015 = m$ssb_2015, ssb_term = m$ssb_term,
      stringsAsFactors = FALSE
    )
  }
}

tab <- do.call(rbind, out)
print(tab, row.names = FALSE, digits = 4)
invisible(tab)
