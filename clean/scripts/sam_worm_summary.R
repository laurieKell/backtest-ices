# Per-draw backtest metrics for the SAM survey draws (worms) and the
# displayed draw, with the number of non-converged SAM refits per draw.
# Run from clean/ with RENV_CONFIG_AUTOLOADER_ENABLED=FALSE.
# Writes data/results/02.4.2_sam_worms_summary.csv and prints a per-stock digest.

root_here <- if (file.exists("R/paths.R")) "." else "clean"
setwd(root_here)
source("R/paths.R")
source("R/constants.R")
source("R/om.R")
source("R/metrics.R")
root <- data_root()

suppressPackageStartupMessages({
  library(FLCore)
  library(FLBRP)
  library(FLBacktest)
})

load_om(root)
eqs <- eqls[["bh1"]]
load(file.path(root, "data/results/02.4.2_sam_worms.RData"))
load(file.path(root, "data/results/02.4.2_closedLoop_sam.RData"))
load(file.path(root, "data/results/02.5_rebuild.RData"))
disp <- closedLoopSam[[srr_om]]
disp_fut <- future[[arm_labs[["sam"]]]]
per_draw <- function(id, stk, fut, draw, nc) {
  refs <- metric_refs(id, eqs, eqls[[srr_om]])
  win <- metric_window(oms[[id]])
  m <- window_metrics(stk, refs, win[["y0"]], win[["yT"]])
  yT <- win[["yT"]]
  sT <- c(ssb(stk)[, ac(yT)])
  yrs_btrig <- if (sT >= refs[["Btrig"]]) 0L else
    years_to(ssb(fut), refs[["Btrig"]], yT)
  data.frame(sid = id, draw = draw, not_converged = nc,
             SSB_Btrig = m$SSB_Btrig, F_Ftar_T = c(fbar(stk)[, ac(yT)]) / refs[["Ftar"]],
             yrs_blim = m$yrs_blim, yrs_btrig = m$yrs_btrig,
             cum_catch_kt = m$cum_catch / 1000, future_yrs_to_btrig = yrs_btrig,
             stringsAsFactors = FALSE)
}

rows <- list()
for (id in case_sids) {
  h <- per_draw(id, oms[[id]], future[[arm_labs[["hist"]]]][[id]], "Historical", NA)
  a <- attributes(disp[[id]])
  cat(id, "displayed attrs:", setdiff(names(a), c("class", ".Data", slotNames(disp[[id]]))), "\n")
  nc_d <- if (!is.null(a$not_converged)) sum(a$not_converged, na.rm = TRUE)
          else if (!is.null(a$convergence)) sum(unlist(a$convergence) != 0, na.rm = TRUE)
          else NA
  d <- per_draw(id, disp[[id]], disp_fut[[id]], "Displayed", nc_d)
  w <- closedLoopSamWorms[[id]]
  nc <- attr(w, "not_converged")
  ws <- lapply(seq_len(dims(w)$iter), function(i)
    per_draw(id, FLCore::iter(w, i), FLCore::iter(futureSamWorms[[id]], i),
             paste0("worm", i), nc[i]))
  rows <- c(rows, list(h, d), ws)
}
out <- do.call(rbind, rows)
out$name <- as.character(stocks$name[match(out$sid, stocks$sid)])
h <- out[out$draw == "Historical", ]
out$delta_SSB_Btrig <- out$SSB_Btrig - h$SSB_Btrig[match(out$sid, h$sid)]
write.csv(out, file.path(root, "data/results/02.4.2_sam_worms_summary.csv"),
          row.names = FALSE)

num <- c("SSB_Btrig", "delta_SSB_Btrig", "yrs_blim", "yrs_btrig", "cum_catch_kt")
print(out[, c("name", "draw", "not_converged", num, "future_yrs_to_btrig")],
      digits = 3, row.names = FALSE)
