# Multi-iteration SAM closed loop (02.4.3_closedLoop_sam_mc.Rmd).
# FLR_SAM fits one iteration at a time, so each (SRR, stock, iteration) is a
# separate single-iteration hcrICES run. Workers load the OM from disk and
# build their own survey from a seed: shipping FLIndex to a PSOCK worker has
# produced non-finite optim failures.

#' Load packages, helpers and OM into a worker's global environment.
sam_mc_init <- function(here, root, libs) {
  Sys.setenv(ICES_BACKTEST_DATA = root, ICES_BACKTEST_CLEAN = here)
  .libPaths(libs)
  g <- globalenv()
  for (f in c("paths.R", "constants.R", "om.R", "sam_oem.R", "sam_mc.R"))
    sys.source(file.path(here, "R", f), envir = g)
  sam_libs()
  suppressPackageStartupMessages({
    library(FLCore); library(FLBRP); library(FLasher)
    library(FLBacktest); library(FLfse); library(stockassessment)
  })
  options(FLfse.sam.q = 1)
  load(file.path(root, "data/om/oms.RData"), envir = g)
  load(file.path(root, "data/om/eqls.RData"), envir = g)
  if (!exists("eqs", envir = g))
    assign("eqs", g$eqls[["bh1"]], envir = g)
  invisible(TRUE)
}

#' Survey seed: depends on stock and iteration only, so the SRRs share the
#' same observation noise (common random numbers). A retry after a failed fit
#' draws a new survey, which breaks common random numbers for that run only.
sam_mc_seed <- function(id, iter, sids, attempt = 1L)
  100000L + 1000L * match(id, sids) + as.integer(iter) +
    1000000L * (as.integer(attempt) - 1L)

sam_mc_file <- function(out, srr, id, iter)
  file.path(out, sprintf("%s_%s_%03d.rds", srr, id, as.integer(iter)))

#' One single-iteration SAM closed loop; cached as .rds in `out`.
#' Uses oms, eqls, eqs from the calling (worker) global environment.
#' A failed run is retried with a new survey seed up to `attempts` times; the
#' attempt used is stored as attr "seed_attempt" on the saved FLStock.
sam_mc_job <- function(srr, id, iter, sids, indexCv, start, bndTac, bndWhen,
                       out, attempts = 3L) {
  f <- sam_mc_file(out, srr, id, iter)
  if (file.exists(f))
    return(list(ok = TRUE, srr = srr, id = id, iter = iter, msg = "cached"))
  msgs <- character(0)
  for (a in seq_len(attempts)) {
    res <- sam_mc_try(srr, id, iter, sids, indexCv, start, bndTac, bndWhen, a)
    if (!inherits(res, "error")) {
      attr(res, "seed_attempt") <- a
      saveRDS(res, f)
      return(list(ok = TRUE, srr = srr, id = id, iter = iter,
                  msg = if (a == 1L) "run" else
                    sprintf("run (attempt %d; %s)", a,
                            paste(msgs, collapse = " | "))))
    }
    msgs <- c(msgs, conditionMessage(res))
  }
  list(ok = FALSE, srr = srr, id = id, iter = iter,
       msg = paste(msgs, collapse = " | "))
}

sam_mc_try <- function(srr, id, iter, sids, indexCv, start, bndTac, bndWhen,
                       attempt) {
  g <- globalenv()
  tryCatch({
    stk <- g$oms[[id]]
    eql <- g$eqls[[srr]][[id]]
    set.seed(sam_mc_seed(id, iter, sids, attempt))
    idx <- sam_oem(stk, indexCv = indexCv, nits = 1L)
    idx <- sam_prime(stk, idx, start = start, lag = 1L)
    run <- hcrICES(sam_catch_na(stk, end = start), eql = eql,
                   sr_deviances = srResiduals(eql),
                   params = hcrParams(g$eqs[[id]]),
                   start = start, end = dims(stk)$maxyear,
                   lag = 1, interval = 1,
                   err = idx, implErr = 0,
                   bndTac = bndTac, bndWhen = bndWhen)[[1]]
    pre <- ac(dims(stk)$minyear:start)
    catch.n(run)[, pre] <- catch.n(stk)[, pre]
    if (any(is.na(catch.n(run))))
      stop("NA catch.n left in projected years.")
    run
  }, error = function(e) e)
}

#' Read cached single-iteration runs and bind them along iter.
#' attr "seed_attempt" on the result gives the survey-seed attempt per iter.
sam_mc_collect <- function(out, srr, id, iters) {
  runs <- lapply(iters, function(i) {
    f <- sam_mc_file(out, srr, id, i)
    if (!file.exists(f))
      stop("Missing run ", f, call. = FALSE)
    readRDS(f)
  })
  att <- vapply(runs, function(x) {
    a <- attr(x, "seed_attempt")
    if (is.null(a)) 1L else as.integer(a)
  }, integer(1))
  stk <- propagate(runs[[1]], length(runs))
  for (i in seq_along(runs)[-1])
    iter(stk, i) <- runs[[i]]
  attr(stk, "seed_attempt") <- setNames(att, iters)
  stk
}
