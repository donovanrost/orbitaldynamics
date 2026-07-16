# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-quality-gate-schema-validation-summary callback-bag collapse.

Status:
Completed and ready to publish.

Selected slice:
Replace the 16-entry callback bag in
`OperationalQualityGateSchemaValidationSummaryContracts` with direct primitive,
stable-ID, and collection-aggregation owners, explicit model-limit data, and
cohesive local blocked/subset rules.

Why this slice:
Live inventory leaves `schema.ex` as the dominant production hotspot at 12,110
lines. The adjacent 332-line schema-validation summary owner has 16 callback
trampolines: shared validators and aggregation functions have exact owners,
model limits are data, and the remaining blocked/subset/error behavior is a
small cohesive summary rule. Focused quality-gate replay, operator-review,
readiness, and export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all schema-validation summary
behavior, including status counts/IDs, import blocking, quality-gate row/gate
ID sets, failed-row subset checks, assumptions, exact errors, model limits,
replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_quality_gate_schema_validation_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No schema-validation-summary callback bag or shared-helper trampolines remain;
direct shared owners, explicit model data, and cohesive local rules preserve
exact validation and error order/messages; focused/broader/export checks pass;
and bounded review finds no blocker.

Completed result:
Removed the 16-entry schema-validation-summary callback bag and all owner
trampolines. Primitive, stable-ID, and collection aggregation behavior now
calls exact owners directly; model limits are explicit data; blocked/subset
rules and errors remain cohesive and unchanged. `schema.ex` fell from 12,110
to 12,088 lines and the owner from 332 to 265.

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
Operational-quality-gate-operator-training-summary callback collapse published
as `9218f0d4`: `schema.ex` fell from 12,135 to 12,110 lines and its owner from
303 to 241. The 16-entry bag became direct primitive/stable/aggregation owners,
explicit model-limit data, and local exact map/list fallbacks. 53 focused,
1,051 broader, and 22 export tests passed; compile, xref, format, diff hygiene,
checked-in schema regeneration, and bounded review were clean.

Blocked:
No.
