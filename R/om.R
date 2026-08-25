# Load 02.0 output. Stock dynamics stay on FLR objects (`FLStock`, `FLBRP`).

load_om <- function(root = "C:/active/blueMarine", envir = parent.frame(),
                    required = TRUE) {
  oms_file  <- file.path(root, "data/om/oms.RData")
  eqls_file <- file.path(root, "data/om/eqls.RData")
  sag_file  <- file.path(root, "data/om/sag.RData")
  if (!file.exists(oms_file) || !file.exists(eqls_file)) {
    if (isTRUE(required))
      stop("Missing data/om/oms.RData or eqls.RData — knit 02.0 first.",
           call. = FALSE)
    return(invisible(FALSE))
  }
  load(oms_file, envir = envir)
  load(eqls_file, envir = envir)
  if (file.exists(sag_file))
    load(sag_file, envir = envir)
  csv <- file.path(root, "data/reference/stocks.csv")
  if (file.exists(csv)) {
    stocks <- read.csv(csv, stringsAsFactors = FALSE)
    stocks$name <- factor(stocks$name, levels = unique(stocks$name))
    assign("stocks", stocks, envir = envir)
    assign("sids", as.character(stocks$sid), envir = envir)
  }
  invisible(TRUE)
}

# Open-loop start year: FLBacktest::openloop_start (do not re-implement here).

# 02.1 / 02.2 must pass before any historical backtest (04.*).
require_om_gate <- function(root = "C:/active/blueMarine", sids = NULL) {
  f_lterm <- file.path(root, "data/results/03.3_lterm_eq.RData")
  f_dyn   <- file.path(root, "data/results/03.0_om.RData")
  if (!file.exists(f_lterm))
    stop("OM gate missing: knit 02.1_lterm_eq.Rmd first\n  ", f_lterm,
         call. = FALSE)
  if (!file.exists(f_dyn))
    stop("OM diagnostics missing: knit 02.2_dynamics.Rmd first\n  ", f_dyn,
         call. = FALSE)
  e <- new.env(parent = emptyenv())
  load(f_lterm, envir = e)
  if (!exists("lterm_eq", envir = e, inherits = FALSE))
    stop("03.3_lterm_eq.RData has no object lterm_eq", call. = FALSE)
  pass <- e$lterm_eq$pass
  if (is.null(pass) || !("pass" %in% names(pass)))
    stop("lterm_eq$pass is missing — re-knit 02.1_lterm_eq.Rmd", call. = FALSE)
  if (!is.null(sids) && "sid" %in% names(pass))
    pass <- pass[as.character(pass$sid) %in% as.character(sids), , drop = FALSE]
  failed <- pass[is.na(pass$pass) | !pass$pass, , drop = FALSE]
  if (nrow(failed)) {
    lab <- if ("sid" %in% names(failed)) as.character(failed$sid)
           else rownames(failed)
    stop("Long-term OM gate failed for: ", paste(lab, collapse = ", "),
         "\nInspect 02.1_lterm_eq / 02.2_dynamics before 04.*", call. = FALSE)
  }
  invisible(TRUE)
}
