# SAM observation model shared by 02.4.1_sam.Rmd and 02.4.2_closedLoop_sam.Rmd.

# Append only — prepending shadows renv tidyverse binaries (breaks ggplot2/vctrs).
sam_libs <- function() {
  user_lib <- file.path(Sys.getenv("LOCALAPPDATA", unset = ""),
                        "R", "win-library",
                        paste(R.version$major,
                              strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1],
                              sep = "."))
  if (!nzchar(user_lib) || !dir.exists(user_lib))
    user_lib <- "C:/Users/lauri/AppData/Local/R/win-library/4.4"
  if (dir.exists(user_lib) && !user_lib %in% .libPaths())
    .libPaths(c(.libPaths(), user_lib))
  if (!requireNamespace("FLfse", quietly = TRUE) ||
      !requireNamespace("stockassessment", quietly = TRUE))
    stop("SAM OEM needs installed packages FLfse and stockassessment ",
         "(user library: ", user_lib, ").", call. = FALSE)
  invisible(user_lib)
}

#' Stocks run through the SAM MP although their ICES assessment is not SAM,
#' so all four case studies share one management procedure. Appended after
#' the stocks.csv SAM stocks: survey seeds depend on position.
sam_extra <- c("cod.27.7a")

#' SAM stock ids present in the OM: stocks.csv SAM assessments + sam_extra.
sam_sids <- function(oms, stocks, extra = sam_extra) {
  sam_csv <- as.character(stocks$sid[grepl("SAM", stocks$assessment)])
  sam_csv <- c(sam_csv, setdiff(extra, sam_csv))
  sids <- sam_csv[sam_csv %in% names(oms)]
  miss <- setdiff(extra, names(oms))
  if (length(miss))
    stop("sam_extra stocks not in oms: ", paste(miss, collapse = ", "),
         call. = FALSE)
  if (!length(sids))
    stop("No SAM stocks in oms / stocks.csv.", call. = FALSE)
  sids
}

#' Catch-at-age placeholders (icesdata stores missing ages as 0.001; the OM
#' carries 1e-9) set to NA so SAM treats them as missing, not as zero catch.
#' Ages with no catch in any year (e.g. haddock age 0, F = 0) keep the
#' placeholder: SAM needs a finite catch there and ~0 is correct.
#' Use on the copy passed to SAM only; the OM keeps its values.
sam_catch_tol <- 1e-3

#' Logical array (dims of catch.n) of cells to pass to SAM as NA.
sam_catch_bad <- function(stk, tol = sam_catch_tol, end = NULL) {
  x <- catch.n(stk)@.Data
  bad <- !is.finite(x) | x <= tol
  empty <- apply(bad, 1, all)
  bad[empty, , , , , ] <- FALSE
  if (!is.null(end)) {
    late <- as.integer(dimnames(x)$year) > as.integer(end)
    bad[, late, , , , ] <- FALSE
  }
  bad
}

sam_catch_na <- function(stk, tol = sam_catch_tol, end = NULL) {
  bad <- sam_catch_bad(stk, tol, end)
  cn <- catch.n(stk)
  cn@.Data[bad] <- NA
  catch.n(stk) <- cn
  stk
}

#' Survey index: catchability 1 times lognormal noise, ages without
#' recruitment and plus group.
sam_oem <- function(stk, indexCv = 0.1, nits = 1L) {
  if (nits > 1L && dims(stk)$iter == 1L)
    stk <- propagate(stk, nits)
  stock.n(stk)[is.na(stock.n(stk))] <- 1e3
  stock.n(stk) <- qmax(stock.n(stk), 1e-2)
  rng <- range(stk)
  amin <- unname(rng["min"]) + 1
  pg <- unname(rng["plusgroup"])
  if (!is.finite(pg))
    pg <- unname(rng["max"])
  amax <- pg - 1
  if (!is.finite(amin) || !is.finite(amax) || amax < amin)
    stop("SAM survey ages are empty.", call. = FALSE)
  idx <- samIndex(trim(stk, age = ac(amin:amax)))
  index(idx)[] <- 1
  index(idx) <- index(idx) %*%
    rlnorm(nits, index(idx) %=% 0, indexCv) %*%
    rlnorm(nits, index(idx)[1] %=% 0, indexCv)
  idx
}

#' Survey observations over the whole index: OM numbers times catchability.
sam_observe <- function(stk, idx) {
  ages <- dimnames(index(idx))$age
  yrs <- dimnames(index(idx))$year
  obs <- stock.n(stk)[ages, yrs]
  obs[!is.finite(obs) | obs <= 0] <- 1e-2
  index(idx) <- obs %*% index(idx)
  idx
}

# Years before the first advice year stay as survey observations.
# hcrICES multiplies the current year by Operating Model numbers, so those
# years must still be the catchability multiplier, not numbers.
sam_prime <- function(stk, idx, start, lag = 1L) {
  yrs <- as.integer(dimnames(index(idx))$year)
  hist <- yrs < (as.integer(start) - as.integer(lag))
  if (!any(hist))
    return(idx)
  ages <- dimnames(index(idx))$age
  y <- ac(yrs[hist])
  obs <- stock.n(stk)[ages, y]
  obs[!is.finite(obs) | obs <= 0] <- 1e-2
  index(idx)[, y] <- obs %*% index(idx)[, y]
  idx
}
