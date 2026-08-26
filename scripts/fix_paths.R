#!/usr/bin/env Rscript
# One-off normaliser: portable root + drop local devtools::load_all paths.
root <- normalizePath(".", winslash = "/")
rmds <- list.files(file.path(root, "Rmd"), pattern = "\\.Rmd$", full.names = TRUE)
knitr_prefix <- 'source(if (file.exists("../R/paths.R")) "../R/paths.R" else "R/paths.R")\nroot <- bm_root()\n'

for (f in rmds) {
  x <- readLines(f, warn = FALSE)
  orig <- x
  x <- gsub('root\\s*<-\\s*"C:/active/blueMarine"', 'root <- bm_root()', x)
  x <- gsub('root\\s*=?\\s*"C:/active/blueMarine"', 'root <- bm_root()', x)
  x <- gsub("source\\(\"C:/active/blueMarine/R/loadStocks.R\"\\)",
            'source(file.path(root, "R/loadStocks.R"))', x)
  # Drop load_all lines / blocks
  x <- x[!grepl('load_all\\("C:/active/flr/', x)]
  x <- x[!grepl('dir\\.exists\\("C:/active/flr/', x)]
  x <- x[!grepl('^if \\(!exists\\("project_hcr"', x)]
  x <- x[!grepl('^\\s*else\\s*$', x) | !grepl('library\\(ggplotFL\\)', x)]
  # Insert paths.R before first bm_root() if missing
  if (any(grepl('root <- bm_root\\(\\)', x)) &&
      !any(grepl('paths\\.R', x))) {
    i <- which(grepl('root <- bm_root\\(\\)', x))[1L]
    x <- c(x[seq_len(i - 1L)], strsplit(knitr_prefix, "\n")[[1L]], x[i:length(x)])
  }
  if (!identical(x, orig)) {
    writeLines(x, f, useBytes = TRUE)
    message("updated ", basename(f))
  }
}
