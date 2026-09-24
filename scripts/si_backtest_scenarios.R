#!/usr/bin/env Rscript
# Supplementary three-arm backtest trajectories for Paper-1 case studies.
# Celtic/Irish Sea cod and whiting only (no haddock, no mackerel).
#
# Arms (legend labels):
#   Historical — realised WGCSE FLStock path
#   F = FMSY   — open-loop constant ICES FMSY (04.1 / openLoop$SRR)
#   ICES AR    — closed-loop ICES Category 1 hockey-stick (04.2 / closedLoop$SRR)
#
# Period of concern (x-axis): hcrICES start (2015) through each stock's
# terminal year — the closed-loop Historical window in skeleton.tex.
# Future rebuild panels are omitted (scoring window is Historical only).
# F = FMSY is the open-loop series restricted to the same years (not re-run
# from 2015); the open-loop itself starts at openloop_start (~1990).
#
# Uses saved pipeline objects (bh3 OM SRR; ICES control points on bh1):
#   data/om/oms.RData, data/om/eqls.RData,
#   data/results/03.1_openLoop.RData, 03.2_closedLoop.RData
#
# Usage:
#   Rscript scripts/si_backtest_scenarios.R
#
# Writes PDF (+ PNG) under tex/figs/si/.

suppressPackageStartupMessages({
  library(FLCore)
  library(FLBRP)
  library(ggplotFL)
  library(ggplot2)
  library(FLBacktest)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/si_backtest_scenarios.R")) {
  normalizePath("scripts", winslash = "/")
} else {
  normalizePath(".", winslash = "/")
}
root_guess <- dirname(script_dir)
source(file.path(root_guess, "R", "paths.R"))
source(file.path(root_guess, "R", "plot_theme.R"))
root <- bm_root(start = c(getwd(), root_guess))

case_sids <- c(
  "cod.27.7a",
  "whg.27.7a",
  "cod.27.7e-k",
  "whg.27.7b-ce-k"
)

arm_cols <- c(
  "Historical" = "#000000",
  "F = FMSY"   = "#0072B2",
  "ICES AR"    = "#D55E00"
)
arm_lty <- c(
  "Historical" = "solid",
  "F = FMSY"   = "solid",
  "ICES AR"    = "solid"
)

srr_om <- "bh3"
# HCR / closed-loop Historical window (skeleton.tex: hcrICES from 2015)
startYr_ar <- 2015L
metrics <- list(F = fbar, SB = ssb, Rec = rec, C = catch)
qname_lab <- labeller(qname = c(
  F = "F", SB = "SSB", Rec = "Recruitment", C = "Catch"
))

win_stk <- function(stk, start, end) {
  start <- max(as.integer(dims(stk)$minyear), as.integer(start))
  end   <- min(as.integer(dims(stk)$maxyear), as.integer(end))
  if (start > end)
    stop("Empty window: start=", start, " end=", end, call. = FALSE)
  window(stk, start = start, end = end)
}

style_traj <- function(p, lwd = 1.2) {
  for (i in seq_along(p$layers)) {
    if (inherits(p$layers[[i]]$geom, "GeomLine"))
      p$layers[[i]]$aes_params$linewidth <- lwd
  }
  p
}

resolve_branch <- function(top, srr) {
  if (is.null(top)) return(NULL)
  if (srr %in% names(top)) return(top[[srr]])
  if ("SRR" %in% names(top) && srr %in% names(top[["SRR"]]))
    return(top[["SRR"]][[srr]])
  NULL
}

out_dir <- file.path(root, "tex", "figs", "si")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

message("Loading OM and backtest results from ", root)
load(file.path(root, "data/om/oms.RData"))
load(file.path(root, "data/om/eqls.RData"))
load(file.path(root, "data/results/03.1_openLoop.RData"))
load(file.path(root, "data/results/03.2_closedLoop.RData"))

if (!exists("stocks") || is.null(stocks)) {
  stocks <- read.csv(
    file.path(root, "data/reference/stocks.csv"),
    stringsAsFactors = FALSE
  )
}
stocks <- stocks[match(case_sids, stocks$sid), , drop = FALSE]
stocks$name <- factor(as.character(stocks$name),
                      levels = unique(as.character(stocks$name)))
stopifnot(nrow(stocks) == 4L, !anyNA(stocks$sid))
sids <- as.character(stocks$sid)

if (!"bh1" %in% names(eqls))
  stop("eqls[['bh1']] missing — knit 02.0_condition_om.Rmd first.", call. = FALSE)
eqs <- eqls[["bh1"]]

ftar_all <- resolve_branch(openLoop[["SRR"]], srr_om)
ar_all   <- resolve_branch(closedLoop[["SRR"]], srr_om)
if (is.null(ftar_all))
  stop("openLoop$SRR$", srr_om, " missing — knit 04.1_openLoop.Rmd.", call. = FALSE)
if (is.null(ar_all))
  stop("closedLoop$SRR$", srr_om, " missing — knit 04.2_closedLoop.Rmd.", call. = FALSE)

ices_rp <- function(id) {
  rp <- refpts(eqs[[id]])
  c(Blim  = c(rp["Blim",        "ssb"]),
    Btrig = c(rp["MSYBtrigger", "ssb"]),
    FMSY  = c(rp["FMSY",        "harvest"]))
}

# Period of concern per stock: max(HCR start, assessment minyear) → terminal
term_yr <- setNames(vapply(sids, function(id)
  as.integer(dims(oms[[id]])$maxyear), integer(1L)), sids)
win_start <- setNames(vapply(sids, function(id) {
  max(as.integer(dims(oms[[id]])$minyear), startYr_ar)
}, integer(1L)), sids)

message("Period of concern (HCR Historical window):")
for (id in sids)
  message("  ", id, ": ", win_start[[id]], "–", term_yr[[id]])

file_stub <- function(sid) {
  paste0("si_backtest_", gsub("[^A-Za-z0-9._-]", "_", sid))
}

failed <- character()
written <- character()
arm_fail <- list()

plot_arms <- function(stks, cols, title, xmin, xmax, ices) {
  nms <- names(stks)
  p <- plot(do.call(FLStocks, stks), metrics = metrics) +
    scale_x_continuous(limits = c(xmin, xmax),
                       breaks = pretty(c(xmin, xmax), n = 6)) +
    scale_colour_manual(values = cols[nms], breaks = nms, labels = nms) +
    scale_fill_manual(values = cols[nms], guide = "none") +
    aes(linetype = stock) +
    scale_linetype_manual(values = arm_lty[nms], breaks = nms, labels = nms) +
    labs(title = title,
         subtitle = sprintf("%d–%d (HCR Historical window)", xmin, xmax),
         x = "Year") +
    facet_grid(qname ~ ., scales = "free_y", labeller = qname_lab) +
    theme_bluemarine(base_size = 11) +
    theme(legend.position = "bottom",
          plot.subtitle = element_text(size = rel(0.85), colour = bm_col("muted")))
  p <- style_traj(p)
  x_lab <- xmin + max(1L, floor((xmax - xmin) * 0.2))
  p +
    geom_flpar(
      data = FLPars(SB = FLPar(Blim = ices[["Blim"]])),
      x = x_lab, colour = bm_col("catch"), linetype = 2) +
    geom_flpar(
      data = FLPars(SB = FLPar(Btrig = ices[["Btrig"]])),
      x = x_lab + 1, colour = bm_col("trigger"), linetype = 3) +
    geom_flpar(
      data = FLPars(F = FLPar(FMSY = ices[["FMSY"]])),
      x = x_lab, colour = bm_col("f_target"), linetype = 2)
}

for (i in seq_len(nrow(stocks))) {
  sid <- as.character(stocks$sid[i])
  nm  <- as.character(stocks$name[i])
  message("=== ", nm, " (", sid, ") ===")

  miss <- character()
  if (is.null(oms[[sid]])) miss <- c(miss, "Historical(oms)")
  if (is.null(ftar_all[[sid]])) miss <- c(miss, "F = FMSY(openLoop)")
  if (is.null(ar_all[[sid]])) miss <- c(miss, "ICES AR(closedLoop)")
  if (length(miss)) {
    message("  MISSING: ", paste(miss, collapse = ", "))
    failed <- c(failed, sid)
    arm_fail[[sid]] <- miss
    next
  }

  ices <- ices_rp(sid)
  y0 <- win_start[[sid]]
  yT <- term_yr[[sid]]

  stks_h <- list(
    "Historical" = win_stk(oms[[sid]], y0, yT),
    "F = FMSY"   = win_stk(ftar_all[[sid]], y0, yT),
    "ICES AR"    = win_stk(ar_all[[sid]], y0, yT)
  )
  p_out <- plot_arms(
    stks_h, arm_cols,
    title = paste0(nm, " — backtest arms"),
    xmin = y0, xmax = yT, ices = ices
  )

  stub <- file_stub(sid)
  pdf_path <- file.path(out_dir, paste0(stub, ".pdf"))
  png_path <- file.path(out_dir, paste0(stub, ".png"))
  ggsave(pdf_path, p_out, width = 8.5, height = 8.5)
  ggsave(png_path, p_out, width = 8.5, height = 8.5, dpi = 150)
  written <- c(written, pdf_path, png_path)
  message("  wrote ", basename(pdf_path), " / ", basename(png_path),
          " (", y0, "–", yT, ")")
}

# Compact overview: SSB and F, three arms, four stocks (same year window)
message("=== combined overview ===")
ts_list <- list()
for (sid in sids) {
  if (sid %in% failed) next
  nm <- as.character(stocks$name[match(sid, stocks$sid)])
  y0 <- win_start[[sid]]
  yT <- term_yr[[sid]]

  mk <- function(stk, arm) {
    df <- model.frame(FLQuants(SSB = ssb(stk), F = fbar(stk)), drop = TRUE)
    if (dims(stk)$iter > 1 && "iter" %in% names(df)) {
      df <- aggregate(cbind(SSB, F) ~ year, data = df, FUN = median, na.rm = TRUE)
    }
    df$arm <- arm
    df$sid <- sid
    df$name <- nm
    df
  }
  ts_list[[sid]] <- rbind(
    mk(win_stk(oms[[sid]], y0, yT), "Historical"),
    mk(win_stk(ftar_all[[sid]], y0, yT), "F = FMSY"),
    mk(win_stk(ar_all[[sid]], y0, yT), "ICES AR")
  )
}

if (length(ts_list)) {
  ts <- do.call(rbind, ts_list)
  rp <- do.call(rbind, lapply(sids, function(id) {
    r <- ices_rp(id)
    data.frame(sid = id, Blim = r[["Blim"]], Btrig = r[["Btrig"]],
               FMSY = r[["FMSY"]], stringsAsFactors = FALSE)
  }))
  ts <- merge(ts, rp, by = "sid")
  ts$name <- factor(ts$name, levels = levels(stocks$name))
  ts$arm <- factor(ts$arm, levels = c("Historical", "F = FMSY", "ICES AR"))

  long <- rbind(
    data.frame(name = ts$name, year = ts$year, arm = ts$arm, qname = "SSB (t)",
               data = ts$SSB, h1 = ts$Blim, h2 = ts$Btrig,
               stringsAsFactors = FALSE),
    data.frame(name = ts$name, year = ts$year, arm = ts$arm, qname = "F",
               data = ts$F, h1 = ts$FMSY, h2 = NA_real_,
               stringsAsFactors = FALSE)
  )
  long$qname <- factor(long$qname, levels = c("SSB (t)", "F"))
  long$arm <- factor(long$arm, levels = levels(ts$arm))
  href <- unique(long[, c("name", "qname", "h1", "h2")])

  yr_note <- paste(sprintf("%s %d–%d",
                           as.character(stocks$name),
                           win_start[sids], term_yr[sids]),
                   collapse = "; ")

  p_all <- ggplot(long, aes(year, data, colour = arm)) +
    geom_hline(data = href, aes(yintercept = h1),
               linetype = 2, colour = bm_col("catch"), linewidth = 0.4) +
    geom_hline(data = subset(href, is.finite(h2)), aes(yintercept = h2),
               linetype = 3, colour = bm_col("trigger"), linewidth = 0.4) +
    geom_line(linewidth = 0.75, na.rm = TRUE) +
    scale_colour_manual(values = arm_cols) +
    facet_grid(qname ~ name, scales = "free_y") +
    labs(
      x = NULL, y = NULL,
      title = "Backtest arms: Historical, F = FMSY, ICES AR",
      subtitle = paste0(
        "HCR Historical window from ", startYr_ar,
        " to each stock terminal year (OM SRR ", srr_om,
        "). SSB: dashed Blim, dotted Btrig; F: dashed FMSY")
    ) +
    theme_bluemarine(base_size = 10) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "bottom")

  comb_pdf <- file.path(out_dir, "si_backtest_casestudy_overview.pdf")
  comb_png <- file.path(out_dir, "si_backtest_casestudy_overview.png")
  ggsave(comb_pdf, p_all, width = 11, height = 5.5)
  ggsave(comb_png, p_all, width = 11, height = 5.5, dpi = 150)
  written <- c(written, comb_pdf, comb_png)
  message("  wrote ", basename(comb_pdf))
  message("  years: ", yr_note)
}

message("\nDone. Wrote ", length(written), " files to ", out_dir)
if (length(failed))
  message("Failed stocks: ", paste(failed, collapse = ", "))
invisible(list(written = written, failed = failed, arm_fail = arm_fail,
               srr = srr_om, win_start = win_start, term_yr = term_yr,
               startYr_ar = startYr_ar))
