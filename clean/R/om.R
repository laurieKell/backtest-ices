# Application wrappers around FLBacktest generics.
# ICES TAC bounds live in constants.R (sourced by notebooks).

.load_flbacktest_fn <- function(name) {
  if (!requireNamespace("FLBacktest", quietly = TRUE))
    stop("Install FLBacktest (devtools::load_all('C:/active/flr/backtest') ",
         "or remotes::install_github('laurieKell/FLBacktest')).",
         call. = FALSE)
  get(name, envir = asNamespace("FLBacktest"), inherits = FALSE)
}

load_om <- function(root = data_root(), envir = parent.frame(),
                    required = TRUE) {
  .load_flbacktest_fn("load_om")(root = root, envir = envir, required = required)
}

openloop_start <- function(stk, target = 1990L) {
  .load_flbacktest_fn("openloop_start")(stk, target = target)
}

require_om_gate <- function(root = data_root(), sids = NULL,
                            file = "data/results/01.1_lterm_eq.RData") {
  .load_flbacktest_fn("require_om_gate")(root = root, sids = sids, file = file)
}

#' Recruitment multipliers for a Future projection (project_hcr): 1 up to the
#' terminal year of `stk`, then exp(mean log residual) of the most recent
#' residual regime of `eql` (FLBacktest::recDevs regimes) for `nYears`.
recent_regime_mult <- function(eql, id = "stock") {
  rd <- recDevs(FLBRPs(setNames(list(eql), id)), nits = 1L)
  rg <- unique(rd$rod[, c("regime", "minyear", "maxyear", "mn")])
  rg <- rg[which.max(rg$maxyear), ]
  c(mult = exp(rg$mn), minyear = rg$minyear, maxyear = rg$maxyear)
}

recent_regime_sr <- function(stk, eql, nYears, id = "stock") {
  maxyr <- dims(stk)$maxyear
  dev <- rec(FLCore::fwdWindow(stk, eql, end = maxyr + as.integer(nYears))) %=% 1
  yrs <- ac(seq(maxyr + 1L, maxyr + as.integer(nYears)))
  dev[, yrs] <- recent_regime_mult(eql, id)[["mult"]]
  dev
}
