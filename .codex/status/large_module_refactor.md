# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate-report callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 25-entry callback bag in `QualityGateReportContracts` with direct
primitive, stable-ID, collection, quality-gate-row aggregation, and readiness-
classification owners, explicit model-limit data, one facade-owned row
validator, and cohesive local boundary/error rules.

Why this slice:
Live inventory leaves `schema.ex` as the dominant production hotspot at 11,955
lines. The 402-line report owner is the remaining core quality-gate callback
surface. The preceding row-aggregation cleanup now provides direct `ids_by`,
`row_ids_by`, and `ids` APIs, eliminating the drift concern identified during
the summary review. Focused report/replay/review/export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all `quality_gate_report.v1`
behavior, including classification/readiness/status/boundary derivation, gate
and row counts/maps/ID sets, optional lists, assumptions, exact errors, model
limits, deterministic output, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/quality_gate_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No quality-gate-report callback bag or shared-helper trampolines remain; direct
shared owners, explicit model data, the row-validator boundary, and cohesive
local rules preserve exact validation/error order and messages; focused/
broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Quality-gate-row aggregation ownership cleanup published as `217d5067`:
`QualityGateRowContracts.ids_by`, `row_ids_by`, and `ids` now own exact stable
sorting directly; the unused row-validator callback entry was removed and
Schema wrappers were simplified. 54 focused, 1,051 broader, and 22 export tests
passed; compile, xref, format, diff hygiene, checked-in schema regeneration,
and bounded review were clean.

Blocked:
No.
