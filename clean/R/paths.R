# Clean tree paths.
#   clean_root() — this folder (Rmd, scripts, tex drafts, figures).
#   data_root()  — same by default, so notebooks use clean/data/…
#
# Override with ICES_BACKTEST_DATA / ICES_BACKTEST_CLEAN if needed.

# renv sandbox hides the user win-library (FLR, FLfse, stockassessment, …).
# Append — never prepend — so project/renv packages win. Prepending a stale
# user-library binary (e.g. vctrs.dll) breaks ggplot2 with
# "The specified procedure could not be found".
.ensure_user_lib <- function() {
  ver <- paste(R.version$major,
               strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1],
               sep = ".")
  candidates <- c(
    file.path(Sys.getenv("LOCALAPPDATA", unset = ""), "R", "win-library", ver),
    "C:/Users/lauri/AppData/Local/R/win-library/4.4",
    Sys.getenv("R_LIBS_USER", unset = "")
  )
  for (lib in unique(candidates[nzchar(candidates)])) {
    if (dir.exists(lib) && !lib %in% .libPaths())
      .libPaths(c(.libPaths(), lib))
  }
  invisible(.libPaths())
}
.ensure_user_lib()

.walk_for <- function(markers, start = NULL, n = 10L) {
  starts <- unique(c(
    start,
    getwd(),
    if (requireNamespace("knitr", quietly = TRUE)) {
      inp <- tryCatch(knitr::current_input(dir = TRUE), error = function(e) NULL)
      if (!is.null(inp) && nzchar(inp)) dirname(inp) else NULL
    }
  ))
  starts <- starts[!is.null(starts) & nzchar(starts)]
  for (s in starts) {
    d <- normalizePath(s, winslash = "/", mustWork = FALSE)
    for (i in seq_len(n)) {
      if (all(file.exists(file.path(d, markers))))
        return(d)
      parent <- dirname(d)
      if (identical(parent, d)) break
      d <- parent
    }
  }
  NULL
}

clean_root <- function(start = NULL) {
  env <- Sys.getenv("ICES_BACKTEST_CLEAN", unset = "")
  if (nzchar(env))
    return(normalizePath(env, winslash = "/", mustWork = TRUE))
  # Prefer an explicit start, then clean/ under the working directory,
  # then walk upward for the clean markers.
  candidates <- unique(c(
    start,
    file.path(getwd(), "clean"),
    getwd()
  ))
  found <- .walk_for(c("FLBacktest-NOTES.md", "R/paths.R"), start = candidates)
  if (is.null(found))
    stop("Cannot find clean/ (need FLBacktest-NOTES.md). ",
         "Set ICES_BACKTEST_CLEAN or knit from clean/Rmd/.",
         call. = FALSE)
  found
}

data_root <- function(start = NULL) {
  env <- Sys.getenv("ICES_BACKTEST_DATA", unset = "")
  if (nzchar(env))
    return(normalizePath(env, winslash = "/", mustWork = TRUE))
  # Default: data live under clean/data (not the parent blueMarine/data).
  here <- clean_root(start = start)
  dir.create(file.path(here, "data"), recursive = TRUE, showWarnings = FALSE)
  here
}

# Alias used by notebooks/scripts.
bm_root <- function(start = NULL) data_root(start = start)
