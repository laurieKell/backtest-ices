# Historical vs Advice-rule trajectories (F, Rec, SSB, Catch) with refpts.
# Used by 02.2 / 02.3 / 02.4 closed-loop notebooks.

traj_years <- c(1990L, 2025L)

.med_flquant <- function(x) {
  if (dims(x)$iter > 1L) FLCore::iterMedians(x) else x
}

#' Long data frame of F, SSB, Rec, Catch for one FLStock.
traj_quant_df <- function(stk, arm, name, xmin = NULL) {
  if (is.null(stk))
    stop("traj_quant_df: NULL stock for arm '", arm, "'.", call. = FALSE)
  if (!is.null(xmin)) {
    xmin <- as.integer(xmin)
    y0 <- max(xmin, as.integer(dims(stk)$minyear))
    stk <- FLCore::window(stk, start = y0)
  }
  q <- FLCore::FLQuants(
    F = .med_flquant(FLCore::fbar(stk)),
    SSB = .med_flquant(FLCore::ssb(stk)),
    Rec = .med_flquant(FLCore::rec(stk)),
    Catch = .med_flquant(FLCore::catch(stk)))
  df <- as.data.frame(q, drop = TRUE)
  data.frame(
    name = as.character(name),
    arm = as.character(arm),
    year = as.integer(df$year),
    qname = as.character(df$qname),
    data = as.numeric(df$data),
    stringsAsFactors = FALSE)
}

#' Quantiles over iterations of F, SSB, Rec, Catch for one FLStock.
traj_quant_ribbon_df <- function(stk, arm, name, xmin = NULL,
                                 probs = c(0.05, 0.5, 0.95)) {
  if (!is.null(xmin))
    stk <- FLCore::window(stk, start = max(as.integer(xmin),
                                           as.integer(dims(stk)$minyear)))
  q <- list(F = FLCore::fbar(stk), SSB = FLCore::ssb(stk),
            Rec = FLCore::rec(stk), Catch = FLCore::catch(stk))
  do.call(rbind, lapply(names(q), function(nm) {
    x <- q[[nm]]@.Data
    yrs <- as.integer(dimnames(q[[nm]])$year)
    m <- matrix(x, nrow = length(yrs))
    p <- t(apply(m, 1, stats::quantile, probs = probs, na.rm = TRUE))
    data.frame(name = as.character(name), arm = as.character(arm),
               year = yrs, qname = nm,
               lo = p[, 1], data = p[, 2], hi = p[, 3],
               stringsAsFactors = FALSE)
  }))
}

#' ggplot: Historical vs multi-iteration Advice-rule runs (median + band).
#'
#' Same scaling and facets as \code{plot_hcr_vs_hist}; band = \code{probs}
#' range over iterations.
#'
#' @param advice Named list (by SRR) of FLStocks with iterations.
plot_hcr_ribbon <- function(oms, advice, sids, labels = NULL,
                            xmin = traj_years[1], xmax = traj_years[2],
                            start_ar = 2015L, probs = c(0.05, 0.5, 0.95)) {
  sids <- as.character(sids)
  rows <- list()
  for (id in sids) {
    nm <- if (!is.null(labels) && id %in% names(labels)) labels[[id]] else id
    h <- traj_quant_df(oms[[id]], "Historical", nm, xmin = xmin)
    h$lo <- h$data
    h$hi <- h$data
    rows[[length(rows) + 1L]] <- h[, c("name", "arm", "year", "qname",
                                       "lo", "data", "hi")]
    for (srr in names(advice)) {
      if (is.null(advice[[srr]][[id]]))
        stop("Missing advice[[", srr, "]][[", id, "]].", call. = FALSE)
      rows[[length(rows) + 1L]] <- traj_quant_ribbon_df(
        advice[[srr]][[id]], srr, nm, xmin = xmin, probs = probs)
    }
  }
  ts <- do.call(rbind, rows)
  ts <- ts[is.finite(ts$data) & ts$year <= as.integer(xmax), , drop = FALSE]
  n_lev <- unique(as.character(ts$name))

  hist <- ts[ts$arm == "Historical", , drop = FALSE]
  mu <- aggregate(data ~ name + qname, data = hist, FUN = function(z)
    mean(z, na.rm = TRUE))
  names(mu)[names(mu) == "data"] <- "mu"
  bad <- !is.finite(mu$mu) | mu$mu == 0
  if (any(bad))
    stop("Non-finite or zero Historical mean for: ",
         paste(paste(mu$name[bad], mu$qname[bad], sep = "/"), collapse = ", "),
         call. = FALSE)
  ts <- merge(ts, mu, by = c("name", "qname"), sort = FALSE)
  ts[, c("lo", "data", "hi")] <- ts[, c("lo", "data", "hi")] / ts$mu

  arm_lev <- c("Historical", setdiff(unique(as.character(ts$arm)), "Historical"))
  ts$arm <- factor(ts$arm, levels = arm_lev)
  ts$name <- factor(as.character(ts$name), levels = n_lev)
  ts$qname <- factor(as.character(ts$qname), levels = c("F", "SSB", "Rec", "Catch"))

  cols <- c(Historical = paper_col("Historical"))
  pal <- paper_cols[c("Advice rule", "ICES Ftar", "OM FMSY", "advice", "catch")]
  other <- setdiff(arm_lev, "Historical")
  for (i in seq_along(other))
    cols[[other[i]]] <- unname(pal[((i - 1L) %% length(pal)) + 1L])

  adv <- ts[ts$arm != "Historical", , drop = FALSE]
  ggplot2::ggplot(ts, ggplot2::aes(year, data, colour = arm)) +
    ggplot2::geom_hline(yintercept = 1, colour = paper_col("muted"),
                        linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = as.integer(start_ar), linetype = 3,
                        colour = paper_col("muted"), linewidth = 0.4) +
    ggplot2::geom_ribbon(data = adv,
                         ggplot2::aes(ymin = lo, ymax = hi, fill = arm),
                         colour = NA, alpha = 0.2) +
    ggplot2::geom_line(linewidth = 0.75) +
    ggplot2::expand_limits(y = 0) +
    ggplot2::facet_grid(qname ~ name, scales = "free_y", as.table = TRUE) +
    ggplot2::scale_x_continuous(limits = c(as.integer(xmin), as.integer(xmax))) +
    ggplot2::scale_colour_manual(values = cols) +
    ggplot2::scale_fill_manual(values = cols, guide = "none") +
    ggplot2::labs(x = NULL, y = "Relative to Historical mean", colour = NULL) +
    theme_paper()
}

#' ICES (bh1) and OM MSY reference lines for one stock.
traj_refs_df <- function(eq_ices, eq_om, name) {
  rp_i <- FLBRP::refpts(eq_ices)
  rp_o <- FLBRP::refpts(eq_om)
  data.frame(
    name = as.character(name),
    qname = c("SSB", "SSB", "SSB", "F", "F", "Catch"),
    ref = c("Blim", "Btrig", "Bmsy", "Ftar", "Fmsy", "MSY"),
    value = c(
      as.numeric(c(rp_i["Blim", "ssb"])),
      as.numeric(c(rp_i["MSYBtrigger", "ssb"])),
      as.numeric(c(rp_o["msy", "ssb"])),
      as.numeric(c(rp_i["FMSY", "harvest"])),
      as.numeric(c(rp_o["msy", "harvest"])),
      as.numeric(c(rp_o["msy", "yield"]))),
    stringsAsFactors = FALSE)
}

#' ggplot: Historical FLStock vs Advice-rule FLStock(s).
#'
#' Each stock\times metric series is divided by the mean of the Historical
#' series for that stock and metric (plotted years), so stocks within a row
#' share a relative \(y\)-scale from 0; each row (F, SSB, Rec, Catch) has its
#' own \(y\)-range. Columns = stock. Colour = arm.
#'
#' @param oms Named list / FLStocks of historical assessments.
#' @param advice Either FLStocks (one SRR) or a named list of FLStocks by SRR.
#' @param eqs FLBRPs with ICES benchmarks (usually eqls[["bh1"]]).
#' @param eql_om FLBRPs for OM MSY refs (one SRR), or named list matching
#'   \code{advice} when several SRRs are plotted.
#' @param sids Stock ids to plot.
#' @param labels Optional named character vector of display names.
#' @param xmin First year on the x-axis.
#' @param xmax Last year on the x-axis.
#' @param start_ar Year the Advice rule departs from history (vertical line).
#' @param advice_lab Legend label when \code{advice} is a single FLStocks.
#' @param arm_fmt sprintf format for arm labels when \code{advice} is a list
#'   (\code{"\%s"} uses the list names as-is). Arms named in
#'   \code{paper_cols} take that colour.
plot_hcr_vs_hist <- function(oms, advice, eqs, eql_om, sids,
                             labels = NULL, xmin = traj_years[1],
                             xmax = traj_years[2],
                             start_ar = 2015L,
                             advice_lab = "Advice rule",
                             arm_fmt = "Advice (%s)") {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("plot_hcr_vs_hist needs ggplot2.", call. = FALSE)

  multi <- is.list(advice) && !is(advice, "FLStocks")
  if (multi) {
    srr_nms <- names(advice)
    if (!length(srr_nms))
      stop("plot_hcr_vs_hist: advice list has no names.", call. = FALSE)
  } else {
    srr_nms <- advice_lab
    advice <- setNames(list(advice), advice_lab)
    if (is(eql_om, "FLBRPs") || is.list(eql_om))
      eql_om <- setNames(list(eql_om), advice_lab)
  }

  sids <- as.character(sids)
  rows <- list()
  refs <- list()
  for (id in sids) {
    nm <- if (!is.null(labels) && id %in% names(labels))
      labels[[id]]
    else if (!is.null(oms[[id]]) && nzchar(name(oms[[id]])))
      name(oms[[id]])
    else id
    if (is.null(oms[[id]]))
      stop("Missing historical stock oms[[", id, "]].", call. = FALSE)
    if (is.null(eqs[[id]]))
      stop("Missing eqs[[", id, "]].", call. = FALSE)

    rows[[length(rows) + 1L]] <- traj_quant_df(
      oms[[id]], "Historical", nm, xmin = xmin)

    for (srr in srr_nms) {
      adv <- advice[[srr]]
      if (is.null(adv) || is.null(adv[[id]]))
        stop("Missing advice[[", srr, "]][[", id, "]].", call. = FALSE)
      arm <- if (multi) sprintf(arm_fmt, srr) else advice_lab
      rows[[length(rows) + 1L]] <- traj_quant_df(
        adv[[id]], arm, nm, xmin = xmin)
    }

    eq_om_one <- if (multi) {
      e0 <- eql_om[[srr_nms[[1]]]]
      if (is.null(e0)) eql_om else e0
    } else {
      e0 <- eql_om[[advice_lab]]
      if (is.null(e0)) eql_om else e0
    }
    if (is.null(eq_om_one[[id]]))
      stop("Missing OM FLBRP for ", id, call. = FALSE)
    refs[[id]] <- traj_refs_df(eqs[[id]], eq_om_one[[id]], nm)
  }

  ts <- do.call(rbind, rows)
  rf <- do.call(rbind, refs)
  q_lev <- c("F", "SSB", "Rec", "Catch")
  q_lab <- c(F = "F", SSB = "SSB", Rec = "Rec", Catch = "Catch")
  n_lev <- unique(as.character(ts$name))
  ts <- ts[is.finite(ts$data) & ts$year <= as.integer(xmax), , drop = FALSE]

  # Scale each stock × metric by the Historical mean (plotted window).
  hist <- ts[ts$arm == "Historical", , drop = FALSE]
  mu <- aggregate(data ~ name + qname, data = hist, FUN = function(z)
    mean(z, na.rm = TRUE))
  names(mu)[names(mu) == "data"] <- "mu"
  bad <- !is.finite(mu$mu) | mu$mu == 0
  if (any(bad))
    stop("Non-finite or zero Historical mean for: ",
         paste(paste(mu$name[bad], mu$qname[bad], sep = "/"), collapse = ", "),
         call. = FALSE)
  ts <- merge(ts, mu, by = c("name", "qname"), sort = FALSE)
  ts$data <- ts$data / ts$mu
  rf <- merge(rf, mu, by = c("name", "qname"), sort = FALSE)
  rf$value <- rf$value / rf$mu
  rf <- rf[is.finite(rf$value), , drop = FALSE]

  arm_lev <- unique(as.character(ts$arm))
  arm_lev <- c("Historical", setdiff(arm_lev, "Historical"))
  ts$arm <- factor(ts$arm, levels = arm_lev)
  # First factor level is the top row in facet_grid(..., as.table = TRUE).
  ts$name <- factor(as.character(ts$name), levels = n_lev)
  rf$name <- factor(as.character(rf$name), levels = n_lev)
  ts$qname <- factor(as.character(ts$qname), levels = q_lev)
  rf$qname <- factor(as.character(rf$qname), levels = q_lev)

  ices_rf <- subset(rf, ref %in% c("Blim", "Btrig", "Ftar"))
  om_rf <- subset(rf, ref %in% c("Bmsy", "Fmsy", "MSY"))

  cols <- c(Historical = paper_col("Historical"))
  other <- setdiff(arm_lev, "Historical")
  pal <- paper_cols[c("Advice rule", "ICES Ftar", "OM FMSY", "advice", "catch")]
  for (i in seq_along(other))
    cols[[other[i]]] <- if (other[i] %in% names(paper_cols))
      unname(paper_cols[[other[i]]])
    else unname(pal[((i - 1L) %% length(pal)) + 1L])

  ggplot2::ggplot(ts, ggplot2::aes(year, data, colour = arm)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 1,
                        colour = paper_col("muted"), linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = as.integer(start_ar), linetype = 3,
                        colour = paper_col("muted"), linewidth = 0.4) +
    ggplot2::geom_hline(data = ices_rf,
                        ggplot2::aes(yintercept = value, linetype = ref),
                        colour = paper_col("trigger"), linewidth = 0.35,
                        inherit.aes = FALSE) +
    ggplot2::geom_hline(data = om_rf,
                        ggplot2::aes(yintercept = value, linetype = ref),
                        colour = paper_col("muted"), linewidth = 0.35,
                        inherit.aes = FALSE) +
    ggplot2::geom_line(linewidth = 0.75) +
    ggplot2::expand_limits(y = 0) +
    ggplot2::facet_grid(qname ~ name, scales = "free_y", as.table = TRUE,
                        labeller = ggplot2::labeller(qname = q_lab)) +
    ggplot2::scale_x_continuous(limits = c(as.integer(xmin), as.integer(xmax))) +
    ggplot2::scale_colour_manual(values = cols) +
    ggplot2::scale_linetype_manual(
      values = c(Blim = "dotted", Btrig = "dashed", Bmsy = "dotdash",
                 Ftar = "dashed", Fmsy = "dotdash", MSY = "dotdash"),
      breaks = c("Blim", "Btrig", "Bmsy", "Ftar", "Fmsy", "MSY"),
      name = "Ref.") +
    ggplot2::labs(x = NULL, y = "Relative to Historical mean", colour = NULL) +
    theme_paper() +
    ggplot2::theme(legend.box = "vertical")
}
