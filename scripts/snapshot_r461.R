lib <- "C:/active/blueMarine/renv/library/windows/R-4.6/x86_64-w64-mingw32"
.libPaths(c(lib, .libPaths()))
setwd("C:/active/blueMarine")

message("R: ", R.version.string)

pkgs <- c(
  "FLCore", "FLBRP", "FLasher", "FLBacktest", "ggplotFL",
  "icesdata", "FLRebuild", "ggh4x", "ggplot2", "TMB", "knitr",
  "reshape2", "dplyr", "renv"
)
for (p in pkgs) {
  ok <- requireNamespace(p, quietly = TRUE)
  cat(sprintf("%-12s %s\n", p, if (ok) "OK" else "FAIL"))
}

# Activate and snapshot
source("renv/activate.R")
status <- renv::status()
print(status)

message("\nSnapshotting...")
renv::snapshot(prompt = FALSE)

lf <- jsonlite::fromJSON("renv.lock", simplifyVector = FALSE)
cat("\nlockfile R:", lf$R$Version, "\n")
cat("FLRebuild in lock:", !is.null(lf$Packages$FLRebuild), "\n")
if (!is.null(lf$Packages$FLRebuild)) {
  cat("  Version:", lf$Packages$FLRebuild$Version, "\n")
  cat("  Source:", lf$Packages$FLRebuild$Source, "\n")
  if (!is.null(lf$Packages$FLRebuild$RemoteUrl))
    cat("  RemoteUrl:", lf$Packages$FLRebuild$RemoteUrl, "\n")
  if (!is.null(lf$Packages$FLRebuild$RemoteSha))
    cat("  RemoteSha:", lf$Packages$FLRebuild$RemoteSha, "\n")
}
