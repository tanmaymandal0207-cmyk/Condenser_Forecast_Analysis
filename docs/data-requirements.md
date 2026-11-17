# Data Requirements for Validation

The five validation steps in the [client report](../deliverables/client-ready-report.md#5-recommended-validation-steps) need data that is not yet in hand. This is the request list to send to the client, with the checks each extract must pass before it is used.

| # | Validation step | Data requested | Minimum fields | Acceptance check |
|---|---|---|---|---|
| 1 | Classify PC-86539 by vehicle application | Challan lines for PC-86539 and other multi-application condenser codes | Challan no., date, part code, full line description, qty, distributor | Line count and total qty per FY tie to the challan register |
| 2 | Reconcile post-2019 figures | Original transaction records from Jun 2019 onwards | Same fields as the 2009–2019 challan history | Monthly totals tie to the provisional figures, or every difference is explained |
| 3 | Test supplier substitution | Distributor-level purchase history across all Swift condenser codes | Distributor, date, part code, qty | Every distributor in the dispatch history is present; no unmapped codes |
| 4 | Refresh competitor pricing | Dated quotations for comparable condensers | Supplier, part / OEM reference, fitment, price, tax treatment, quote date | Like-for-like on fitment and tax; quote date within the last 6 months |
| 5 | Size the replacement market | Swift / Dzire sales or registration cohorts | Model, generation, year, units | Source and year stated; cohorts align with the fitment mapping |

## Handling

- Extracts stay outside this repository (`.gitignore` blocks Excel and CSV files).
- Distributor and customer names are pseudonymised before any figure is published, following the same rules as [Inventory Reconciliation](https://github.com/tanmaymandal0207-cmyk/inventory-reconciliation/blob/main/docs/anonymisation.md).
- Each extract is logged in the [CHANGELOG](../CHANGELOG.md) with the date received and its acceptance-check result.
