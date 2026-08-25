# Outline — peer-review manuscript

Working title: **A historical backtest of ICES advice: separating harvest
policy from observed productivity**

Target: *ICES Journal of Marine Science* (original article or Food for
Thought). Companion software: **FLBacktest**
([laurieKell/FLBacktest](https://github.com/laurieKell/FLBacktest)).

## Abstract (draft skeleton)

Realised Category 1 trajectories mix the properties of ICES advice with
the degree to which that advice was followed. We condition age-structured
Operating Models on WGCSE assessments for six Northeast Atlantic stocks
and hold biology and recruitment residuals fixed while changing only
harvest policy. Open-loop fishing at published \(F_{\mathrm{target}}\) is
contrasted with the closed-loop ICES hockey-stick HCR (`hcrICES`). ICES
\(B_{\lim}\), \(MSYB_{\mathrm{trigger}}\) and \(F_{\mathrm{target}}\) are
treated as HCR **inputs**; Operating Model \(B_{\mathrm{MSY}}\) is the
performance metric. Results show that implementing the rule is not the
historical fishery, that open-loop \(F_{\mathrm{target}}\) and the HCR
answer different questions, and that scoring against the trigger can
disagree with scoring against \(B_{\mathrm{MSY}}\) in either direction.

## Research question

Had Category 1 ICES advice been implemented, what would SSB, \(F\) and
catch have been, given the **productivity that actually occurred** (time-
varying life history plus recruitment residuals)? This is not a
climate-forced MSE.

## Design

1. Condition an age-structured OM (`FLStock` + `FLBRP`) on the WG assessment
   (`icesdata::eql`; six SRR hypotheses + scn0–scn2).
2. Gate: long-term `fwd` at \(F_{\mathrm{MSY}}\) must match `refpts`
   (`FLBacktest::ltermEq` / `ltermPass`).
3. Two policies, same OM: open-loop \(F_{\mathrm{target}}\)
   (`openloop_start` + `FLasher::fwd`); closed-loop ICES HCR (`hcrICES`,
   `err = NULL`).
4. Historical window: replay residuals. Future window: mean recruitment
   (`project_hcr` / `years_to`) — a different experiment.
5. Report ICES control points as HCR inputs; OM \(B_{\mathrm{MSY}}\) as the
   performance metric (Winker et al. 2025, 2026).

## Case studies

Primary narrative: Irish Sea whiting (`whg.27.7a`, scn2) and Celtic Sea
cod (`cod.27.7e-k`, scn0). Supporting digest: remaining gated stocks on
scn2 (`06.2`). Mackerel flagged for benchmark discontinuity.

## Proposed structure

1. **Introduction** — implementation vs rule; EqSim open-loop vs closed-loop
   MSE; hockey-stick control points vs compensatory \(B_{\mathrm{MSY}}\)
   (Mesnil & Rochet 2010; Winker et al.).
2. **Methods**
   - FLR objects and conditioning (`cleanStock`, `eql`, benchmarks).
   - Empirical productivity OM (Punt et al. 2014; Trochta et al.; Lindmark
     et al. on \(B_{0,t}\)).
   - Gate (`ltermEq`); open vs closed loop; Future window.
   - Software: FLBacktest generics; `tryIt = FALSE`.
3. **Results**
   - Terminal status vs ICES points (all stocks).
   - \(MSYB_{\mathrm{trigger}}/B_{\mathrm{MSY}}\) on scn2.
   - Historical vs \(F_{\mathrm{target}}\) vs advice rule (two stocks + digest).
   - Future rebuild times: trigger ≠ \(B_{\mathrm{MSY}}\).
4. **Discussion** — advice not followed vs advice that would not have rebuilt
   to MSY; Irish Sea cod choke / \(F_{\mathrm{target}}\) mismatch; SAM OEM
   as robustness (`04.4`), not the base case.
5. **Conclusions** — keep HCR inputs and MSY metrics distinct; replay
   observed productivity when asking historical counterfactuals.

## What this paper is not

GCM-driven recruitment; full SAM peels for every advice year; mixed-fishery
technical interactions as a formal multi-stock OM (except as interpretation
for Irish Sea cod \(F\)).

## Figures / tables (target)

| Item | Content | Source notebook |
|------|---------|-----------------|
| Fig 1 | Two-stock SSB/\(F\)/catch trajectories | `06.1` |
| Fig 2 | Residuals + STARS; dynamic \(B_0\) | `06.1` |
| Fig 3 | SRR / production function vs hockey-stick points | `06.1`/`06.2` |
| Fig 4 | Future rebuild (trigger vs \(B_{\mathrm{MSY}}\)) | `06.0`/`04.3` |
| Tab 1 | Terminal Hist / \(F_{\mathrm{tar}}\) / AR ratios | `05.0` |
| Tab 2 | ICES points vs OM \(B_{\mathrm{MSY}}\) (scn2) | `06.2` |
| Tab 3 | Years-to-rebuild | `04.3` / `06.0` |

## Supplementary material

The `Rmd/` knit chain **is** the supplement (`00_supplement.Rmd` index).
Methods text shared with other papers: FLBacktest vignette
`vignettes/methods-backtest.Rmd`.

## Next before submission

1. Freeze scn2 (or agreed OM) in the main figures — align `06.0` with `06.1`/`06.2`.
2. Decide mackerel in or out.
3. Optional: short stochastic sensitivity for \(P(\mathrm{SSB}<B_{\lim})\).
4. Cite FLBacktest release; point Code availability at the GitHub repos.
