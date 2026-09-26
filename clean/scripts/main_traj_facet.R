#!/usr/bin/env Rscript
# Paper figure: Historical vs Advice rule, four case-study stocks.
# ggplot2 facet (rows = F, SSB, Rec, Catch; columns = stock).
# FLCore::plot is used for a lattice check of the stitched FLStocks;
# the published figure is plain ggplot2 (FLCore has no ggplot generic).
#
#   Rscript scripts/main_traj_facet.R
#
# Writes clean/tex/figs/traj_facet.pdf (+ .png).

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
here_guess <- dirname(script_dir)
source(file.path(here_guess, "R", "paths.R"))
source(file.path(here_guess, "R", "constants.R"))
here <- clean_root(start = c(getwd(), here_guess))
root <- data_root(start = c(getwd(), here))

future_xmin <- 2000L
arm_cols <- paper_cols[c("Historical", "Advice rule")]

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

need <- function(path, what) {
  if (!file.exists(path))
    stop("Missing ", what, ": ", path, call. = FALSE)
}

message("Loading OM and results from ", root)
need(file.path(root, "data/om/oms.RData"), "oms")
need(file.path(root, "data/om/eqls.RData"), "eqls")
need(file.path(root, "data/results/02.2_closedLoop.RData"), "closed loop")
need(file.path(root, "data/results/02.5_rebuild.RData"), "rebuild")
load(file.path(root, "data/om/oms.RData"))
load(file.path(root, "data/om/eqls.RData"))
load(file.path(root, "data/results/02.2_closedLoop.RData"))
load(file.path(root, "data/results/02.5_rebuild.RData"))

if (!exists("future") || is.null(future[["Historical"]]) ||
    is.null(future[["Advice rule"]]))
  stop("02.5_rebuild.RData must contain future$Historical and future$`Advice rule`.",
       call. = FALSE)

if (!exists("stocks") || is.null(stocks))
  stocks <- read.csv(file.path(root, "data/reference/stocks.csv"),
                     stringsAsFactors = FALSE)
stocks <- stocks[match(case_sids, stocks$sid), , drop = FALSE]
if (nrow(stocks) != 4L || anyNA(stocks$sid))
  stop("stocks.csv is missing one of case_sids: ",
       paste(case_sids, collapse = ", "), call. = FALSE)
sids  <- as.character(stocks$sid)
names <- setNames(as.character(stocks$name), sids)

if (!"bh1" %in% names(eqls))
  stop("eqls[['bh1']] missing.", call. = FALSE)
eqs <- eqls[["bh1"]]
ar  <- closedLoop[["SRR"]][[srr_om]]
if (is.null(ar))
  stop("closedLoop$SRR$", srr_om, " missing — knit 02.2_closedLoop.Rmd.",
       call. = FALSE)

ts   <- list()
refs <- list()
yrs  <- list()
stks_h <- list()
stks_a <- list()
for (id in sids) {
  if (is.null(oms[[id]]))
    stop("Missing oms[[", id, "]]", call. = FALSE)
  if (is.null(future[["Historical"]][[id]]) ||
      is.null(future[["Advice rule"]][[id]]) ||
      is.null(ar[[id]]))
    stop("Missing Historical / Advice-rule series for ", id, call. = FALSE)
  nm    <- names[[id]]
  maxyr <- as.integer(dims(oms[[id]])$maxyear)

  hist_stk <- window(paste_hist(future[["Historical"]][[id]], oms[[id]]),
                     start = future_xmin)
  ar_stk   <- window(from_hcr(paste_hist(future[["Advice rule"]][[id]],
                                         ar[[id]]),
                              startYr_ar, oms[[id]]),
                     start = future_xmin)
  stks_h[[nm]] <- hist_stk
  stks_a[[nm]] <- ar_stk

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

# Lattice diagnostic (FLCore::plot). Not the paper figure.
out_dir <- file.path(here, "tex", "figs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
pdf(file.path(out_dir, "traj_flcore_plot.pdf"), width = 10, height = 8)
print(FLCore::plot(FLStocks(stks_h)))
print(FLCore::plot(FLStocks(stks_a)))
dev.off()

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

period_lev <- c("Early", "Backtest", "Future")
period_fills <- c(Early = "#f0f3f5", Backtest = "#e4ebf0", Future = "#f5efe6")
periods <- do.call(rbind, lapply(seq_len(nrow(yrs)), function(i) {
  data.frame(
    name  = yrs$name[i],
    period = factor(period_lev, levels = period_lev),
    xmin  = c(future_xmin, startYr_ar, yrs$terminal[i]),
    xmax  = c(startYr_ar, yrs$terminal[i], yrs$xmax[i]),
    stringsAsFactors = FALSE)
}))
period_labs <- periods
period_labs$qname <- factor("F", levels = q_lev)
period_labs$x <- (period_labs$xmin + period_labs$xmax) / 2

panel_lab <- labeller(qname = q_lab, name = label_value, .multi_line = TRUE)

p <- ggplot(ts, aes(year, data, colour = arm)) +
  geom_rect(data = periods, aes(xmin = xmin, xmax = xmax, fill = period),
            ymin = -Inf, ymax = Inf, inherit.aes = FALSE, colour = NA) +
  geom_vline(data = yrs, aes(xintercept = terminal),
             linetype = 3, colour = paper_col("muted"), linewidth = 0.4) +
  geom_vline(xintercept = startYr_ar, linetype = 3,
             colour = arm_cols[["Advice rule"]], linewidth = 0.4) +
  geom_hline(data = om_refs, aes(yintercept = value),
             linetype = 3, colour = paper_col("muted"), linewidth = 0.45) +
  geom_hline(data = ices_refs, aes(yintercept = value),
             linetype = 2, colour = paper_col("muted"), linewidth = 0.45) +
  geom_line(linewidth = 0.9) +
  geom_text(data = period_labs, aes(x = x, y = Inf, label = period),
            inherit.aes = FALSE, vjust = 1.4, size = 2.4,
            colour = paper_col("muted")) +
  scale_colour_manual(values = arm_cols, name = NULL) +
  scale_fill_manual(values = period_fills, guide = "none") +
  scale_x_continuous(breaks = seq(2000, 2050, by = 10),
                     expand = expansion(mult = 0)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  facet_wrap(vars(qname, name), ncol = 4, scales = "free_y",
             labeller = panel_lab, strip.position = "top") +
  labs(x = NULL, y = NULL) +
  theme_paper(base_size = 10) +
  theme(strip.text = element_text(size = rel(0.8), lineheight = 0.9),
        axis.text.x = element_text(size = rel(0.8), angle = 30, hjust = 1),
        panel.spacing.x = unit(0.45, "lines"),
        panel.spacing.y = unit(0.5, "lines"))

pdf_path <- file.path(out_dir, "traj_facet.pdf")
png_path <- file.path(out_dir, "traj_facet.png")
ggsave(pdf_path, p, width = 15, height = 8.5)
ggsave(png_path, p, width = 15, height = 8.5, dpi = 150)
message("wrote ", pdf_path, "\n      ", png_path)
message("FLCore::plot diagnostic: ", file.path(out_dir, "traj_flcore_plot.pdf"))
invisible(list(pdf = pdf_path, png = png_path))
