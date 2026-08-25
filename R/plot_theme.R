# Shared ggplot theme and scales for blueMarine figures

#' Project colour palette
bm_palette <- function() {
  c(
    advice    = "#1b4f72",
    catch     = "#c0392b",
    sag       = "#1b4f72",
    flstock   = "#c0392b",
    actual    = "#c0392b",
    geomean   = "#1b4f72",
    devs      = "#148f77",
    ink       = "#2c3e50",
    muted     = "#566573",
    ref_line  = "#d5d8dc",
    ref_strong = "#95a5a6",
    trigger    = "#e67e22",
    f_target   = "#27ae60",
    strip_fill = "#ecf0f1",
    strip_border = "#bdc3c7",
    grid_major = "#ecf0f1")}

bm_col <- function(...) {
  pal <- bm_palette()
  x <- c(...)
  unname(pal[match(x, names(pal))])
}

#' Facet row order for scaled comparison plots
qname_levels <- function() {
  c("SSB/MSYBtrigger", "F/FMSY", "R/mean", "C/MSY")
}

qname_levels_grid <- function() {
  c("F/FMSY", "SSB/MSYBtrigger", "R/mean", "C/MSY")
}

#' Base theme — clean panels, legible facets, bottom legend
theme_bluemarine <- function(base_size = 11, facet_x_angle = 0) {
  pal <- bm_palette()
  ggplot2::theme_bw(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = pal["grid_major"], linewidth = 0.35),
      panel.border = ggplot2::element_rect(
        colour = pal["strip_border"], linewidth = 0.45),
      strip.background = ggplot2::element_rect(
        fill = pal["strip_fill"], colour = pal["strip_border"],
        linewidth = 0.45),
      strip.text = ggplot2::element_text(
        face = "bold", colour = pal["ink"], size = ggplot2::rel(0.92)),
      axis.title = ggplot2::element_text(colour = pal["ink"]),
      axis.text = ggplot2::element_text(colour = pal["muted"],
                                        size = ggplot2::rel(0.88)),
      axis.text.x = ggplot2::element_text(
        angle = facet_x_angle,
        hjust = if (facet_x_angle > 0) 1 else 0.5),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      legend.key.width = grid::unit(1.1, "cm"),
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.9)),
      plot.margin = ggplot2::margin(6, 8, 6, 8))
}

theme_bluemarine_html <- function() {
  theme_bluemarine(base_size = 12, facet_x_angle = 0)
}

theme_bluemarine_latex <- function() {
  theme_bluemarine(base_size = 10, facet_x_angle = 45)
}

theme_bluemarine_facet <- function(base_size = 11) {
  theme_bluemarine(base_size = base_size, facet_x_angle = 45)
}

#' Rotate \code{facet_grid} row strip labels sideways (left strip)
#'
#' Use with \code{facet_grid(..., switch = "y")} so row labels sit on the left
#' and read bottom-to-top.
theme_facet_rows_rotated <- function(angle = 90, size = ggplot2::rel(1)) {
  ggplot2::theme(
    strip.placement = "outside",
    strip.text.y = ggplot2::element_text(
      angle = angle, hjust = 0.5, vjust = 0.5, size = size),
    strip.text.y.left = ggplot2::element_text(
      angle = angle, hjust = 0.5, vjust = 0.5, size = size))
}

#' Theme tuned for multi-stock projection grids
theme_projections <- function(base_size = 13, facet_x_angle = 45) {
  theme_bluemarine(base_size = base_size, facet_x_angle = facet_x_angle) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(size = ggplot2::rel(1)),
      strip.text.x = ggplot2::element_text(size = ggplot2::rel(1)),
      axis.text = ggplot2::element_text(size = ggplot2::rel(0.95)),
      legend.text = ggplot2::element_text(size = ggplot2::rel(1)))
}

geom_bm_refline <- function(yintercept = 1, ...) {
  ggplot2::geom_hline(
    yintercept = yintercept,
    linewidth = 0.35,
    colour = bm_col("ref_strong"),
    ...)
}

#' Reference-line positions for scaled projection panels (by stock facet)
projection_ref_lines <- function(cmp) {
  if (!("name" %in% names(cmp)) && ("stock" %in% names(cmp)))
    cmp$name <- cmp$stock
  if (!all(c("name", "qname") %in% names(cmp))) return(NULL)
  rp <- unique(cmp[, intersect(c("sid", "name", "msybtrigger", "blim"),
                               names(cmp)), drop = FALSE])
  if (!nrow(rp)) return(NULL)

  q_ssb <- "SSB/MSYBtrigger"
  q_f   <- "F/FMSY"
  pieces <- list()

  ok <- rp[is.finite(rp$msybtrigger) & rp$msybtrigger > 0, , drop = FALSE]
  if (nrow(ok)) {
    pieces$trigger <- data.frame(
      name = ok$name, qname = q_ssb, yintercept = 1,
      kind = "trigger", stringsAsFactors = FALSE)
    if ("blim" %in% names(ok)) {
      bl <- ok[is.finite(ok$blim) & ok$blim > 0, , drop = FALSE]
      if (nrow(bl)) {
        pieces$blim <- data.frame(
          name = bl$name, qname = q_ssb,
          yintercept = bl$blim / bl$msybtrigger,
          kind = "blim", stringsAsFactors = FALSE)
      }
    }
  }

  pieces$f_target <- data.frame(
    name = unique(rp$name), qname = q_f, yintercept = 1,
    kind = "f_target", stringsAsFactors = FALSE)

  out <- do.call(rbind, pieces)
  rownames(out) <- NULL
  out
}

#' Add \eqn{B_{\lim}}, MSY \eqn{B_{\mathrm{trigger}}}, and \eqn{F_{\mathrm{target}}}
#' reference lines to a projection ggplot
add_projection_reflines <- function(p, cmp) {
  rl <- projection_ref_lines(cmp)
  if (is.null(rl) || !nrow(rl)) return(p)
  if (!is.null(cmp$name))
    rl$name <- factor(rl$name, levels = levels(cmp$name))
  if (!is.null(cmp$qname))
    rl$qname <- factor(rl$qname, levels = levels(cmp$qname))

  p +
    ggplot2::geom_hline(
      data = subset(rl, kind == "blim"),
      ggplot2::aes(yintercept = yintercept),
      colour = bm_col("catch"), linewidth = 0.45, inherit.aes = FALSE) +
    ggplot2::geom_hline(
      data = subset(rl, kind == "trigger"),
      ggplot2::aes(yintercept = yintercept),
      colour = bm_col("trigger"), linewidth = 0.45, inherit.aes = FALSE) +
    ggplot2::geom_hline(
      data = subset(rl, kind == "f_target"),
      ggplot2::aes(yintercept = yintercept),
      colour = bm_col("f_target"), linewidth = 0.45, inherit.aes = FALSE)
}

#' Shade SSB below \eqn{B_{\mathrm{MSY}}} and \eqn{F} above \eqn{F_{\mathrm{MSY}}}
#'
#' Prepends a \code{geom_rect} so the band sits behind trajectories and
#' reference lines. \code{qname} must match the ggplotFL facet names
#' (default \code{SSB} and \code{F}).
shade_msy_status <- function(p, xmin, xmax, bmsy, fmsy,
                             q_ssb = "SSB", q_f = "F",
                             fill = "red", alpha = 0.12) {
  if (is.null(p$data) || !("qname" %in% names(p$data)))
    stop("plot data must contain qname (ggplotFL time series).", call. = FALSE)
  qlev <- if (is.factor(p$data$qname)) levels(p$data$qname)
          else unique(as.character(p$data$qname))
  if (!q_ssb %in% qlev || !q_f %in% qlev)
    stop("qname levels do not include ", q_ssb, " and ", q_f, ".", call. = FALSE)
  bad <- rbind(
    data.frame(qname = factor(q_ssb, levels = qlev),
               xmin = xmin, xmax = xmax, ymin = -Inf, ymax = bmsy),
    data.frame(qname = factor(q_f, levels = qlev),
               xmin = xmin, xmax = xmax, ymin = fmsy, ymax = Inf))
  below <- ggplot2::geom_rect(
    data = bad,
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    inherit.aes = FALSE, fill = fill, alpha = alpha, colour = NA)
  p$layers <- c(list(below), p$layers)
  p
}

scale_catch_advice_colour <- function() {
  ggplot2::scale_colour_manual(values = c(
    "ICES advice" = bm_col("advice"),
    "Reported catch" = bm_col("catch"),
    "Reported catch (SAG)" = bm_col("catch")))
}

scale_catch_advice_linetype <- function() {
  ggplot2::scale_linetype_manual(values = c(
    "ICES advice" = "dashed",
    "Reported catch" = "solid",
    "Reported catch (SAG)" = "solid"))
}

scale_source_compare <- function() {
  ggplot2::scale_colour_manual(
    values = c(
      SAG = bm_col("sag"),
      FLStock = bm_col("flstock"),
      actual = bm_col("actual"),
      geomean = bm_col("geomean"),
      devs = bm_col("devs")),
    labels = c(
      SAG = "SAG",
      FLStock = "FLStock",
      actual = "Actual",
      geomean = "Target F, mean recruitment",
      devs = "Target F, recruitment deviates"))
}

#' Line types for projection figures (\code{actual} solid; \code{geomean} dashed;
#' \code{devs} long-dash to distinguish from \code{actual})
scale_projection_linetype <- function() {
  ggplot2::scale_linetype_manual(
    values = c(actual = "solid", geomean = "dashed", devs = "longdash"),
    labels = c(
      actual = "Actual (assessment)",
      geomean = "Target F, mean recruitment",
      devs = "Target F, recruitment deviates"))
}

scale_backtest_source <- function() {
  ggplot2::scale_colour_manual(values = c(
    realised = bm_col("catch"),
    "HCR counterfactual" = bm_col("advice")),
    labels = c(
      realised = "Realised",
      "HCR counterfactual" = "HCR counterfactual"))
}

scale_assessment_year <- function(name = "Assessment") {
  if (requireNamespace("viridisLite", quietly = TRUE)) {
    ggplot2::scale_colour_viridis_d(
      option = "D", end = 0.92, name = name)
  } else {
    ggplot2::scale_colour_brewer(palette = "Blues", name = name)
  }
}

refpt_labels <- function(vars = c("fpa", "bpa", "blim", "fmsy", "msybtrigger")) {
  lbl <- c(
    flim = "F[lim]", fpa = "F[pa]", bpa = "B[pa]",
    blim = "B[lim]", fmsy = "F[MSY]",
    msybtrigger = "MSY*B[trigger]")
  lbl[vars]
}

facets_stock_row <- function(scales = "free_y") {
  ggplot2::facet_grid(name ~ ., scales = scales)
}

facets_stock_wrap <- function(ncol = 2, scales = "free_y") {
  ggplot2::facet_wrap(~ name, scales = scales, ncol = ncol)
}

facets_stock_wrap_stock <- function(ncol = 2, scales = "free_y") {
  ggplot2::facet_wrap(~ name, scales = scales, ncol = ncol)
}

#' Multi-stock time series (one panel per \code{sid})
#'
#' Uses facet strip labels (not in-panel text), shows \eqn{y}-axis values,
#' and applies \code{\link{theme_bluemarine_html}}.
#'
#' @param data Data frame with \code{year}, \code{sid}, and the \code{y} column
#' @param y Character name of the series column
#' @param title,ylab Plot labels
#' @param ncol Facet columns
#' @param colour Line colour (default project advice blue)
#' @param linewidth Line width
#' @param hline Optional horizontal reference (e.g. 0 or 1)
#' @return A ggplot
#' @export
ggplot_stock_ts <- function(data, y = "data", title = NULL, ylab = NULL,
                            ncol = 2, colour = bm_col("advice"),
                            linewidth = 0.7, hline = NULL) {
  if (!all(c("year", "sid", y) %in% names(data)))
    stop("data must contain year, sid, and '", y, "'.", call. = FALSE)
  data = as.data.frame(data)
  data$sid = factor(as.character(data$sid),
                    levels = unique(as.character(data$sid)))

  p = ggplot2::ggplot(data, ggplot2::aes(x = .data$year, y = .data[[y]])) +
    ggplot2::geom_line(colour = colour, linewidth = linewidth, na.rm = TRUE) +
    ggplot2::facet_wrap(~sid, scales = "free_y", ncol = ncol) +
    ggplot2::labs(title = title, x = "Year", y = ylab) +
    theme_bluemarine_html() +
    ggplot2::theme(legend.position = "none")

  if (!is.null(hline))
    p = p + ggplot2::geom_hline(
      yintercept = hline, colour = bm_col("ref_strong"),
      linewidth = 0.35, linetype = "dashed")
  p
}

#' Multi-stock time series with colour / linetype grouping
#'
#' @inheritParams ggplot_stock_ts
#' @param colour,linetype Aesthetic column names (or \code{NULL})
#' @param colour_values Optional named colour vector
#' @return A ggplot
#' @export
ggplot_stock_ts_cmp <- function(data, y, colour = NULL, linetype = NULL,
                                title = NULL, ylab = NULL, ncol = 2,
                                linewidth = 0.7, colour_values = NULL,
                                hline = NULL) {
  if (!all(c("year", "sid", y) %in% names(data)))
    stop("data must contain year, sid, and '", y, "'.", call. = FALSE)
  data = as.data.frame(data)
  data$sid = factor(as.character(data$sid),
                    levels = unique(as.character(data$sid)))
  data$.y = data[[y]]

  mapping = ggplot2::aes(x = .data$year, y = .data$.y)
  if (!is.null(colour))
    mapping = utils::modifyList(mapping, ggplot2::aes(colour = .data[[colour]]))
  if (!is.null(linetype))
    mapping = utils::modifyList(mapping, ggplot2::aes(linetype = .data[[linetype]]))

  p = ggplot2::ggplot(data, mapping) +
    ggplot2::geom_line(linewidth = linewidth, na.rm = TRUE) +
    ggplot2::facet_wrap(~sid, scales = "free_y", ncol = ncol) +
    ggplot2::labs(title = title, x = "Year", y = ylab) +
    theme_bluemarine_html()

  if (!is.null(colour_values))
    p = p + ggplot2::scale_colour_manual(values = colour_values)
  if (!is.null(hline))
    p = p + ggplot2::geom_hline(
      yintercept = hline, colour = bm_col("ref_strong"),
      linewidth = 0.35, linetype = "dashed")
  p
}

facets_compare_grid <- function(scales = "free_y") {
  ggplot2::facet_grid(
    qname ~ name, scales = scales, switch = "y",
    labeller = ggplot2::labeller(
      qname = function(x) x,
      name = function(x) x))
}

#' Default \eqn{y}-axis limits per projection row (ratio-scaled panels)
projection_ylim <- function() {
  c(
    "F/FMSY"           = 6,
    "SSB/MSYBtrigger"  = 6,
    "R/mean"           = 3,
    "C/MSY"            = 10
  )
}

#' Row-specific \eqn{y} scales for projection facets (\pkg{ggh4x})
projection_facetted_y_scales <- function(limits = projection_ylim()) {
  if (!requireNamespace("ggh4x", quietly = TRUE))
    stop("Package 'ggh4x' is required for row-wise projection y scales.",
         call. = FALSE)
  yscale <- function(ymax) {
    ggplot2::scale_y_continuous(
      limits = c(0, ymax),
      expand = ggplot2::expansion(mult = c(0, 0.02)),
      oob = scales::squish)
  }
  lv <- qname_levels_grid()
  ggh4x::facetted_pos_scales(
    y = lapply(lv, function(q) yscale(limits[[q]])))
}

#' Invisible points to fix row-wise \eqn{y} limits (fallback without \pkg{ggh4x})
projection_limit_blanks <- function(stocks, limits = projection_ylim(),
                                  x = 2010) {
  lv <- qname_levels_grid()
  nm <- stock_name_levels(stocks)
  pieces <- lapply(names(limits), function(q) {
    ylim <- limits[[q]]
    expand.grid(
      name = nm, qname = q, year = x, y = c(0, ylim),
      stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, pieces)
  out$name <- factor(out$name, levels = nm)
  out$qname <- factor(out$qname, levels = lv)
  out
}

#' Historical target-\eqn{F} projection figure (shared row scales, varying by metric)
ggplot_projections <- function(proj_cmp, stocks, xlim = c(2010, 2026),
                               linewidth = 0.8, limits = projection_ylim(),
                               base_size = 13, rotate_row_labels = TRUE,
                               extra_theme = NULL) {
  if (!("name" %in% names(proj_cmp)) && ("stock" %in% names(proj_cmp)))
    proj_cmp$name <- proj_cmp$stock
  proj_cmp <- order_stock_names(proj_cmp, stocks)
  proj_cmp$qname <- factor(proj_cmp$qname, levels = qname_levels_grid())

  p <- ggplot2::ggplot(
      proj_cmp,
      ggplot2::aes(.data$year, .data$data,
                   colour = .data$source, linetype = .data$source)) +
    ggplot2::geom_line(linewidth = linewidth) +
    scale_source_compare() +
    scale_projection_linetype() +
    facets_projection_grid() +
    ggplot2::labs(x = NULL, y = NULL)
  if (!is.null(xlim))
    p <- p + ggplot2::coord_cartesian(xlim = xlim)
  if (requireNamespace("ggh4x", quietly = TRUE)) {
    p <- p + projection_facetted_y_scales(limits)
  } else {
    blanks <- projection_limit_blanks(stocks, limits = limits, x = xlim[1])
    p <- p + ggplot2::geom_blank(
      data = blanks,
      ggplot2::aes(x = .data$year, y = .data$y),
      inherit.aes = FALSE)
  }
  if (!is.null(extra_theme))
    p <- p + extra_theme
  else
    p <- p + theme_projections(base_size = base_size)
  if (isTRUE(rotate_row_labels))
    p <- p + theme_facet_rows_rotated(size = ggplot2::rel(1))
  add_projection_reflines(p, proj_cmp)
}

#' Projection panels: shared \eqn{y} within each metric row across stocks
#'
#' With \code{qname ~ name}, \code{scales = "free_y"} shares \eqn{y} within each
#' metric row across stocks; use \code{\link{projection_facetted_y_scales}} for
#' row-specific limits.
facets_projection_grid <- function(scales = "free_y") {
  ggplot2::facet_grid(
    qname ~ name, scales = scales, switch = "y",
    labeller = ggplot2::labeller(
      qname = function(x) x,
      name = function(x) x))
}
