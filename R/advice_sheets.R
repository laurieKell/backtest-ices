# ICES advice-sheet status and reference points transcribed from docs/advice.
# Table 1 layout = MSY / precautionary-approach stock status (not the forecast
# assumptions table that current sheets number as Table 1).

load_advice_sheets <- function(root = bm_root()) {
  f <- file.path(root, "data/reference/advice_sheets.csv")
  if (!file.exists(f))
    stop("Missing ", f, call. = FALSE)
  x <- read.csv(f, stringsAsFactors = FALSE, check.names = FALSE,
                na.strings = c("NA", ""))
  need <- c("sid", "sheet_file", "ices_advice_year", "FMSY", "Blim", "Bpa",
            "MSYBtrigger", "Fpa", "msy_f", "msy_ssb", "pa_f_fpa", "pa_f_flim",
            "pa_ssb_bpa", "pa_ssb_blim", "pa_f_label", "pa_ssb_label",
            "stock_dev", "blim_basis", "fmsy_basis")
  miss <- setdiff(need, names(x))
  if (length(miss))
    stop("advice_sheets.csv missing columns: ", paste(miss, collapse = ", "),
         call. = FALSE)
  x
}

advice_row <- function(advice, sid) {
  i <- match(sid, advice$sid)
  if (is.na(i))
    stop("No advice-sheet row for ", sid, call. = FALSE)
  advice[i, , drop = FALSE]
}

# Compare sheet FMSY / Blim / MSYBtrigger to the FLBRP the HCR actually used
# (bh1 via addBenchmark). Do not overwrite oms/eqls. Stop only if HCR inputs
# disagree with the sheet — that would mean the backtest used an older SAG row.
check_advice_vs_eqls <- function(advice, eqs, sids = NULL, tol_f = 1e-4,
                                 tol_b = 1) {
  if (is.null(sids)) sids <- as.character(advice$sid)
  rows <- list()
  bad <- character()
  for (id in sids) {
    sh <- advice_row(advice, id)
    if (is.null(eqs[[id]])) {
      rows[[id]] <- data.frame(
        sid = id, quantity = "FLBRP", sheet = NA_real_, hcr = NA_real_,
        match = FALSE, note = "missing eqls[[sid]]",
        stringsAsFactors = FALSE)
      bad <- c(bad, id)
      next
    }
    rp <- refpts(eqs[[id]])
    chk <- list(
      FMSY        = list(sheet = sh$FMSY,        hcr = c(rp["FMSY", "harvest"]),
                         tol = tol_f),
      Blim        = list(sheet = sh$Blim,        hcr = c(rp["Blim", "ssb"]),
                         tol = tol_b),
      MSYBtrigger = list(sheet = sh$MSYBtrigger, hcr = c(rp["MSYBtrigger", "ssb"]),
                         tol = tol_b))
    for (q in names(chk)) {
      a <- as.numeric(chk[[q]]$sheet)
      b <- as.numeric(chk[[q]]$hcr)
      ok <- is.finite(a) && is.finite(b) && abs(a - b) <= chk[[q]]$tol
      rows[[paste(id, q)]] <- data.frame(
        sid = id, quantity = q, sheet = a, hcr = b, match = ok,
        note = if (ok) "sheet = HCR (bh1/SAG at 02.0)" else
          "HCR used a different SAG row; re-knit 02.0 + 04.1 + 04.2",
        stringsAsFactors = FALSE)
      if (!ok) bad <- c(bad, id)
    }
  }
  cmp <- do.call(rbind, rows)
  rownames(cmp) <- NULL
  if (length(bad)) {
    stop("Advice-sheet FMSY/Blim/MSYBtrigger disagree with the HCR FLBRP for: ",
         paste(unique(bad), collapse = ", "),
         "\nDisplayed status still follows docs/advice. ",
         "Open/closed-loop results used the SAG row at 02.0 conditioning. ",
         "Re-knit 02.0 + 04.1 + 04.2 before treating HCR trajectories as current-sheet HCR.\n",
         paste(utils::capture.output(print(cmp[!cmp$match, , drop = FALSE])),
               collapse = "\n"),
         call. = FALSE)
  }
  cmp
}

advice_catch_lab <- function(row) {
  if (isTRUE(row$advice_catch_t == 0))
    return(as.character(row$advice_catch_note))
  paste0(prettyNum(row$advice_catch_t, big.mark = ","), " t (",
         row$advice_catch_note, ")")
}

# Two-row ICES Table 1 layout for one stock.
advice_status_block <- function(advice, sid, stocks = NULL) {
  sh <- advice_row(advice, sid)
  f_pa <- paste0("$F_{\\mathrm{pa}}$: ", sh$pa_f_fpa,
                 "; $F_{\\lim}$: ", sh$pa_f_flim,
                 " (", sh$pa_f_label, ")")
  s_pa <- paste0("$B_{\\mathrm{pa}}$: ", sh$pa_ssb_bpa,
                 "; $B_{\\lim}$: ", sh$pa_ssb_blim,
                 " (", sh$pa_ssb_label, ")")
  tab <- data.frame(
    Framework = c("Maximum sustainable yield (MSY) approach",
                  "Precautionary approach"),
    `Fishing pressure` = c(paste0("$F_{\\mathrm{MSY}}$: ", sh$msy_f), f_pa),
    `Stock size` = c(paste0("$MSYB_{\\mathrm{trigger}}$: ", sh$msy_ssb), s_pa),
    check.names = FALSE, stringsAsFactors = FALSE)
  knitr::kable(
    tab, row.names = FALSE, escape = FALSE,
    col.names = c("", "Fishing pressure", "Stock size"))
}
