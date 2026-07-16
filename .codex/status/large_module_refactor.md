# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-quality-gate-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 24-entry callback bag in
`OperationalQualityGateSummaryContracts` with direct primitive, stable-ID,
collection, aggregation, and readiness-classification owners, explicit
model-limit data, one facade-owned quality-gate-row validator, and cohesive
local grouping/boundary rules.

Why this slice:
Live inventory leaves `schema.ex` as the dominant production hotspot at 11,996
lines. The 462-line core quality-gate summary owner is the natural consolidation
point after its adjacent operator-training, schema-validation,
unavailable-resource, and import-readiness owners were made direct-owner based.
Its 24 callbacks have exact shared owners or bounded pure summary rules, with
focused quality-gate replay/review/export coverage available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all operational quality-gate
summary behavior, including classification/readiness/status/boundary derivation,
gate and row counts/maps/ID sets, assumptions, exact messages, model limits,
deterministic output/errors, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_quality_gate_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No core quality-gate-summary callback bag or shared-helper trampolines remain;
direct shared owners, explicit model data, the row-validator boundary, and
cohesive local rules preserve exact validation/error order and messages;
focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-quality-gate-import-readiness-summary callback collapse published
as `c9af94db`: `schema.ex` fell from 12,049 to 11,996 lines and its owner from
512 to 413. The 20-entry bag became direct primitive/stable/aggregation owners,
explicit model data, one final timeline-context validator boundary, and
unchanged local routing/subset rules. 49 focused, 1,051 broader, and 22 export
tests passed; compile, xref, format, diff hygiene, checked-in schema
regeneration, and bounded review were clean.

Blocked:
No.
