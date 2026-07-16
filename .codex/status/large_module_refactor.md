# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate-row aggregation ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Make `QualityGateRowContracts` own stable sorting for `ids_by`, `row_ids_by`,
and `ids`; remove the aggregation-only callback parameter and the unused
`stable_sorted_ids` row-validator callback entry; update facade wrappers and
callers without changing results.

Why this slice:
The completed core-summary review identified future drift risk because its
grouping logic had to reproduce `QualityGateRowContracts` callback-driven
aggregation. The 144-line row owner already owns these algorithms, while the
stable-sort callback is not used by row validation. Consolidating this boundary
before the 402-line quality-gate-report callback cleanup avoids a second copied
implementation and makes the next slice smaller and safer.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, quality-gate row validation, and
all report/summary gate-ID grouping, deduplication, sorting, status counts,
error ordering, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/quality_gate_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
Quality-gate row aggregation no longer requires a callback bag; stable sorting
has one cohesive owner; row validation behavior is unchanged; focused/broader/
export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-quality-gate-summary callback collapse published as `8a32655d`:
`schema.ex` fell from 11,996 to 11,968 lines and its owner from 462 to 400. The
24-entry bag became direct primitive/stable/collection/classification owners,
explicit model data, one row-validator boundary, and exact local grouping/
boundary rules. 54 focused, 1,051 broader, and 22 export tests passed; compile,
xref, format, diff hygiene, checked-in schema regeneration, and bounded review
were clean.

Next candidate:
Collapse the 25-entry `QualityGateReportContracts` callback bag using the new
direct row aggregation API.

Blocked:
No.
