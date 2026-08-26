# Reinstall FLRebuild from GitHub and refresh renv.lock (no Local source).
lib <- "C:/active/blueMarine/renv/library/windows/R-4.6/x86_64-w64-mingw32"
.libPaths(c(lib, .libPaths()))
setwd("C:/active/blueMarine")

Sys.setenv(
  PATH = paste(
    "C:/rtools45/usr/bin",
    "C:/rtools45/x86_64-w64-mingw32.static.posix/bin",
    Sys.getenv("PATH"),
    sep = ";"
  )
)

message("R: ", R.version.string)
message("Installing flr/FLRebuild from GitHub...")

remotes::install_github(
  "flr/FLRebuild",
  lib = lib,
  upgrade = "never",
  force = TRUE,
  dependencies = TRUE
)

ok <- requireNamespace("FLRebuild", quietly = TRUE)
stopifnot(ok)
message("FLRebuild ", packageVersion("FLRebuild"), " loads OK")

source("renv/activate.R")
renv::record(list(FLRebuild = "flr/FLRebuild"))
renv::snapshot(prompt = FALSE)

lf <- jsonlite::fromJSON("renv.lock", simplifyVector = FALSE)
pkg <- lf$Packages$FLRebuild
cat("lock Source:", pkg$Source, "\n")
cat("lock Version:", pkg$Version, "\n")
cat("lock RemoteUsername:", pkg$RemoteUsername, "\n")
cat("lock RemoteRepo:", pkg$RemoteRepo, "\n")
cat("lock RemoteSha:", substr(as.character(pkg$RemoteSha), 1, 12), "\n")
url <- pkg$RemoteUrl
if (!is.null(url) && grepl("active[/\\\\]flr|:[\\\\/]", url) && !grepl("github\\.com", url)) {
  stop("Still pointing at a local path: ", url)
}
message("Done.")
