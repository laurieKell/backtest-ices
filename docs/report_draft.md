# Backtest of ICES advice for selected Northeast Atlantic stocks

Draft report for Laurence Kell / blueMarine. Lift into `Rmd/06.0_report.Rmd`.
**Freeze:** 25 August 2026. Repositories:
[backtest-ices](https://github.com/laurieKell/backtest-ices) (application) and
[FLBacktest](https://github.com/laurieKell/FLBacktest) (engine).
Bibliography: `tex/refs.bib` (Pandoc keys `winker2026rebuilding`,
`winker2025precautionary`, `Lindmark2026productivity`, `mesnil2010hockeystick`
/ `mesnil2010continuous`, `Winker2022InsideOut`, `punt2016msebestpractice`).

This document absorbs the earlier scn2-only note. Notebooks in `Rmd/` are
**supplementary material**, not the report body.

This is a historical backtest, not a forecast. Observed productivity is
time-varying \(M\), mass and maturity plus stock–recruitment residuals — not
climate.

---

## i) What was done and why

The practical problem is the gap between ICES Category 1 advice and what the
fishery implemented. A second, related problem is how that advice is scored.
ICES does not report \(B_{\mathrm{MSY}}\). EqSim, as used at benchmarks, is an
open-loop equilibrium simulation: it scans constant \(F\) on a stock–recruitment
relationship (SRR) fitted to assessment SSB–recruit pairs, typically a
hockey-stick [@mesnil2010hockeystick; @punt2016msebestpractice]. It is not a
closed-loop management strategy evaluation (MSE). It does not simulate the
management feedback loop — data, advice lag, the harvest control rule (HCR), or
catch implementation — so EqSim \(F_{\mathrm{MSY}}\) is not a property of a
closed management procedure [@winker2025precautionary].

What ICES reports are **operational control points**: \(B_{\lim}\),
\(MSYB_{\mathrm{trigger}}\) and \(F_{\mathrm{target}}\). \(B_{\lim}\) is
typically the hockey-stick breakpoint (recruitment impairment).
\(MSYB_{\mathrm{trigger}}\) is then usually \(B_{\mathrm{pa}} \approx 1.4
B_{\lim}\), not a percentile of \(B_{\mathrm{MSY}}\) [@winker2026rebuilding;
@winker2025precautionary]. After the breakpoint, expected recruitment is
constant, so the production function is truncated. For many stocks the
breakpoint sits at or near what would be \(B_{\mathrm{MSY}}\) on a compensatory
curve — a limit that looks like a target. The SSB–recruit pairs themselves are
model outputs, not independent observations [@Winker2022InsideOut]. Steepness,
and therefore \(B_{\mathrm{MSY}}\), is poorly identified from them. That is why
ICES does not currently report \(B_{\mathrm{MSY}}\).

@winker2026rebuilding make the operational distinction this report uses:
\(MSYB_{\mathrm{trigger}}\) is an HCR threshold that reduces \(F\) when SSB is
low, not a biomass target; \(B_{\mathrm{MSY}}\) is the policy objective.
Treating the trigger as the target is why a stock can sit above
\(MSYB_{\mathrm{trigger}}\) and still be well short of \(B_{\mathrm{MSY}}\).
@winker2025precautionary showed that EqSim \(F_{\mathrm{MSY}}\) is not
precautionary relative to a shortcut MSE that retains assessment structure and
advice lags. The implication is simple: ICES control points stay as HCR
**inputs**; whether a harvest policy meets MSY is scored on Operating Model
\(B_{\mathrm{MSY}}\) and \(F_{\mathrm{MSY}}\).

The response was to condition WGCSE Category 1 assessments as age-structured
`FLStock` Operating Models, with time-varying weights, \(M\), maturity and
selectivity, then to impose a hard gate: a long-term projection at
\(F_{\mathrm{MSY}}\) must match the `FLBRP` reference points before any backtest
is run. The historical experiment holds that Operating Model fixed and changes
only harvest policy. Two policies are compared. Open loop is a simple `fwd`
projection at the published ICES \(F_{\mathrm{target}}\) from 1990, or two years
after the first assessment year if later. Closed loop is the ICES hockey-stick
(`hcrICES`) from 2015: \(F\) is revised from SSB each year and a short-term
projection sets the TAC. The advice rule does not start from the open-loop
\(F_{\mathrm{target}}\) trajectory. The open-loop run is a no-feedback
benchmark that separates fishing at \(F_{\mathrm{target}}\) from following the
HCR.

In the Historical window, expected recruitment follows the Operating Model SRR
at that year's SSB, and the fitted residuals are then replayed, so the
productivity that actually occurred is common across policies
[@Lindmark2026productivity]. The Future window uses the same SRR **without**
those residuals: biology and selectivity are recent means, and recruitment is
mean recruitment. That switches the observed productivity history off. It is
longer than the ICES 1–2 year advice forecast and is not a stochastic forecast;
the aim is expected rebuilding time under the ICES advice rule.

Structural uncertainty in the SRR was represented by six hypotheses on the same
biology — **bh1** unconstrained Beverton–Holt, **bh2** FishLife steepness prior,
**bh3** \(R_0\) prior from the ICES hockey-stick ratio, and **rk1–rk3** the
Ricker analogues — plus three further Beverton–Holt variants **scn0–scn2**. ICES
HCR inputs (\(F_{\mathrm{target}}\), \(B_{\lim}\), \(MSYB_{\mathrm{trigger}}\))
are always the published SAG values attached to **bh1**, held fixed across
Operating Model SRRs. Operating Model \(B_{\mathrm{MSY}}\) and \(F_{\mathrm{MSY}}\)
used as performance metrics come from the SRR that actually projects the stock.

**scn2** is the readable single hypothesis presented here. It is Beverton–Holt
in steepness–\(R_0\) form: a weakly informative steepness prior of 0.7 (CV 0.3)
and \(R_0\) equal to median recruitment above the ICES \(MSYB_{\mathrm{trigger}}\)
cutoff. It is not unconstrained \(h\) (bh1 / scn1), where \(B_{\mathrm{MSY}}\)
can run off with an unidentified steepness; not a hockey-stick Operating Model,
which would treat the truncated ICES production function as truth; and not scn0
(\(h = 0.999\)), which is nearly linear. Funder case studies used scn2 for Irish
Sea whiting (`whg.27.7a`) and scn0 for Celtic Sea cod (`cod.27.7e-k`). The
all-stock note standardises on scn2. Other branches remain in `eqls` and in the
open- and closed-loop outputs.

---

## ii) Frame of this study

This document is the report. The `Rmd/` chain **is** the supplementary methods.
[`00_supplement.Rmd`](../Rmd/00_supplement.Rmd) is the index. Knit order is
inventory (`01_screening.Rmd`), Operating Model conditioning
(`02.0_condition_om.Rmd`), the hard gate (`02.1_lterm_eq.Rmd`,
`02.2_dynamics.Rmd`), the generic backtest (`04.1_openLoop.Rmd`,
`04.2_closedLoop.Rmd`), the Future window (`04.3_rebuild.Rmd`), the all-stock
digest (`05.0_digest.Rmd`), the two funder case studies
(`06.1_TwoStocks.Rmd`), and the generic OM note (`06.2_generic.Rmd`).
[`06.0_report.Rmd`](../Rmd/06.0_report.Rmd) loads results and holds the contract
figures; it does not re-run the simulations. Optional off-path notebooks are the
SAM observation-error closed loop (`04.4_closedLoop_sam.Rmd`) and an internal
SRR note (`07_srr_internal_external.Rmd`).

Figures and tables that carry the scn2 argument come from `06.1` (Irish Sea
whiting on scn2, Celtic Sea cod on scn0) and `06.2` (generic scn2 OM; Celtic Sea
cod and Irish Sea whiting are in `06.1`).
The paired Historical | Future figures still knitted in `06.0` are the **bh3**
reference case already produced there (Beverton–Holt with an \(R_0\) prior from
\(MSYB_{\mathrm{trigger}}/B_{\lim}\)). bh3 is a related compensatory hypothesis,
not scn2. Captions in `06.0` say bh3; `06.2` says scn2. Rebuild times quoted from
those `06.0` panels are therefore bh3, not scn2. Aligning `06.0` figures with
scn2 remains a next step.

For the Irish and Celtic Sea gadoids, \(MSYB_{\mathrm{trigger}}\) is the ICES
SAG value used as an HCR input. For Northeast Atlantic mackerel the 2025
advice sheet sets \(MSYB_{\mathrm{trigger}}=B_{\mathrm{pa}}\) (4,119,337 t),
which matches the SAG row used at conditioning. Recent mackerel benchmarks
also changed the assessment substantially, so the backtest conflates following
advice with robustness of that advice. The stock is retained for completeness.

One Operating Model is shown for readability. Showing every SRR in the report
body would bury the distinction the study is built on: ICES control points as
HCR inputs versus Operating Model MSY as performance metrics. Structural
uncertainty remains in `eqls`.

---

## iii) Results

Numbers below are taken from knitted HTML, not invented. Terminal assessment
status versus ICES points is from `05.0_digest.html` Table 1 (the Historical
column is the assessment and does not depend on the Operating Model SRR; the
open- and closed-loop columns there are the **bh1** digest). ICES control points
versus scn2 \(B_{\mathrm{MSY}}\) are from the ICES vs scn2 table in
`06.2_generic.html`. Case-study take-home text, including the advice-sheet
status tables, is from `06.1_TwoStocks.html`. Future rebuild years are from
`06.0_report.html` and are **bh3**. Excel files `data/results/06.1.xlsx` and
`06.2.xlsx` were not on disk at the time of this draft; they are written when
those notebooks are knitted.

### Historical status versus ICES control points

All six stocks sit below \(B_{\lim}\) on the current advice sheets in
`docs/advice` (MSY and precautionary-approach status). Realised \(\bar F\)
exceeds ICES \(F_{\mathrm{target}}\) except in Irish Sea cod (below
\(F_{\mathrm{MSY}}\)); Celtic Sea haddock is above \(F_{\mathrm{MSY}}\) but
below \(F_{\mathrm{pa}}\).

| Stock | SID | Year | Hist SSB / \(B_{\mathrm{trig}}\) | Hist \(\bar F / F_{\mathrm{target}}\) |
|---|---|---:|---:|---:|
| Irish Sea cod | `cod.27.7a` | 2023 | 0.54 | 0.07 |
| Irish Sea whiting | `whg.27.7a` | 2023 | 0.68 | 4.75 |
| Celtic Sea cod | `cod.27.7e-k` | 2025 | 0.02 | 4.44 |
| Celtic Sea whiting | `whg.27.7b-ce-k` | 2024 | 0.22 | 1.42 |
| Celtic Sea haddock | `had.27.7b-k` | 2025 | 0.63 | 1.78 |
| NE Atlantic mackerel | `mac.27.nea` | 2024 | 0.77 | 1.39 |

Source: `05.0_digest.html` Table 1 for the OM-year ratios; ICES qualitative
status from the advice sheets (2025–2026). Celtic Sea cod is far below
\(B_{\lim}\) with \(F\) above \(F_{\mathrm{MSY}}\) and \(F_{\mathrm{pa}}\)
(2026 sheet). Irish Sea whiting is below \(B_{\lim}\) with \(F\) above
\(F_{\mathrm{MSY}}\) and \(F_{\mathrm{pa}}\) (2025 sheet). Irish Sea cod is
the exception on \(F\): historical \(\bar F\) is about
\(0.07\times F_{\mathrm{target}}\), and the 2026 sheet has \(F\) below
\(F_{\mathrm{MSY}}\).

### ICES SRR assumptions versus Operating Model \(B_{\mathrm{MSY}}\) (scn2)

`06.2` records how ICES derived the control points on the advice sheets in
`docs/advice` (not the Operating Model). Irish Sea cod \(B_{\lim}\) is the
lowest SSB with above-average recruitment (9,364 t; 2026 sheet). Irish Sea
whiting \(B_{\lim}\) is \(0.15 B_0\) (1,670 t) on the 2025 sheet (WKBNSCS),
with \(MSYB_{\mathrm{trigger}}=B_{\mathrm{pa}}=2\,322\,\mathrm{t}\). The 2015
WKNSEA Type 2 breakpoint (26,300 t) is not the current-sheet value; SAG and
the HCR inputs match the 2025 sheet. Celtic Sea cod is \(B_{\lim}=B_{\mathrm{loss}}\)
(SSB in 2005; 4,200 t). Celtic Sea whiting is \(B_{\lim}=B_{\mathrm{loss}}\)
(SSB in 2008; 36,571 t); EqSim used segmented regression with the breakpoint
fixed at that \(B_{\lim}\), \(F_{\mathrm{MSY}}\) capped at \(F_{\mathrm{p}0.05}\).
Celtic Sea haddock \(B_{\lim}\) is lowest observed SSB (9,227 t). Mackerel uses
the lowest SSB that later produced good recruitment (2002, 2004, 2005), with
\(MSYB_{\mathrm{trigger}}=B_{\mathrm{pa}}\). \(F_{\lim}\) is not defined on
these sheets. SAG \(F_{\mathrm{MSY}}\) / \(B_{\lim}\) / \(MSYB_{\mathrm{trigger}}\)
match the sheets, so the backtest HCR does not need a re-knit for reference
points. Celtic Sea cod’s SAG assessment year is 2023 against the 2026 sheet;
the published values are unchanged (ICES 2020).

On scn2, \(MSYB_{\mathrm{trigger}}/B_{\mathrm{MSY}}\) is not one (`06.2`
ICES vs Operating Model table):

| Stock | \(B_{\lim}\) | \(B_{\mathrm{trig}}\) | OM \(B_{\mathrm{MSY}}\) | \(B_{\mathrm{trig}}/B_{\mathrm{MSY}}\) | \(F_{\mathrm{target}}\) | OM \(F_{\mathrm{MSY}}\) |
|---|---:|---:|---:|---:|---:|---:|
| Irish Sea cod | 9,364 | 13,012 | 10,356 | 1.26 | 0.171 | 0.410 |
| Irish Sea whiting | 1,670 | 2,322 | 7,102 | 0.33 | 0.210 | 0.249 |
| Celtic Sea cod | 4,200 | 5,800 | 83,142 | 0.07 | 0.290 | 0.180 |
| Celtic Sea whiting | 36,571 | 50,818 | 37,166 | 1.37 | 0.375 | 0.519 |
| Celtic Sea haddock | 9,227 | 12,822 | 29,086 | 0.44 | 0.353 | 0.275 |
| NE Atlantic mackerel | 3,067,017 | 4,119,337 | 2,948,274 | 1.40 | 0.191 | 0.895 |

Source: `06.2_generic.html` ICES vs Operating Model table. Units are tonnes for biomass and year\(^{-1}\)
for \(F\). A ratio well below one is the expected gap when the trigger is a
\(B_{\mathrm{pa}}\) proxy, not MSY [@winker2026rebuilding]. Celtic Sea cod on
scn2 is the extreme case: the trigger is 5,800 t against an Operating Model
\(B_{\mathrm{MSY}}\) of 83,142 t. Irish Sea whiting and Celtic Sea haddock sit
the same way (0.33 and 0.44). The opposite disagreement also occurs: Irish Sea
cod, Celtic Sea whiting and mackerel have \(MSYB_{\mathrm{trigger}}\)
**above** scn2 \(B_{\mathrm{MSY}}\) (1.26, 1.37, 1.40). Scoring against ICES
points and scoring against Operating Model MSY can therefore disagree in either
direction. \(F_{\mathrm{target}}\) and Operating Model \(F_{\mathrm{MSY}}\)
also differ, most clearly for Irish Sea cod (0.171 versus 0.410) and mackerel
(0.191 versus 0.895).

### Historical versus \(F_{\mathrm{target}}\) versus the advice rule

Black is the assessment. Blue is open-loop \(F_{\mathrm{target}}\) from about
1990. Orange is the ICES advice rule from 2015. Time-series, residual, dynamic
\(B_0\), SRR and production figures for the two funder stocks are in `06.1`;
the same set for the remaining stocks on a generic scn2 OM is in `06.2`. The `06.0` paired
panels remain bh3.

Where historical \(F\) was well above \(F_{\mathrm{target}}\), fishing at
\(F_{\mathrm{target}}\) from 1990 produces a large biomass gain once \(F\) is
cut. On the `05.0` bh1 digest, terminal SSB / \(MSYB_{\mathrm{trigger}}\) under
constant \(F_{\mathrm{target}}\) is 5.10 for Irish Sea whiting and 8.21 for
Celtic Sea cod, against Historical 0.68 and 0.02. The closed-loop advice rule
from 2015 also lifts those stocks (3.85 and 3.45 on that digest), but it is not
the same experiment as fishing at \(F_{\mathrm{target}}\) from 1990: the HCR
only sets \(F = F_{\mathrm{target}}\) once SSB is at or above the trigger, and
it starts later. The `06.1` take-home is the same pattern on the case-study
OMs (scn2 whiting, scn0 Celtic Sea cod): constant \(F_{\mathrm{target}}\)
rebuilds Irish Sea whiting to several times \(MSYB_{\mathrm{trigger}}\); Celtic
Sea cod shows a large biomass gain once \(F\) is cut. Under the advice rule
from 2015, Irish Sea whiting is already above both the trigger and Operating
Model \(B_{\mathrm{MSY}}\) at the advice-rule start; Celtic Sea cod can sit
above the trigger and still be short of Operating Model \(B_{\mathrm{MSY}}\).

Irish Sea cod is the opposite. Historical \(\bar F / F_{\mathrm{target}} \approx
0.07\) (`05.0`; also stated in `06.0`). Fishing *at* \(F_{\mathrm{target}}\)
**lowers** terminal SSB relative to the assessment (`05.0`: Historical 0.54,
\(F_{\mathrm{target}}\) 0.28, advice rule 0.35). Two mechanisms can produce a
realised \(F\) this far below the ICES target, and this backtest does not
separate them. One is mixed-fishery constraint: Irish Sea cod has been treated
as a recovery / choke stock, so catch can sit well below a single-stock TAC
even when the advice rule would allow \(F_{\mathrm{target}}\). The other is a
reference-point mismatch: ICES \(F_{\mathrm{target}}\) is the SAG HCR input,
whereas Operating Model \(F_{\mathrm{MSY}}\) is a different equilibrium
quantity (scn2: 0.410 versus 0.171). Both are far above historical \(\bar F\).

Celtic Sea whiting and haddock are intermediate. Historical SSB is below the
trigger (0.22 and 0.63). Historical \(F\) is above \(F_{\mathrm{target}}\)
(1.42 and 1.78). On the bh1 digest, constant \(F_{\mathrm{target}}\) and the
advice rule both raise SSB / trigger relative to Historical, but Celtic Sea
whiting remains below the trigger (0.38 and 0.47) while haddock just exceeds it
(1.22 and 1.21). Mackerel barely moves: 0.77 Historical, 0.77
\(F_{\mathrm{target}}\), 0.78 advice rule, with Historical
\(F / F_{\mathrm{target}} = 1.39\).

Implementation of the rule is therefore not the historical fishery, and
fishing at \(F_{\mathrm{target}}\) is not the same as following the HCR.

### Residuals, production functions, and the Future window

Catch is not the only driver. The Operating Model uses an SRR plus the log
residual of observed recruitment. Those residuals, with time-varying \(M\),
maturity and mass-at-age, are the observed productivity history, not a climate
covariate [@Lindmark2026productivity]. STARS regime means on those residuals
are shown in `06.1` (two stocks) and `06.2` (all stocks). Irish Sea whiting
recruitment in the assessment is a smooth series, so those residuals are
strongly autocorrelated; they are still the deviations replayed in the
historical backtest. Dynamic unfished SSB (`b0dyn`) replays the assessment at
\(F=0\) with the same SRR, life history and residuals: the gap to assessment
SSB is depletion against a productivity-varying unfished stock, not against a
stationary \(B_0\).

SRR and production-function plots in `06.1` and `06.2` make the hockey-stick
versus compensatory distinction visible. A hockey-stick would be flat to the
right of \(B_{\lim}\). scn2 continues to increase towards \(R_0\).
\(B_{\mathrm{MSY}}\) and \(F_{\mathrm{MSY}}\) on those yield curves are
Operating Model properties. ICES \(B_{\lim}\) and \(MSYB_{\mathrm{trigger}}\)
are not points on that production function.

The Future window is a different experiment. From each Historical-window
terminal state a twenty-year HCR is run with mean biology and **mean**
recruitment (`04.3`; `project_hcr`). That is not a continuation of the residual
history. Rebuild times below are from the **bh3** run already knitted in
`06.0`; they are not scn2.

On that bh3 Future run, Irish Sea whiting reaches \(MSYB_{\mathrm{trigger}}\)
in 2 years from Historical and Operating Model \(B_{\mathrm{MSY}}\) in 7; the
advice-rule start is already above both. Mackerel is already above
\(B_{\mathrm{MSY}}\) while still below the trigger — the same qualitative
disagreement as the scn2 ICES vs Operating Model table, where \(MSYB_{\mathrm{trigger}}/B_{\mathrm{MSY}}
= 1.40\). Irish Sea cod reaches \(B_{\mathrm{MSY}}\) first because that
biomass sits below ICES \(MSYB_{\mathrm{trigger}}\) (scn2 ratio 1.26). Celtic
Sea whiting never reaches the ICES trigger in 20 years from either start, but
it does reach Operating Model \(B_{\mathrm{MSY}}\) in about 16–18 years; on
scn2 the trigger sits above \(B_{\mathrm{MSY}}\) (ratio 1.37). Celtic Sea cod
reaches the ICES trigger in about 9 years from the Historical terminal state;
Operating Model \(B_{\mathrm{MSY}}\) is not reached in 20 years from either
start. The advice-rule start (bh3 closed-loop terminal state) is already above
the trigger (0 years) and still short of Operating Model \(B_{\mathrm{MSY}}\).
Rebuild to the ICES trigger and rebuild to MSY biomass are different targets.

---

## iv) Main findings

Implementation of the ICES advice rule is not the historical fishery. Open-loop
\(F_{\mathrm{target}}\) and the closed-loop HCR answer different questions, and
historical \(F\) was often neither. Irish Sea cod, with historical
\(\bar F \approx 0.07\times F_{\mathrm{target}}\), shows that fishing at the
ICES target can *reduce* SSB relative to what occurred. Celtic Sea cod and
Irish Sea whiting show the converse: had \(F\) been cut to
\(F_{\mathrm{target}}\), SSB would have been several times the trigger.

\(MSYB_{\mathrm{trigger}}\) is not \(B_{\mathrm{MSY}}\). It is an HCR
threshold, usually a \(B_{\mathrm{pa}}\) proxy [@winker2026rebuilding]. On
scn2, \(MSYB_{\mathrm{trigger}}/B_{\mathrm{MSY}}\) ranges from 0.07 (Celtic Sea
cod) to 1.40 (mackerel). Scoring a harvest policy against ICES operational
points and scoring it against Operating Model MSY can disagree, in either
direction. That disagreement is why ICES does not report \(B_{\mathrm{MSY}}\),
and why this report keeps the two objects distinct.

The hockey-stick is the shape of the ICES HCR, not Operating Model truth. EqSim
fits that shape to assessment SSB–recruit pairs in an open-loop equilibrium
scan. The backtest projects a compensatory SRR (scn2 in the all-stock note) and
scores MSY on that SRR. Using the hockey-stick as the Operating Model would
treat the truncated ICES production function as the population.

The residuals replayed in the Historical window are observed productivity, not
SST and not a climate projection [@Lindmark2026productivity]. The Future window
switches that history off and uses mean recruitment. The two windows are
different experiments.

One Operating Model is shown so that the control-point versus performance-metric
distinction remains readable. Structural uncertainty is not thereby removed; it
sits in `eqls` (bh1–rk3, scn0–scn2) and in the corresponding `04.1` / `04.2`
outputs.

---

## v) Next steps

Remaining gated stocks can be read from `05.0_digest.Rmd`; `06.2` already
standardises every stock currently in the gate on scn2, while `06.1` remains
the funder pair. Optional SAM observation error (`04.4_closedLoop_sam.Rmd`) is
a robustness check, not the base case. A peer-review paper is outlined in
`docs/paper_outline.md`. The Historical | Future figures in `06.0` should be
reinstalled on scn2 if the contract report is to show the same hypothesis as
`06.2`; they currently remain bh3. This report does not offer climate-forced
recruitment projections.
