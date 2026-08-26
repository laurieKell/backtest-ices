# Application OM I/O — delegates to FLBacktest when the package is loaded.
# Stock dynamics stay on FLR objects (FLStock, FLBRP).

.load_flbacktest_fn <- function(name) {
  if (!requireNamespace("FLBacktest", quietly = TRUE))
    stop("Install FLBacktest (devtools::load_all('C:/active/flr/backtest') ",
         "or remotes::install_github('laurieKell/FLBacktest')).",
         call. = FALSE)
  get(name, envir = asNamespace("FLBacktest"), inherits = FALSE)
}

load_om <- function(root = "C:/active/blueMarine", envir = parent.frame(),
                    required = TRUE) {
  .load_flbacktest_fn("load_om")(root = root, envir = envir, required = required)
}

openloop_start <- function(stk, target = 1990L) {
  .load_flbacktest_fn("openloop_start")(stk, target = target)
}

require_om_gate <- function(root = "C:/active/blueMarine", sids = NULL) {
  .load_flbacktest_fn("require_om_gate")(root = root, sids = sids)
}
