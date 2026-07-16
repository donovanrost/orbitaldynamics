# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-quality-gate-import-readiness-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 20-entry callback bag in
`OperationalQualityGateImportReadinessSummaryContracts` with direct primitive,
stable-ID, and collection-aggregation owners, explicit model-limit data, one
facade-owned timeline-publication-context validator, and cohesive local import
readiness/subset rules.

Why this slice:
Live inventory leaves `schema.ex` as the dominant production hotspot at 12,049
lines. The adjacent 512-line import-readiness owner has 20 callback trampolines:
shared validators and aggregations have exact owners, model limits are data,
only timeline-publication-context validation remains a facade dependency, and
focused replay/review/export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all quality-gate import-readiness
summary behavior, including validation counts/status IDs, import-blocking and
publication context, row/gate ID sets, failed-row subset checks, assumptions,
exact errors, model limits, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_quality_gate_import_readiness_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/import-readiness replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No import-readiness-summary callback bag or shared-helper trampolines remain;
direct shared owners, explicit model data, the context-validator boundary, and
cohesive local rules preserve exact validation/error order and messages;
focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-quality-gate-unavailable-resource-summary callback collapse
published as `25827a01`: the live 17-entry bag was removed; `schema.ex` fell
from 12,088 to 12,049 lines and its owner from 296 to 230. Direct
primitive/stable/aggregation/readiness-reason owners, explicit model data, and
the exact local count sum replaced the bag. 53 focused, 1,054 broader, and 22
export tests passed; compile, xref, format, diff hygiene, checked-in schema
regeneration, and bounded review were clean.

Blocked:
No.
