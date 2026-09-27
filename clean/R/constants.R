# Constants only. Plotting is ggplot2::theme_bw + geom_line.

case_sids=c(
  "cod.27.7e-k",
  "whg.27.7a",
  "cod.27.7a",
  "whg.27.7b-ce-k")

case_labs=c(
  "cod.27.7e-k"    = "Celtic Sea cod",
  "whg.27.7a"      = "Irish Sea whiting",
  "cod.27.7a"      = "Irish Sea cod",
  "whg.27.7b-ce-k" = "Celtic Sea whiting")

srr_om    ="bhw"
startYr_ar=2015L

# ICES TAC stability clause (hcrICES bndTac / bndWhen).
hcr_tac_bounds=function() c(0.8, 1.2)
hcr_tac_bnd_when=function() "btrig"

# Named colours for paper figures (Okabe–Ito-ish). Not a ggplot wrapper.
paper_cols=c(
  Historical     = "#000000",
  "Advice rule"  = "#D55E00",
  "ICES Ftar"    = "#0072B2",
  "OM FMSY"      = "#009E73",
  advice         = "#0072B2",
  catch          = "#D55E00",
  muted          = "grey50",
  ink            = "#222222",
  trigger        = "#E69F00",
  f_target       = "#009E73",
  ref_strong     = "grey40",
  strip_fill     = "#ecf0f1")

paper_col=function(...) {
  x=c(...)
  miss=setdiff(x, names(paper_cols))
  if (length(miss))
    stop("Unknown paper_cols name: ", paste(miss, collapse = ", "), call. = FALSE)
  unname(paper_cols[x])}

# Compatibility for copied notebooks that still call bm_col().
bm_col=paper_col

theme_paper=function(base_size = 11) {
  ggplot2::theme_bw(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom")}
