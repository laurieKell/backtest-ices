# Migrate blueMarine renv library to R 4.6.1
# Usage (from project root, with R 4.6.1):
#   path/to/R-4.6.1/bin/Rscript.exe scripts/migrate_r461.R

options(
  repos = c(
    CRAN = "https://cloud.r-project.org",
    FLR = "https://flr.r-universe.dev"
  ),
  Ncpus = max(1L, parallel::detectCores() - 1L),
  pkgType = "both"
)

message("R version: ", R.version.string)
message("libPaths:\n", paste(" ", .libPaths(), collapse = "\n"))

if (!requireNamespace("renv", quietly = TRUE))
  install.packages("renv")

# Ensure renv itself is current for R 4.6
renv::upgrade(version = NULL, prompt = FALSE)

message("\n=== Restoring packages from renv.lock ===")
ok <- tryCatch({
  renv::restore(prompt = FALSE)
  TRUE
}, error = function(e) {
  message("restore() had errors: ", conditionMessage(e))
  FALSE
})

message("\n=== Updating packages to latest compatible versions ===")
tryCatch(
  renv::update(prompt = FALSE),
  error = function(e) message("update() errors: ", conditionMessage(e))
)

# Ensure key GitHub / r-universe packages are present at latest
gh <- c(
  "flr/FLCore@devel",
  "flr/FLBRP",
  "flr/FLasher",
  "flr/ggplotFL",
  "flr/FLRebuild",
  "laurieKell/FLBacktest"
)
message("\n=== Reinstalling FLR / FLBacktest from remotes ===")
if (!requireNamespace("remotes", quietly = TRUE))
  renv::install("remotes", prompt = FALSE)
for (pkg in gh) {
  message("Installing ", pkg, " ...")
  tryCatch(
    remotes::install_github(pkg, upgrade = "never", quiet = FALSE),
    error = function(e) message("FAILED ", pkg, ": ", conditionMessage(e))
  )
}

message("\n=== Snapshotting lockfile for R ", as.character(getRversion()), " ===")
renv::snapshot(prompt = FALSE, force = TRUE)

message("\n=== Status summary ===")
print(renv::status())
message("\nDone.")
