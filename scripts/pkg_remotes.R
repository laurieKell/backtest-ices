pkgs <- c("FLCore", "FLBRP", "FLasher", "ggplotFL", "icesdata",
          "FLBacktest", "FLRebuild")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    cat(p, ": MISSING\n")
    next
  }
  d <- packageDescription(p)
  user <- if (is.null(d$RemoteUsername)) "?" else d$RemoteUsername
  repo <- if (is.null(d$RemoteRepo)) "?" else d$RemoteRepo
  sha  <- if (is.null(d$RemoteSha)) "local" else substr(d$RemoteSha, 1, 7)
  cat(sprintf("%s %s remote=%s/%s@%s\n", p, d$Version, user, repo, sha))
}
