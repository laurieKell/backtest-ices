## Application I/O for data/reference/stocks.csv.
## Missing-slot fill for FLasher is FLBacktest::cleanStock.

loadFLStock <- function(rdata, path) {
  yr_end <- NA_integer_
  if (is.data.frame(rdata)) {
    if ("end" %in% names(rdata))
      yr_end <- as.integer(rdata$end[1])
    object <- rdata$object[1]
    rdata <- rdata$rdata[1]
  }
  rdata <- as.character(rdata)[1]
  object <- as.character(object)[1]
  fl <- file.path(path, rdata)
  if (!isTRUE(file.exists(fl)))
    stop("Missing ", fl, call. = FALSE)
  e <- new.env()
  load(fl, envir = e)
  if (!exists(object, envir = e, inherits = FALSE))
    stop("Object '", object, "' not in ", basename(fl),
         "; found: ", paste(ls(e), collapse = ", "), call. = FALSE)
  stk <- get(object, envir = e, inherits = FALSE)
  if (is.finite(yr_end))
    stk <- FLCore::window(stk, end = yr_end)
  stk}

stock_name <- function(sid, stocks) {
  as.character(stocks$name[match(as.character(sid), as.character(stocks$sid))])}

stock_name_levels <- function(stocks) as.character(stocks$name)

stockInventory <- function(inv, oms) {
  inv$minyear <- NA_integer_
  inv$maxyear <- NA_integer_
  inv$minage <- NA_integer_
  inv$maxage <- NA_integer_
  nms <- names(oms)
  for (i in seq_len(nrow(inv))) {
    key <- as.character(inv$sid[i])
    if (!key %in% nms)
      key <- as.character(inv$object[i])
    if (!key %in% nms)
      stop("stockInventory: no FLStock for sid/object ",
           inv$sid[i], " / ", inv$object[i], call. = FALSE)
    d <- dims(oms[[key]])
    inv$minyear[i] <- as.integer(d$minyear)
    inv$maxyear[i] <- as.integer(d$maxyear)
    inv$minage[i] <- as.integer(d$min)
    inv$maxage[i] <- as.integer(d$max)
  }
  inv}
