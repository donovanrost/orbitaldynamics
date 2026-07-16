# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-timeline-report callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 15-entry callback bag in `OperationalTimelineReportContracts` with
direct primitive, stable-ID, collection-validation, and collection-aggregation
owners, explicit timeline model-limit data, and the one facade-owned row
validator function.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,307 lines. The 471-line operational-timeline owner contains 15 callback
trampolines; most target shared primitive/collection validators, while timeline
row validation remains a facade boundary. Focused timeline report, replay,
review, export, and broader candidate-refresh coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all operational-timeline report
behavior, including validation order/messages, optional aggregates, row
validation, timeline model limits, deterministic errors, replay consumers, and
exports.

Likely extraction target:
Replace `validate/4` with an explicit signature accepting timeline model-limit
data plus the row validator. Remove the schema bag and owner trampolines, call
shared validators and collection aggregations directly, and preserve the
five-argument field-equality default-message behavior exactly.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_timeline_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline-report schema contracts and validation fixtures
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No operational-timeline report callback bag or shared-helper trampolines remain;
explicit model data and the one row-validator boundary preserve exact behavior,
including default equality messages; focused/broader/export checks pass; and
bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Contact-contention-resolution-summary callback collapse published as
`79e3e39a`:
`schema.ex` fell from 12,357 to 12,307 lines and its owner from 509 to 421. The
18-entry bag became direct shared owners, explicit model-limit data, and one
policy-validator boundary; four newly dead facade wrappers were removed. 62
focused, 761 broader, and 22 export tests passed; compile, xref, format, diff
hygiene, and checked-in schema regeneration were clean. Bounded review found no
issues; malformed-input ordering was reviewed structurally rather than through
exhaustive differential generation.

Blocked:
No.
