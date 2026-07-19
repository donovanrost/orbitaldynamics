# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection validation extraction.

Status:
Completed and published.

Selected boundary:
Extract candidate-rejection report validation, optional nested report
validation, and optional source-row validation into
`OrbitalDynamics.Schema.CandidateRejectionValidation`. Preserve the existing
arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,991 lines; the selected contiguous cluster spans
  6,383-6,423.
- The cluster has one responsibility: validate standalone and nested
  candidate-rejection evidence.
- Model limits remain shared facade/export data and required-field lookup
  remains registry-owned; both can be passed into the new validator without
  moving registry or JSON Schema responsibilities.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,864 files with warnings as errors.
- Focused candidate-rejection contracts passed: 2 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 8 valid, missing, nested, and
  malformed candidate-rejection fixtures.
- Static inspection confirms the facade retains only its arity-3 callback
  seams; runtime xref reports `Schema` as the sole caller of the new owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema candidate-rejection validation extraction, selected in `2a36e107` and
implemented in `deae0f5a`. `schema.ex` moved from 6,991 to 6,972 lines; the
dedicated owner is 36 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after
candidate-rejection validation has one production owner.

Blocked:
No.
