# Methods notebooks

The contract supplement **is** these notebooks. Index:
[`00_supplement.Rmd`](00_supplement.Rmd).

Do not duplicate figures from `06.0_report.Rmd`.

## Knit order

| Role | Notebook | Required before next |
|------|----------|----------------------|
| Inventory | `01_screening.Rmd` | — |
| Condition | `02.0_condition_om.Rmd` | 01 |
| **Gate** | `02.1_lterm_eq.Rmd`, `02.2_dynamics.Rmd` | 02.0; **04.* stop without these** |
| Generic backtest | `04.1_openLoop.Rmd`, `04.2_closedLoop.Rmd` | gate; same OM, two policies |
| Forward | `04.3_rebuild.Rmd` | 04.2 |
| All-stock digest | `05.0_digest.Rmd` | 04.1 + 04.2 |
| Case studies | `06.1_TwoStocks.Rmd` | 04.* (Irish Sea whiting, Celtic Sea cod) |
| Generic OM, scn2 | `06.2_generic.Rmd` | 04.1 + 04.2 |
| Contract report | `06.0_report.Rmd` | loads results only |

Optional, off the generic path: `04.4_closedLoop_sam.Rmd`,
`07_srr_internal_external.Rmd`.

## FLR vs this project

See [`docs/FLR_methods.md`](../docs/FLR_methods.md).
