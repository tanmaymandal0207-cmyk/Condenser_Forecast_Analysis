# Changelog

## 21 Nov 2026 — README cross-links

### Added
- README: Related Projects section linking Inventory Reconciliation, Commercial Intelligence Dashboard and SQL Business Problems (20 Nov 2026).
- README: LinkedIn link in the author footer.
- README: Related added to the section navigation (22 Nov 2026) and a back-to-top link above the author footer (23 Nov 2026).

## 18 Nov 2026 — Renamed to Condenser Forecast Analysis

### Changed
- Repository renamed from `Swift_Condenser_Legacy_Analysis` to `Condenser_Forecast_Analysis`, as the project now covers the condenser forecasting pilot (Phase 2), not only the PC-86207 demand-gap study (Phase 1). GitHub redirects the old URL.
- `assets/banner.svg`: new banner, "Condenser Forecast Analysis", with a chart of condenser pieces by financial year (FY 2022–23 highlighted, FY 2026–27 partial), a trend line and a dashed forecast band.
- README: banner alt text, overview line and repository tree updated to the new name.

## 18 Nov 2026 — Phase 2: forecasting pilot data foundation

### Added
- `docs/data-model.md`: star schema for the condenser pilot (ER diagram), monthly grain with FY-quarter roll-up, source cut-over rule (challan register to Mar 2019, Excel files from Apr 2019), code-matching rules and the checks run after each load.
- `sql/`: BigQuery scripts for load checks, client code decisions, the combined monthly and quarterly condenser series, and a one-row validation summary. Placeholder project names and the anonymised `PC-` pattern.
- `pipeline/excel_to_long.py`: loads the yearly sales workbooks, stops if a file does not reconcile to its *Totals* row, matches condenser codes to the master list and writes the BigQuery load files. Reproduces the client run exactly (38,114 rows; 169,628 condenser pcs).
- `deliverables/migration-status-report.md`: anonymised version of the status report sent to the client: progress, checks, volumes by financial year and open items A–F.
- Glossary terms for Phase 2 (master list, code map, grain, FY quarter, cut-over, Q5 grade, provisional).

### Changed
- README: two-phase overview, Phase 2 section with data-flow and FY volume charts, updated observation on PC-86207 / PC-86539 / PC-86815 from the 2019–2026 data, data limitations, repository tree, and a combined status table.
- `deliverables/client-ready-report.md`: section 5a with the 2019–2026 update; post-2019 limitation updated.
- `deliverables/commitments.md`, `deliverables/README.md`, `docs/data-requirements.md`: Phase 2 deliverables and data status.
- `.gitignore`: also excludes `out/`, PDFs and pickles, so client exports and the client PDF stay out.

### Results
- 47 of 47 old challan codes resolved with the client (18 auto, 16 accepted, 2 kept as own parts, 11 excluded = 2,742 pcs).
- 0 unmapped codes, 0 duplicate parts; 338,096.5 condenser pcs, Apr 2009 – Oct 2026.

## Unreleased — 17 Nov 2026

### Added
- `docs/glossary.md`: definitions of challan, dispatch, FY, `PC-` codes, fitment, multi-application codes, code transition and the other terms used in the brief; linked from the methodology.
- `docs/data-requirements.md`: the data request list for the five validation steps, with minimum fields, acceptance checks and handling rules; linked from Status & Next Steps.

## 16 Nov 2026

### Added
- `.gitattributes`: LF for Markdown and SVG, binaries marked as binary.
- `.gitignore`: keeps client source data (Excel, CSV, `data/`, `raw/`) and Excel lock files out of the repo.

### Changed
- `deliverables/README.md`: file index with purpose and status.
- `research/README.md`: explains that drafts are kept unchanged and how the first draft's brand-level framing narrowed to the PC-86207 question.

## 15 Nov 2026

### Changed
- README restructured to match the other portfolio repos: badges, section links, observations table that separates findings from what they do not yet prove, actual repository tree, status and next steps.
- Client and brand anonymised: the client is referred to only as an automotive parts distributor and the brand part-code prefix is replaced by `PC-` (as in Inventory Reconciliation). Banner updated to `PC-86207`; title no longer overlaps the condenser graphic or accent bar, and the subtitle fits the banner width.
- `deliverables/client-ready-report.md` rewritten around the condenser demand question, with findings, confidence levels and validation steps.
- `deliverables/commitments.md` condensed into scope, analytical, data-handling and deliverable commitments.

### Kept
- `research/01-first-draft.md` is the original working draft and is left unchanged for traceability.

## 10 Nov 2026

### Added
- Research first draft, client-ready report and project commitments.
- Repository banner and project README.
