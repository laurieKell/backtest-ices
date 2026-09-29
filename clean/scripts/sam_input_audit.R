# SAM input audit. Re-runs the displayed SAM closed loop (02.4.2) and the
# OEM worms (sam_oem_worms.R) with stockassessment::sam.fit traced, and
# writes, for every refit, the exact data, configuration and starting
# parameters SAM received; fit diagnostics against the Operating Model; and
# a SAM retrospective (5 peels) on the final fit of each loop.
# Run from clean/ with RENV_CONFIG_AUTOLOADER_ENABLED=FALSE.
# Output: data/results/sam_audit/.

root_here <- if (file.exists("R/paths.R")) "." else "clean"
setwd(root_here)
source("R/paths.R")
source("R/constants.R")
source("R/om.R")
source("R/sam_oem.R")
source("R/sam_mc.R")
root <- data_root()
here <- clean_root()

suppressPackageStartupMessages({
  library(FLCore)
  library(parallel)
})

load_om(root)
sids_all <- sam_sids(oms, stocks)
out <- file.path(root, "data/results/sam_audit")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
worm_dir <- file.path(root, "data/interim/02.4.2_sam_worms/cv010", srr_om)
n_worms <- as.integer(Sys.getenv("BM_SAM_WORMS", unset = "8"))
only <- Sys.getenv("BM_AUDIT_ONLY", unset = "")
ncores <- as.integer(Sys.getenv("BM_AUDIT_CORES",
                                unset = max(1L, parallel::detectCores() - 2L)))

jobs <- rbind(
  data.frame(run = "display", id = case_sids, iter = 0L,
             stringsAsFactors = FALSE),
  expand.grid(run = "worm", id = case_sids, iter = seq_len(n_worms),
              stringsAsFactors = FALSE))
if (nzchar(only))
  jobs <- jobs[paste(jobs$run, jobs$id, jobs$iter, sep = "/") %in%
                 strsplit(only, ",")[[1]], ]

audit_long <- function(x, fit_n, assess_year, fleets) {
  obs <- as.data.frame(x$aux)
  obs$value <- exp(x$logobs)
  obs$quantity <- fleets[obs$fleet]
  obs <- obs[, c("quantity", "fleet", "year", "age", "value")]
  bio_nms <- intersect(c("natMor", "stockMeanWeight", "catchMeanWeight",
                         "landMeanWeight", "disMeanWeight", "propMat",
                         "landFrac", "propF", "propM"), names(x))
  bio <- do.call(rbind, lapply(bio_nms, function(nm) {
    a <- x[[nm]]
    if (is.null(dim(a))) return(NULL)
    d <- as.data.frame.table(a, stringsAsFactors = FALSE)
    names(d)[1:2] <- c("year", "age")
    fleet <- if (ncol(d) > 3) d[[3]] else NA
    data.frame(quantity = nm, fleet = fleet, year = d$year, age = d$age,
               value = d$Freq, stringsAsFactors = FALSE)
  }))
  res <- rbind(obs, bio)
  cbind(fit = fit_n, assess_year = assess_year, res)
}

audit_conf <- function(conf) {
  s <- function(v) paste(v, collapse = " ")
  m <- function(v) paste(apply(as.matrix(v), 1, s), collapse = " | ")
  data.frame(
    minAge = conf$minAge, maxAge = conf$maxAge,
    plusGroup = s(conf$maxAgePlusGroup),
    fbarRange = s(conf$fbarRange),
    keyLogFsta = m(conf$keyLogFsta), keyLogFpar = m(conf$keyLogFpar),
    keyVarF = m(conf$keyVarF), keyVarObs = m(conf$keyVarObs),
    corFlag = s(conf$corFlag), obsCorStruct = s(conf$obsCorStruct),
    stockRecruitmentModelCode = s(conf$stockRecruitmentModelCode),
    stringsAsFactors = FALSE)
}

audit_est <- function(fit, fit_n) {
  tab <- function(f, q) {
    t <- tryCatch(f(fit), error = function(e) NULL)
    if (is.null(t)) return(NULL)
    data.frame(fit = fit_n, quantity = q, year = as.integer(rownames(t)),
               estimate = t[, "Estimate"], low = t[, "Low"],
               high = t[, "High"], stringsAsFactors = FALSE)
  }
  rbind(tab(stockassessment::ssbtable, "SSB"),
        tab(stockassessment::fbartable, "Fbar"),
        tab(stockassessment::rectable, "Rec"))
}

audit_job <- function(k, jobs, out, worm_dir, sids_all) {
  g <- globalenv()
  run <- jobs$run[k]; id <- jobs$id[k]; it <- as.integer(jobs$iter[k])
  dir_k <- file.path(out, "fits", run, id, sprintf("%03d", it))
  dir.create(dir_k, recursive = TRUE, showWarnings = FALSE)
  log <- new.env()
  log$n <- 0L
  log$fits <- list()
  log$inputs <- list()
  suppressMessages(trace(
    "sam.fit", where = asNamespace("stockassessment"), print = FALSE,
    tracer = bquote({
      n <- get("n", envir = .(log)) + 1L
      assign("n", n, envir = .(log))
      inp <- list(data = data, conf = conf, parameters = parameters)
      saveRDS(inp, file.path(.(dir_k), sprintf("sam_input_%02d.rds", n)))
      l <- get("inputs", envir = .(log)); l[[n]] <- inp
      assign("inputs", l, envir = .(log))
    }),
    exit = bquote({
      n <- get("n", envir = .(log))
      l <- get("fits", envir = .(log)); l[n] <- list(returnValue(NULL))
      assign("fits", l, envir = .(log))
    })))

  stk <- g$oms[[id]]
  eql <- g$eqls[[srr_om]][[id]]
  seed <- NA_integer_
  ref <- NULL
  t0 <- Sys.time()
  err <- NA_character_
  res <- tryCatch({
    if (run == "display") {
      samEnv <- new.env()
      load(file.path(data_root(), "data/results/02.4.1_sam.RData"), envir = samEnv)
      seed <- 1000L + match(id, samEnv$sids)
      set.seed(seed)
      idx <- sam_prime(stk, samEnv$oem[[id]], start = startYr_ar, lag = 1L)
      f_ref <- file.path(data_root(), "data/interim/02.4.2_closedLoop_sam",
                         srr_om, id, "run.rds")
      if (file.exists(f_ref)) ref <- readRDS(f_ref)
      hcrICES(sam_catch_na(stk, end = startYr_ar), eql = eql,
              sr_deviances = srResiduals(eql),
              params = hcrParams(g$eqs[[id]]),
              start = startYr_ar, end = dims(stk)$maxyear,
              lag = 1, interval = 1, err = idx, implErr = 0,
              bndTac = hcr_tac_bounds(), bndWhen = hcr_tac_bnd_when())[[1]]
    } else {
      f_ref <- file.path(worm_dir, id, sprintf("%03d.rds", it))
      ref <- readRDS(f_ref)
      seed <- attr(ref, "seed")
      if (is.null(seed)) {
        a <- attr(ref, "seed_attempt"); if (is.null(a)) a <- 1L
        seed <- sam_worm_seed(id, it, sids_all, a)
      }
      set.seed(seed)
      idx <- sam_oem(stk, indexCv = 0.1, nits = 1L)
      idx <- sam_prime(stk, idx, start = startYr_ar, lag = 1L)
      hcrICES(sam_catch_na(stk, end = startYr_ar), eql = eql,
              sr_deviances = srResiduals(eql),
              params = hcrParams(g$eqs[[id]]),
              start = startYr_ar, end = dims(stk)$maxyear,
              lag = 1, interval = 1, err = idx, implErr = 0,
              bndTac = hcr_tac_bounds(), bndWhen = hcr_tac_bnd_when(),
              maxF = hcr_maxF())[[1]]
    }
  }, error = function(e) { err <<- conditionMessage(e); NULL },
  finally = suppressMessages(untrace("sam.fit",
                                     where = asNamespace("stockassessment"))))
  minutes <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  if (!is.null(res)) saveRDS(res, file.path(dir_k, "run.rds"))

  truth <- if (!is.null(res)) res else ref
  fits <- log$fits
  inputs <- log$inputs
  n_fit <- length(inputs)
  fleets_of <- function(d) {
    f <- attr(d, "fleetNames")
    if (is.null(f)) paste0("fleet", seq_len(d$noFleets)) else f
  }

  long <- list(); est <- list(); rows <- list(); confs <- list()
  for (n in seq_len(n_fit)) {
    d <- inputs[[n]]$data
    cf <- inputs[[n]]$conf
    ay <- max(d$years)
    long[[n]] <- audit_long(d, n, ay, fleets_of(d))
    confs[[n]] <- cbind(fit = n, assess_year = ay, audit_conf(cf))
    writeLines(deparse(cf), file.path(dir_k, sprintf("sam_conf_%02d.txt", n)))
    fit <- if (n <= length(fits)) fits[[n]] else NULL
    ok <- is.list(fit) && !is.null(fit$opt)
    e <- if (ok) audit_est(fit, n) else NULL
    est[[n]] <- e
    ssb_hat <- fb_hat <- ssb_cv <- NA_real_
    if (!is.null(e)) {
      s <- e[e$quantity == "SSB" & e$year == ay, ]
      f <- e[e$quantity == "Fbar" & e$year == ay, ]
      if (nrow(s)) { ssb_hat <- s$estimate
        ssb_cv <- (log(s$high) - log(s$estimate)) / 1.96 }
      if (nrow(f)) fb_hat <- f$estimate
    }
    ssb_om <- fb_om <- NA_real_
    if (!is.null(truth) && ac(ay) %in% dimnames(ssb(truth))$year) {
      ssb_om <- c(ssb(truth)[, ac(ay)])
      fr <- cf$fbarRange
      fb_om <- mean(c(harvest(truth)[ac(fr[1]:fr[2]), ac(ay)]))
    }
    grad <- if (ok) tryCatch(max(abs(fit$sdrep$gradient.fixed)),
                             error = function(e) NA_real_) else NA_real_
    rows[[n]] <- data.frame(
      run = run, sid = id, iter = it, fit = n, assess_year = ay,
      n_years = d$noYears, n_obs = length(d$logobs),
      n_survey_obs = sum(d$aux[, "fleet"] != 1),
      convergence = if (ok) fit$opt$convergence else NA_integer_,
      message = if (ok) fit$opt$message else "no fit returned",
      objective = if (ok) fit$opt$objective else NA_real_,
      npar = if (ok) length(fit$opt$par) else NA_integer_,
      max_grad = grad,
      pdHess = if (ok) isTRUE(fit$sdrep$pdHess) else NA,
      ssb_sam = ssb_hat, ssb_om = ssb_om, ssb_rel = ssb_hat / ssb_om - 1,
      ssb_cv = ssb_cv,
      fbar_sam = fb_hat, fbar_om = fb_om, fbar_rel = fb_hat / fb_om - 1,
      stringsAsFactors = FALSE)
  }
  long <- do.call(rbind, long)
  est <- do.call(rbind, est)
  rows <- do.call(rbind, rows)
  confs <- do.call(rbind, confs)
  if (!is.null(long)) write.csv(long, file.path(dir_k, "sam_inputs_long.csv"), row.names = FALSE)
  if (!is.null(est)) write.csv(est, file.path(dir_k, "sam_estimates.csv"), row.names = FALSE)
  if (!is.null(confs)) write.csv(confs, file.path(dir_k, "sam_conf.csv"), row.names = FALSE)

  retro <- data.frame(run = run, sid = id, iter = it,
                      rho_ssb = NA_real_, rho_fbar = NA_real_, rho_rec = NA_real_,
                      peels = NA_integer_, peels_not_converged = NA_integer_,
                      error = NA_character_, stringsAsFactors = FALSE)
  last <- if (length(fits)) fits[[length(fits)]] else NULL
  if (is.list(last) && !is.null(last$opt)) {
    r <- tryCatch(stockassessment::retro(last, year = 5, ncores = 1),
                  error = function(e) e)
    if (inherits(r, "error")) {
      retro$error <- conditionMessage(r)
    } else {
      m <- tryCatch(stockassessment::mohn(r), error = function(e) NULL)
      if (!is.null(m)) {
        retro$rho_ssb <- unname(m["SSB"]); retro$rho_fbar <- unname(m[grep("Fbar", names(m))[1]])
        retro$rho_rec <- unname(m[1])
      }
      pc <- vapply(r, function(x) if (is.list(x) && !is.null(x$opt))
        as.integer(x$opt$convergence) else NA_integer_, integer(1))
      retro$peels <- length(r)
      retro$peels_not_converged <- sum(is.na(pc) | pc != 0L)
      saveRDS(lapply(r, function(x) list(
        conv = x$opt$convergence,
        ssb = tryCatch(stockassessment::ssbtable(x), error = function(e) NULL),
        fbar = tryCatch(stockassessment::fbartable(x), error = function(e) NULL))),
        file.path(dir_k, "retro_peels.rds"))
    }
  }

  repro <- NA_real_
  if (!is.null(res) && !is.null(ref)) {
    yrs <- intersect(dimnames(ssb(res))$year, dimnames(ssb(ref))$year)
    repro <- max(abs(c(ssb(res)[, yrs]) / c(ssb(ref)[, yrs]) - 1), na.rm = TRUE)
  }
  job <- data.frame(run = run, sid = id, iter = it, seed = seed,
                    refits = n_fit, minutes = round(minutes, 2),
                    loop_error = err, max_rel_diff_vs_cached = repro,
                    stringsAsFactors = FALSE)
  list(job = job, fits = rows, retro = retro)
}
environment(audit_job) <- globalenv()
environment(audit_long) <- globalenv()
environment(audit_conf) <- globalenv()
environment(audit_est) <- globalenv()

message(nrow(jobs), " loops to audit on ", max(1L, min(ncores, nrow(jobs))), " cores")
t0 <- Sys.time()
if (ncores < 1L) {
  sam_mc_init(here, root, .libPaths())
  res <- lapply(seq_len(nrow(jobs)), audit_job, jobs = jobs, out = out,
                worm_dir = worm_dir, sids_all = sids_all)
} else {
cl <- makeCluster(min(ncores, nrow(jobs)))
res <- tryCatch({
  clusterCall(cl, sam_mc_init, here = here, root = root, libs = .libPaths())
  clusterExport(cl, c("audit_long", "audit_conf", "audit_est", "audit_job"))
  parLapplyLB(cl, seq_len(nrow(jobs)), function(k, jobs, out, worm_dir, sids_all)
    tryCatch(audit_job(k, jobs, out, worm_dir, sids_all), error = function(e)
      list(job = data.frame(run = jobs$run[k], sid = jobs$id[k],
                            iter = jobs$iter[k], seed = NA, refits = NA,
                            minutes = NA, loop_error = conditionMessage(e),
                            max_rel_diff_vs_cached = NA))),
    jobs = jobs, out = out, worm_dir = worm_dir, sids_all = sids_all)
}, finally = stopCluster(cl))
}
message("audit ", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min")

bind <- function(nm) do.call(rbind, lapply(res, `[[`, nm))
sfx <- if (nzchar(only)) "_subset" else ""
write.csv(bind("job"), file.path(out, paste0("audit_jobs", sfx, ".csv")), row.names = FALSE)
write.csv(bind("fits"), file.path(out, paste0("audit_fits", sfx, ".csv")), row.names = FALSE)
write.csv(bind("retro"), file.path(out, paste0("audit_retro", sfx, ".csv")), row.names = FALSE)
print(bind("job"))
