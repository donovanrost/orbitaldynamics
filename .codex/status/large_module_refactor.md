# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-report validation extraction.

Status:
Completed and published.

Selected boundary:
Extract optional contact-filter, contact-contention, and
contact-contention-resolution report validation into
`OrbitalDynamics.Schema.ContactReportValidation`. Preserve the existing
arity-2 and arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 7,023 lines; the selected contact-report seams span
  5,872-5,905 and 5,952-5,963.
- The cluster has one responsibility: validate optional communications contact
  evidence before it is consumed by campaign and allocation contracts.
- Its only nested row dependency already has a production owner in
  `ResourceValidation`; the report contract modules and primitive error
  construction can be called directly by the new owner.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,863 files with warnings as errors.
- Focused filter and communications contracts passed: 13 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 8 valid and mutated standalone
  and nested contact-report fixtures.
- Static inspection confirms the facade retains only its arity-2/arity-3
  callback seams; runtime xref reports `Schema` as the sole caller of the new
  owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema contact-report validation extraction, selected in `5e53f326` and
implemented in `d4cd41ab`. `schema.ex` moved from 7,023 to 6,991 lines; the
dedicated owner is 51 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after contact-report
validation has one production owner.

Blocked:
No.
