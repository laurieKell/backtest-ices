#!/usr/bin/env Rscript
# Main-text Figure: Historical vs Advice rule, four demonstration stocks,
# single faceted ggplot (rows = F, SSB, Recruitment, Catch; columns = stock).
#
# Replaces the 2x2 montage of the per-stock right-hand panels knitted by
# Rmd/06.0_report.Rmd (06.0_report-traj-{1..4}.png). Same series and same
# construction as those panels:
#   Historical  — assessment series through the terminal year, then the
#                 20-year HCR projection from the Historical terminal state
#   Advice rule — closed-loop hcrICES from startYr_ar (2015) on the bh3 OM,
#                 then the 20-year HCR projection from its terminal state
# x-axis: future_xmin (2000) through terminal year + 20.
#
# Uses saved pipeline objects (bh3 OM SRR; ICES control points on bh1):
#   data/om/oms.RData, data/om/eqls.RData,
#   data/results/03.2_closedLoop.RData, data/results/04.3_rebuild.RData
#
# Usage:
#   Rscript scripts/main_traj_facet.R
#
# Writes tex/figs/traj_facet.pdf (+ .png).

suppressPackageStartupMessages({
  library(FLCore)
  library(FLBRP)
  library(ggplot2)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/"))
} else if (file.exists("scripts/main_traj_facet.R")) {
  normalizePath("scripts", winslash = "/")
} else {
  normalizePath(".", winslash = "/")
}
root_guess <- dirname(script_dir)
source(file.path(root_guess, "R", "paths.R"))
source(file.path(root_guess, "R", "plot_theme.R"))
root <- bm_root(start = c(getwd(), root_guess))

# Column order in the figure (matches skeleton.tex Results prose)
case_sids <- c("cod.27.7e-k", "whg.27.7a", "cod.27.7a", "whg.27.7b-ce-k")

srr_om      <- "bh3"
startYr_ar  <- 2015L
future_xmin <- 2000L

arm_cols <- c("Historical" = "#000000", "Advice rule" = "#D55E00")

# ---- helpers (as in 06.0_report.Rmd) ----------------------------------------
set_years <- function(out, src, yrs) {
  stock.n(out)[, yrs]    <- stock.n(src)[, yrs]
  harvest(out)[, yrs]    <- harvest(src)[, yrs]
  catch.n(out)[, yrs]    <- catch.n(src)[, yrs]
  landings.n(out)[, yrs] <- landings.n(src)[, yrs]
  discards.n(out)[, yrs] <- discards.n(src)[, yrs]
  catch(out)[, yrs]      <- catch(src)[, yrs]
  landings(out)[, yrs]   <- landings(src)[, yrs]
  discards(out)[, yrs]   <- discards(src)[, yrs]
  out
}

# NA before `yr`; join to the historical series in `yr`
from_hcr <- function(stk, yr, hist) {
  out <- stk
  yrs <- as.integer(dimnames(out)$year)
  pre <- as.character(yrs[yrs < yr])
  if (length(pre)) {
    for (s in c("stock.n", "harvest", "catch.n", "landings.n", "discards.n",
                "catch", "landings", "discards"))
      slot(out, s)[, pre] <- NA
  }
  y0 <- as.character(yr)
  if (y0 %in% dimnames(hist)$year && y0 %in% dimnames(out)$year)
    out <- set_years(out, hist, y0)
  out
}

# Replace overlapping years with the source series (assessment / closed loop)
paste_hist <- function(stk, hist) {
  yrs <- intersect(dimnames(stk)$year, dimnames(hist)$year)
  if (!length(yrs)) return(stk)
  set_years(stk, hist, yrs)
}

med <- function(x) if (dims(x)$iter > 1) iterMedians(x) else x

to_df <- function(stk, arm, nm) {
  q <- FLQuants(F = med(fbar(stk)), SB = med(ssb(stk)),
                Rec = med(rec(stk)), C = med(catch(stk)))
  df <- as.data.frame(q, drop = TRUE)
  data.frame(name = nm, arm = arm, year = as.integer(df$year),
             qname = as.character(df$qname), data = df$data,
             stringsAsFactors = FALSE)
}

# ---- load -------------------------------------------------------------------
message("Loading OM and results from ", root)
load(file.path(root, "data/om/oms.RData"))
load(file.path(root, "data/om/eqls.RData"))
load(file.path(root, "data/results/03.2_closedLoop.RData"))
rebuild_file <- file.path(root, "data/results/04.3_rebuild.RData")
if (!file.exists(rebuild_file))
  stop("Knit 04.3_rebuild.Rmd first: ", rebuild_file, call. = FALSE)
load(rebuild_file)

if (!exists("stocks") || is.null(stocks))
  stocks <- read.csv(file.path(root, "data/reference/stocks.csv"),
                     stringsAsFactors = FALSE)
stocks <- stocks[match(case_sids, stocks$sid), , drop = FALSE]
stopifnot(nrow(stocks) == 4L, !anyNA(stocks$sid))
sids  <- as.character(stocks$sid)
names <- setNames(as.character(stocks$name), sids)

eqs <- eqls[["bh1"]]
ar  <- closedLoop[["SRR"]][[srr_om]]
if (is.null(ar))
  stop("closedLoop$SRR$", srr_om, " missing — knit 04.2_closedLoop.Rmd.",
       call. = FALSE)

# ---- assemble ---------------------------------------------------------------
ts   <- list()
refs <- list()
yrs  <- list()
for (id in sids) {
  nm    <- names[[id]]
  maxyr <- as.integer(dims(oms[[id]])$maxyear)

  hist_stk <- window(paste_hist(future[["Historical"]][[id]], oms[[id]]),
                     start = future_xmin)
  ar_stk   <- window(from_hcr(paste_hist(future[["Advice rule"]][[id]],
                                         ar[[id]]),
                              startYr_ar, oms[[id]]),
                     start = future_xmin)

  ts[[id]] <- rbind(to_df(hist_stk, "Historical", nm),
                    to_df(ar_stk,   "Advice rule", nm))

  rp_i <- refpts(eqs[[id]])
  rp_o <- refpts(eqls[[srr_om]][[id]])
  refs[[id]] <- data.frame(
    name  = nm,
    qname = c("SB", "SB", "SB", "F", "F", "C"),
    ref   = c("Blim", "Btrig", "Bmsy", "Ftar", "Fmsy", "MSY"),
    value = c(rp_i["Blim", "ssb"], rp_i["MSYBtrigger", "ssb"],
              rp_o["msy", "ssb"], rp_i["FMSY", "harvest"],
              rp_o["msy", "harvest"], rp_o["msy", "yield"]),
    stringsAsFactors = FALSE)
  yrs[[id]] <- data.frame(name = nm, terminal = maxyr,
                          xmax = max(as.integer(dims(hist_stk)$maxyear),
                                     as.integer(dims(ar_stk)$maxyear)),
                          stringsAsFactors = FALSE)
  message("  ", nm, ": ", future_xmin, "-", maxyr, " (+20)")
}
ts   <- do.call(rbind, ts)
refs <- do.call(rbind, refs)
yrs  <- do.call(rbind, yrs)

q_lev <- c("F", "SB", "Rec", "C")
q_lab <- c(F = "F", SB = "SSB (t)", Rec = "Recruitment", C = "Catch (t)")
n_lev <- unname(names)

ts$name   <- factor(ts$name, levels = n_lev)
ts$arm    <- factor(ts$arm, levels = names(arm_cols))
ts$qname  <- factor(ts$qname, levels = q_lev)
refs$name  <- factor(refs$name, levels = n_lev)
refs$qname <- factor(refs$qname, levels = q_lev)
yrs$name   <- factor(yrs$name, levels = n_lev)
ts <- ts[is.finite(ts$data), ]

ices_refs <- subset(refs, ref %in% c("Blim", "Btrig", "Ftar"))
om_refs   <- subset(refs, ref %in% c("Bmsy", "Fmsy", "MSY"))
ref_cols  <- c(Blim = bm_col("catch"), Btrig = bm_col("trigger"),
               Ftar = bm_col("f_target"))

# Strip: metric over stock name in each panel
panel_lab <- labeller(qname = q_lab, name = label_value, .multi_line = TRUE)

p <- ggplot(ts, aes(year, data, colour = arm)) +
  geom_vline(data = yrs, aes(xintercept = terminal),
             linetype = 3, colour = bm_col("muted"), linewidth = 0.4) +
  geom_vline(xintercept = startYr_ar, linetype = 3,
             colour = arm_cols[["Advice rule"]], linewidth = 0.4) +
  geom_hline(data = om_refs, aes(yintercept = value),
             linetype = 3, colour = bm_col("muted"), linewidth = 0.45) +
  geom_hline(data = ices_refs, aes(yintercept = value, colour = ref),
             linetype = 2, linewidth = 0.45, show.legend = FALSE) +
  geom_line(linewidth = 0.9, na.rm = TRUE) +
  # keep ICES control points inside the panel range
  geom_blank(data = ices_refs, aes(y = value, x = future_xmin),
             inherit.aes = FALSE) +
  scale_colour_manual(values = c(arm_cols, ref_cols),
                      breaks = names(arm_cols), name = NULL) +
  scale_x_continuous(breaks = seq(2000, 2050, by = 10)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05)),
                     labels = scales::label_comma()) +
  facet_wrap(vars(qname, name), ncol = 4, scales = "free_y",
             labeller = panel_lab, strip.position = "top") +
  labs(x = NULL, y = NULL) +
  theme_bluemarine(base_size = 10) +
  theme(legend.position = "bottom",
        strip.text = element_text(size = rel(0.85), lineheight = 0.95),
        panel.spacing.x = unit(0.8, "lines"),
        panel.spacing.y = unit(0.6, "lines"))

out_dir <- file.path(root, "tex", "figs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
pdf_path <- file.path(out_dir, "traj_facet.pdf")
png_path <- file.path(out_dir, "traj_facet.png")
ggsave(pdf_path, p, width = 11, height = 9)
ggsave(png_path, p, width = 11, height = 9, dpi = 150)
message("wrote ", pdf_path, "\n      ", png_path)
invisible(list(pdf = pdf_path, png = png_path, refs = refs, years = yrs))
