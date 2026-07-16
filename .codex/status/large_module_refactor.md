# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-quality-gate-operator-training-summary callback-bag collapse.

Status:
Completed and ready to publish.

Selected slice:
Replace the 16-entry callback bag in
`OperationalQualityGateOperatorTrainingSummaryContracts` with direct primitive
and stable-ID owners, explicit model-limit data, and cohesive local count/ID-map
derivations.

Why this slice:
Live inventory leaves `schema.ex` as the dominant production hotspot at 12,135
lines. The adjacent 303-line operator-training summary owner has 16 callback
trampolines: ten target shared validators, one is model-limit data, and five are
small pure collection derivations that belong with the summary rules. Focused
quality-gate replay, operator-review, readiness, and export coverage is
available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all operator-training summary
behavior, including requirement counts/IDs, role/training/certification lists,
quality-gate row and gate ID maps, review flags, assumptions, exact messages,
model limits, deterministic errors, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_quality_gate_operator_training_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No operator-training-summary callback bag or shared-helper trampolines remain;
direct shared owners, explicit model data, and cohesive pure derivations preserve
exact validation order/messages; focused/broader/export checks pass; and bounded
review finds no blocker.

Completed result:
Removed the 16-entry operator-training-summary callback bag and all owner
trampolines. Primitive, stable-ID, and collection aggregation behavior now
calls exact owners directly; model limits are explicit data; map-sum and
list-fallback rules remain cohesive and exact. `schema.ex` fell from 12,135 to
12,110 lines and the owner from 303 to 241.

Verification:
- compile with warnings as errors passed
- 53 focused readiness/schema/quality-gate replay/review tests passed
- 1,051 broader candidate-refresh/operator-review tests passed
- 22 schema-export tests passed
- compile-connected xref, format, diff hygiene, and checked-in schema
  regeneration were clean
- bounded read-only review found no issues

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-execution-boundary-summary callback collapse published as
`90b8ffe4`: `schema.ex` fell from 12,163 to 12,135 lines and its owner from 332
to 263. The 18-entry bag became direct primitive/stable/readiness owners,
explicit model-limit data, one gate-validator boundary, and local pure boundary
and count rules. 44 focused, 1,051 broader, and 22 export tests passed; compile,
xref, format, diff hygiene, checked-in schema regeneration, and bounded review
were clean.

Blocked:
No.
