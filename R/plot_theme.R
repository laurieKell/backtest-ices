# Shared ggplot theme and scales for backtest-ices figures (pipeline-used only).
# Extra / unused helpers live in R/_local/plot_theme_extra.R (gitignored).

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

#' Rotate \code{facet_grid} row strip labels sideways (left strip)
theme_facet_rows_rotated <- function(angle = 90, size = ggplot2::rel(1)) {
  ggplot2::theme(
    strip.placement = "outside",
    strip.text.y = ggplot2::element_text(
      angle = angle, hjust = 0.5, vjust = 0.5, size = size),
    strip.text.y.left = ggplot2::element_text(
      angle = angle, hjust = 0.5, vjust = 0.5, size = size))
}

#' Shade SSB below \eqn{B_{\mathrm{MSY}}} and \eqn{F} above \eqn{F_{\mathrm{MSY}}}
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

facets_stock_row <- function(scales = "free_y") {
  ggplot2::facet_grid(name ~ ., scales = scales)
}

facets_stock_wrap <- function(ncol = 2, scales = "free_y") {
  ggplot2::facet_wrap(~ name, scales = scales, ncol = ncol)
}

#' Multi-stock time series (one panel per \code{sid})
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
