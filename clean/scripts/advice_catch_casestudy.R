#!/usr/bin/env Rscript
# Paper figure: ICES advised catch (ASD) vs reported catch (SAG).
# Four case-study stocks, 2010 onward.
#
#   Rscript scripts/advice_catch_casestudy.R
#
# Writes clean/tex/figs/advice_catch_casestudy.pdf (+ .png).
# Needs network access to asd.ices.dk and clean/data/om/sag.RData.

suppressPackageStartupMessages({
  library(ggplot2)
  library(jsonlite)
})

.script_name <- "advice_catch_casestudy.R"
.script_path <- local({
  for (i in rev(seq_len(sys.nframe()))) {
    ofile <- sys.frame(i)$ofile
    if (!is.null(ofile) && nzchar(ofile) &&
        identical(basename(ofile), .script_name) && file.exists(ofile))
      return(normalizePath(ofile, winslash = "/", mustWork = TRUE))
  }
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    p <- sub("^--file=", "", file_arg[[1]])
    if (file.exists(p) && identical(basename(p), .script_name))
      return(normalizePath(p, winslash = "/", mustWork = TRUE))
  }
  for (cand in c("scripts/advice_catch_casestudy.R",
                 "clean/scripts/advice_catch_casestudy.R")) {
    if (file.exists(cand))
      return(normalizePath(cand, winslash = "/", mustWork = TRUE))
  }
  stop("Cannot locate scripts/advice_catch_casestudy.R. ",
       "Rscript it from clean/, or source() the full path.",
       call. = FALSE)
})
script_dir <- dirname(.script_path)
here_guess <- dirname(script_dir)
source(file.path(here_guess, "R", "paths.R"))
source(file.path(here_guess, "R", "constants.R"))
here <- clean_root(start = c(here_guess, getwd()))
root <- data_root(start = c(here, here_guess, getwd()))

ensure_seed_inputs(root)
stocks <- read.csv(file.path(root, "data/reference/stocks.csv"),
                   stringsAsFactors = FALSE)
stocks <- stocks[match(case_sids, stocks$sid), , drop = FALSE]
if (nrow(stocks) != length(case_sids) || anyNA(stocks$sid))
  stop("stocks.csv missing case_sids: ",
       paste(case_sids, collapse = ", "), call. = FALSE)
stocks$name <- factor(as.character(stocks$name),
                      levels = as.character(stocks$name))
sids <- as.character(stocks$sid)

sag_path <- file.path(root, "data/om/sag.RData")
if (!file.exists(sag_path))
  stop("Missing ", sag_path, " — knit 01.0_condition_om.Rmd first.",
       call. = FALSE)
load(sag_path)
if (is.null(sag$ts) || !all(c("sid", "assYear", "year", "catch") %in% names(sag$ts)))
  stop("sag$ts must have sid, assYear, year, catch.", call. = FALSE)

advice <- do.call(rbind, lapply(sids, function(sid) {
  url <- paste0("https://asd.ices.dk/API/getAdviceViewRecord?StockCode=",
                utils::URLencode(sid, reserved = TRUE))
  d <- tryCatch(jsonlite::fromJSON(url), error = function(e)
    stop("Advice API failed for ", sid, ": ", conditionMessage(e),
         call. = FALSE))
  if (is.null(d) || !NROW(d))
    stop("Advice API returned no rows for ", sid, call. = FALSE)
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  data.frame(
    sid        = sid,
    assYear    = as.integer(d$assessmentYear),
    adviceYear = as.integer(substr(as.character(d$adviceApplicableFrom), 1, 4)),
    advice     = suppressWarnings(as.numeric(d$adviceValue)),
    stringsAsFactors = FALSE)
}))
advice <- subset(advice, is.finite(adviceYear) & is.finite(advice))

latest_ass <- aggregate(assYear ~ sid, data = sag$ts, FUN = max)
reported <- merge(sag$ts, latest_ass, by = c("sid", "assYear"))
reported <- reported[reported$sid %in% sids, , drop = FALSE]

advice_plot <- rbind(
  data.frame(sid = advice$sid, year = advice$adviceYear,
             series = "ICES advice", data = advice$advice,
             stringsAsFactors = FALSE),
  data.frame(sid = reported$sid, year = reported$year,
             series = "Reported catch", data = reported$catch,
             stringsAsFactors = FALSE))
advice_plot <- subset(advice_plot, year >= 2010 & is.finite(data))
advice_plot <- merge(advice_plot, stocks[, c("sid", "name")], by = "sid")
advice_plot$name <- factor(advice_plot$name, levels = levels(stocks$name))
advice_plot$series <- factor(advice_plot$series,
                             levels = c("Reported catch", "ICES advice"))

p <- ggplot(advice_plot, aes(year, data, colour = series, linetype = series)) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 1.2, alpha = 0.9) +
  scale_colour_manual(values = c(
    "ICES advice" = paper_col("advice"),
    "Reported catch" = paper_col("catch"))) +
  scale_linetype_manual(values = c(
    "ICES advice" = "dashed",
    "Reported catch" = "solid")) +
  facet_grid(name ~ ., scales = "free_y") +
  labs(x = NULL, y = "Catch (t)", colour = NULL, linetype = NULL) +
  theme_paper()

out_dir <- file.path(here, "tex", "figs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
pdf_path <- file.path(out_dir, "advice_catch_casestudy.pdf")
png_path <- file.path(out_dir, "advice_catch_casestudy.png")
ggsave(pdf_path, p, width = 10, height = 8)
ggsave(png_path, p, width = 10, height = 8, dpi = 150)
message("wrote ", pdf_path)
message("      ", png_path)
