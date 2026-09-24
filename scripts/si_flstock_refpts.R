#!/usr/bin/env Rscript
# Supplementary FLStock time-series panels with ICES reference points.
# Four Paper-1 case studies only (Celtic/Irish Sea cod and whiting).
#
# Usage (from repo root or anywhere):
#   Rscript scripts/si_flstock_refpts.R
#
# Writes PDF (+ PNG) under tex/figs/si/.

suppressPackageStartupMessages({
  library(FLCore)
  library(ggplotFL)
  library(ggplot2)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/si_flstock_refpts.R")) {
  normalizePath("scripts", winslash = "/")
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(dirname(script_dir), "R", "paths.R"))
source(file.path(dirname(script_dir), "R", "loadStocks.R"))
source(file.path(dirname(script_dir), "R", "plot_theme.R"))
root <- bm_root(start = c(getwd(), dirname(script_dir)))

case_sids <- c(
  "cod.27.7a",
  "whg.27.7a",
  "cod.27.7e-k",
  "whg.27.7b-ce-k"
)

stocks <- read.csv(
  file.path(root, "data/reference/stocks.csv"),
  stringsAsFactors = FALSE
)
stocks <- stocks[match(case_sids, stocks$sid), , drop = FALSE]
stocks$name <- factor(stocks$name, levels = unique(stocks$name))
stopifnot(nrow(stocks) == 4L, !anyNA(stocks$sid))

out_dir <- file.path(root, "tex", "figs", "si")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Published ICES points matching skeleton Table tab:casestudy-status
# (fallback if SAG cache is missing or incomplete).
refpts_paper <- data.frame(
  sid = case_sids,
  FMSY = c(0.171, 0.210, 0.290, 0.375),
  Blim = c(9364, 1670, 4200, 36571),
  MSYBtrigger = c(13012, 2322, 5800, 50818),
  stringsAsFactors = FALSE
)

load_rfpts <- function() {
  cand <- c(
    file.path(root, "data/interim/sag_stocks.RData"),
    file.path(root, "data/om/sag.RData")
  )
  for (fl in cand) {
    if (!file.exists(fl)) next
    e <- new.env(parent = emptyenv())
    load(fl, envir = e)
    sag <- if (exists("sag", envir = e, inherits = FALSE)) e$sag else NULL
    if (is.null(sag) || is.null(sag$rfpts)) next
    rp <- as.data.frame(sag$rfpts, stringsAsFactors = FALSE)
    nms <- names(rp)
    # Normalise column names used across SAG dumps
    rename <- c(
      fmsy = "FMSY", Fmsy = "FMSY", FMSY = "FMSY",
      blim = "Blim", Blim = "Blim",
      msybtrigger = "MSYBtrigger", MSYBtrigger = "MSYBtrigger",
      Btrigger = "MSYBtrigger"
    )
    for (nm in intersect(names(rename), nms))
      names(rp)[names(rp) == nm] <- rename[[nm]]
    need <- c("sid", "FMSY", "Blim", "MSYBtrigger")
    if (!all(need %in% names(rp))) next
    if ("assYear" %in% names(rp)) {
      rp <- rp[order(rp$sid, -as.integer(rp$assYear)), , drop = FALSE]
      rp <- rp[!duplicated(rp$sid), , drop = FALSE]
    }
    rp <- rp[rp$sid %in% case_sids, need, drop = FALSE]
    if (nrow(rp) == length(case_sids)) {
      message("Reference points from ", fl)
      return(rp)
    }
  }
  message("Using skeleton Table tab:casestudy-status reference points")
  refpts_paper
}

rfpts <- load_rfpts()
rfpts <- merge(stocks[, c("sid", "name")], rfpts, by = "sid", all.x = TRUE)
rfpts <- rfpts[match(case_sids, rfpts$sid), , drop = FALSE]

# Metrics / panel names aligned with 06.0_report.Rmd
metrics <- list(Rec = rec, SB = ssb, C = catch, F = fbar)

file_stub <- function(sid) {
  paste0("si_flstock_", gsub("[^A-Za-z0-9._-]", "_", sid))
}

failed <- character()
written <- character()

for (i in seq_len(nrow(stocks))) {
  sid <- as.character(stocks$sid[i])
  nm  <- as.character(stocks$name[i])
  message("=== ", nm, " (", sid, ") ===")

  stk <- tryCatch(
    loadFLStock(stocks[i, , drop = FALSE], file.path(root, "data/WGCSE")),
    error = function(e) {
      message("  LOAD FAILED: ", conditionMessage(e))
      NULL
    }
  )
  if (is.null(stk)) {
    failed <- c(failed, sid)
    next
  }
  if (requireNamespace("FLBacktest", quietly = TRUE)) {
    stk <- tryCatch(FLBacktest::cleanStock(stk), error = function(e) stk)
  }

  rp <- rfpts[rfpts$sid == sid, , drop = FALSE]
  blim  <- suppressWarnings(as.numeric(rp$Blim[1]))
  btrig <- suppressWarnings(as.numeric(rp$MSYBtrigger[1]))
  fmsy  <- suppressWarnings(as.numeric(rp$FMSY[1]))
  if (!all(is.finite(c(blim, btrig, fmsy)))) {
    message("  Missing refpts; using paper table fallback")
    fb <- refpts_paper[refpts_paper$sid == sid, , drop = FALSE]
    blim  <- fb$Blim
    btrig <- fb$MSYBtrigger
    fmsy  <- fb$FMSY
  }

  x0 <- as.integer(dims(stk)$minyear)
  x_lab <- x0 + max(2L, floor((as.integer(dims(stk)$maxyear) - x0) * 0.15))

  p <- plot(FLStocks(Assessment = stk), metrics = metrics) +
    geom_flpar(
      data = FLPars(SB = FLPar(Blim = blim)),
      x = x_lab, colour = bm_col("catch"), linetype = 2) +
    geom_flpar(
      data = FLPars(SB = FLPar(Btrig = btrig)),
      x = x_lab + 3, colour = bm_col("trigger"), linetype = 3) +
    geom_flpar(
      data = FLPars(F = FLPar(FMSY = fmsy)),
      x = x_lab, colour = bm_col("f_target"), linetype = 2) +
    labs(
      title = nm,
      subtitle = sprintf(
        "ICES: Blim = %s t, MSYBtrigger = %s t, FMSY = %s",
        formatC(blim, format = "fg", digits = 4),
        formatC(btrig, format = "fg", digits = 4),
        formatC(fmsy, format = "fg", digits = 3)),
      x = "Year") +
    theme_bluemarine(base_size = 11) +
    theme(legend.position = "none",
          plot.subtitle = element_text(size = rel(0.85), colour = bm_col("muted")))

  stub <- file_stub(sid)
  pdf_path <- file.path(out_dir, paste0(stub, ".pdf"))
  png_path <- file.path(out_dir, paste0(stub, ".png"))
  ggsave(pdf_path, p, width = 8.5, height = 7.5)
  ggsave(png_path, p, width = 8.5, height = 7.5, dpi = 150)
  written <- c(written, pdf_path, png_path)
  message("  wrote ", basename(pdf_path), " / ", basename(png_path))
}

# Combined 2x2 overview (SSB and F only) for a compact SI overview page
message("=== combined overview ===")
ts_list <- list()
for (i in seq_len(nrow(stocks))) {
  sid <- as.character(stocks$sid[i])
  if (sid %in% failed) next
  stk <- loadFLStock(stocks[i, , drop = FALSE], file.path(root, "data/WGCSE"))
  if (requireNamespace("FLBacktest", quietly = TRUE))
    stk <- tryCatch(FLBacktest::cleanStock(stk), error = function(e) stk)
  df <- model.frame(FLQuants(SSB = ssb(stk), F = fbar(stk), Catch = catch(stk)),
                    drop = TRUE)
  df$sid <- sid
  df$name <- as.character(stocks$name[i])
  ts_list[[sid]] <- df
}
if (length(ts_list)) {
  ts <- do.call(rbind, ts_list)
  ts <- merge(ts, rfpts[, c("sid", "Blim", "MSYBtrigger", "FMSY")], by = "sid")
  ts$name <- factor(ts$name, levels = levels(stocks$name))
  long <- rbind(
    data.frame(name = ts$name, year = ts$year, qname = "SSB (t)",
               data = ts$SSB, h1 = ts$Blim, h2 = ts$MSYBtrigger,
               stringsAsFactors = FALSE),
    data.frame(name = ts$name, year = ts$year, qname = "F",
               data = ts$F, h1 = ts$FMSY, h2 = NA_real_,
               stringsAsFactors = FALSE)
  )
  long$qname <- factor(long$qname, levels = c("SSB (t)", "F"))
  href <- unique(long[, c("name", "qname", "h1", "h2")])

  p_all <- ggplot(long, aes(year, data)) +
    geom_hline(data = href, aes(yintercept = h1),
               linetype = 2, colour = bm_col("catch"), linewidth = 0.4) +
    geom_hline(data = subset(href, is.finite(h2)), aes(yintercept = h2),
               linetype = 3, colour = bm_col("trigger"), linewidth = 0.4) +
    geom_line(colour = bm_col("advice"), linewidth = 0.75, na.rm = TRUE) +
    facet_grid(qname ~ name, scales = "free_y") +
    labs(x = NULL, y = NULL,
         title = "Case-study FLStocks with ICES reference points",
         subtitle = "SSB: dashed Blim, dotted MSYBtrigger; F: dashed FMSY") +
    theme_bluemarine(base_size = 10) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  comb_pdf <- file.path(out_dir, "si_flstock_casestudy_overview.pdf")
  comb_png <- file.path(out_dir, "si_flstock_casestudy_overview.png")
  ggsave(comb_pdf, p_all, width = 11, height = 5.5)
  ggsave(comb_png, p_all, width = 11, height = 5.5, dpi = 150)
  written <- c(written, comb_pdf, comb_png)
  message("  wrote ", basename(comb_pdf))
}

message("\nDone. Wrote ", length(written), " files to ", out_dir)
if (length(failed))
  message("Failed to load: ", paste(failed, collapse = ", "))
invisible(list(written = written, failed = failed, rfpts = rfpts))
