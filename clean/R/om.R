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
