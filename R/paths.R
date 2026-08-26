# Project root detection (portable across machines)

#' Find the blueMarine repository root
#'
#' Looks upward from the working directory (and the current knitr input,
#' when knitting) for \code{data/reference/stocks.csv}.
#'
#' @param start Optional character vector of directories to start from.
#' @return Normalised absolute path to the project root.
#' @export
bm_root <- function(start = NULL) {
  markers <- c("data/reference/stocks.csv", "scripts/run_pipeline.R")
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
    for (i in seq_len(8L)) {
      if (all(file.exists(file.path(d, markers))))
        return(d)
      parent <- dirname(d)
      if (identical(parent, d)) break
      d <- parent
    }
  }
  stop("Cannot find blueMarine root (need data/reference/stocks.csv). ",
       "Set the working directory to the repo or knit from Rmd/.",
       call. = FALSE)
}
