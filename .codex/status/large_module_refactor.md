# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-quality-gate-unavailable-resource-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 15-entry callback bag in
`OperationalQualityGateUnavailableResourceSummaryContracts` with direct
primitive, stable-ID, and collection-aggregation owners, explicit model-limit
data, and cohesive local reason/count derivations.

Why this slice:
Live inventory leaves `schema.ex` as the dominant production hotspot at 12,088
lines. The adjacent 296-line unavailable-resource summary owner has 15 callback
trampolines: shared validators and aggregation functions have exact owners,
model limits are data, and the remaining unavailable/station reason rules are
small cohesive summary logic. Focused unavailable-resource replay, readiness,
operator-review, and export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all unavailable-resource
summary behavior, including reason/count maps, blocked contact groupings,
quality-gate row/gate IDs, assumptions, exact messages, model limits,
deterministic errors, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_quality_gate_unavailable_resource_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/unavailable-resource replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No unavailable-resource-summary callback bag or shared-helper trampolines remain;
direct shared owners, explicit model data, and cohesive local rules preserve
exact validation and error order/messages; focused/broader/export checks pass;
and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-quality-gate-schema-validation-summary callback collapse published
as `3742f6de`: `schema.ex` fell from 12,110 to 12,088 lines and its owner from
332 to 265. The 16-entry bag became direct primitive/stable/aggregation owners,
explicit model-limit data, and unchanged local blocked/subset rules. 53 focused,
1,051 broader, and 22 export tests passed; compile, xref, format, diff hygiene,
checked-in schema regeneration, and bounded review were clean.

Blocked:
No.
