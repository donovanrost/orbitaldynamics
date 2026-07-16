# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-import-eligibility-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 17-entry callback bag in
`OperationalImportEligibilitySummaryContracts` with direct primitive, stable-ID,
collection, and readiness-classification owners, explicit model-limit data, and
one facade-owned gate validator.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,216 lines. The 259-line import-eligibility owner has 17 callback trampolines;
most target shared validators or readiness-classification/count owners, one is
model-limit data, and only nested readiness-gate validation remains a facade
boundary. Focused readiness, replay, review, and export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all import-eligibility summary
behavior, including classification/status derivation, gate totals, non-passed
rows, assumptions, exact messages, model limits, deterministic errors, replay
consumers, and exports.

Likely extraction target:
Replace the opaque bag with explicit model-limit data plus the gate validator;
remove shared-helper trampolines and call exact primitive, stable-ID,
collection-validation, and readiness-classification owners directly.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_import_eligibility_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- operational-readiness and import-eligibility schema contracts
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No import-eligibility callback bag or shared-helper trampolines remain; direct
owners, explicit model data, and the gate-validator boundary preserve exact
validation order/messages; focused/broader/export checks pass; and bounded
review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to the completed
  filter-count slice.

Last completed slice:
Filter-report-count callback collapse published as `6ebc1694`: `schema.ex` fell from
12,226 to 12,216 lines and its owner from 365 to 317. The four-entry bag became
direct primitive owners plus exact local nil/default equality-message clauses;
all callback trampolines were removed. 71 focused, 798 broader, and 22 export
tests passed; compile, xref, format, diff hygiene, and checked-in schema
regeneration were clean. Bounded review found no issues.

Blocked:
No.
