#!/usr/bin/env Rscript
# Manuscript Results with the SAM management procedure as the Advice rule.
# Four case studies, reference OM bh3. Advice rule = 02.4.2 SAM closed loop
# for SAM stocks; perfect information (02.2) for stocks without a SAM
# assessment (Irish Sea cod). Perfect-information metrics are kept alongside
# as the no-assessment-error bound.
#
#   Rscript scripts/manuscript_sam.R
#
# Writes clean/data/results/04.2_manuscript_sam.RData and prints the tables.

suppressPackageStartupMessages({
  library(FLCore)
  library(FLBRP)
  library(FLasher)
  library(FLBacktest)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/manuscript_sam.R")) {
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
  path
}
load(need(file.path(root, "data/om/oms.RData")))
load(need(file.path(root, "data/om/eqls.RData")))
load(need(file.path(root, "data/results/02.1_openLoop.RData")))
load(need(file.path(root, "data/results/02.2_closedLoop.RData")))
load(need(file.path(root, "data/results/02.4.2_closedLoop_sam.RData")))

eqs <- eqls[["bh1"]]
if (!srr_om %in% names(closedLoopSam))
  stop("02.4.2 has no ", srr_om, " run (BM_SAM_STAGE=loop).", call. = FALSE)
sam <- closedLoopSam[[srr_om]]
pi  <- closedLoop[["SRR"]][[srr_om]]
bndTac  <- closedLoop[["bndTac"]]
bndWhen <- closedLoop[["bndWhen"]]

mp_type <- setNames(ifelse(case_sids %in% names(sam), "SAM", "Perfect info"),
                    case_sids)
mp <- FLStocks(setNames(lapply(case_sids, function(id)
  if (mp_type[[id]] == "SAM") sam[[id]] else pi[[id]]), case_sids))

win <- function(stk, fun, y0, yT) {
  v <- c(fun(stk)[, ac(y0:yT)])
  if (length(v) != length(y0:yT) || any(!is.finite(v)))
    stop("Non-finite series in ", y0, "-", yT, call. = FALSE)
  v
}
mapc <- function(cv) {
  cv <- cv[is.finite(cv) & cv > 0]
  mean(abs(diff(cv) / head(cv, -1L)))
}

rows <- list()
for (id in case_sids) {
  yT <- as.integer(dims(oms[[id]])$maxyear)
  y0 <- max(as.integer(dims(oms[[id]])$minyear), startYr_ar)
  rp <- refpts(eqs[[id]])
  blim  <- c(rp["Blim", "ssb"])
  btrig <- c(rp["MSYBtrigger", "ssb"])
  ftar  <- c(rp["FMSY", "harvest"])
  arms <- list(
    Historical      = oms[[id]],
    `OL F_target`   = openLoop[["SRR"]][[srr_om]][[id]],
    `OL OM F_MSY`   = openLoop[["OM_FMSY"]][[srr_om]][[id]],
    `Advice rule`   = mp[[id]],
    `Perfect info`  = pi[[id]])
  for (arm in names(arms)) {
    stk <- arms[[arm]]
    if (is.null(stk)) stop("Missing ", arm, " for ", id, call. = FALSE)
    s <- win(stk, ssb, y0, yT)
    f <- win(stk, fbar, y0, yT)
    cc <- win(stk, catch, y0, yT)
    rows[[length(rows) + 1L]] <- data.frame(
      stock = unname(case_labs[[id]]), sid = id, arm = arm,
      mp = if (arm == "Advice rule") mp_type[[id]] else "",
      y0 = y0, yT = yT, n = length(s),
      SSB_Btrig = s[length(s)] / btrig,
      F = mean(f), F_Ftar = mean(f) / ftar,
      yrs_blim = sum(s < blim), yrs_btrig = sum(s < btrig),
      cum_c_kt = sum(cc) / 1000, mapc_pct = 100 * mapc(cc),
      stringsAsFactors = FALSE)
  }
}
metrics <- do.call(rbind, rows)
hist <- metrics[metrics$arm == "Historical", c("sid", "SSB_Btrig")]
metrics$delta <- metrics$SSB_Btrig - hist$SSB_Btrig[match(metrics$sid, hist$sid)]

# 20-year Future from terminal states, as in 02.5_rebuild.Rmd.
nYears <- 20L
starts <- list(Historical = oms[case_sids], `Advice rule` = mp)
future <- lapply(starts, function(stks)
  FLStocks(setNames(lapply(case_sids, function(id)
    project_hcr(stks[[id]], eqls[[srr_om]][[id]], hcrParams(eqs[[id]]),
                nYears, bndTac = bndTac, bndWhen = bndWhen)), case_sids)))

rebuild <- do.call(rbind, lapply(names(starts), function(pol) {
  do.call(rbind, lapply(case_sids, function(id) {
    stk <- starts[[pol]][[id]]
    yT <- dims(stk)$maxyear
    sT <- c(iterMedians(ssb(stk)[, ac(yT)]))
    btrig <- c(refpts(eqs[[id]])["MSYBtrigger", "ssb"])
    bmsy  <- c(refpts(eqls[[srr_om]][[id]])["msy", "ssb"])
    s <- ssb(future[[pol]][[id]])
    data.frame(
      stock = unname(case_labs[[id]]), sid = id, policy = pol,
      Bmsy_Btrig = bmsy / btrig,
      SSB_Btrig = sT / btrig, SSB_Bmsy = sT / bmsy,
      years_to_Btrig = if (sT < btrig) years_to(s, btrig, yT) else 0L,
      years_to_Bmsy  = if (sT < bmsy)  years_to(s, bmsy,  yT) else 0L,
      stringsAsFactors = FALSE)
  }))
}))

out <- file.path(root, "data/results/04.2_manuscript_sam.RData")
save(metrics, rebuild, future, mp, mp_type, srr_om, startYr_ar, nYears,
     bndTac, bndWhen, file = out)

op <- options(width = 200)
cat("Advice rule MP by stock:\n"); print(mp_type)
cat("\nBacktest window metrics:\n")
print(metrics, row.names = FALSE, digits = 3)
cat("\nRebuild (years to threshold; NA = not within ", nYears, "):\n", sep = "")
print(rebuild, row.names = FALSE, digits = 3)
options(op)
cat("Saved ", out, "\n", sep = "")
