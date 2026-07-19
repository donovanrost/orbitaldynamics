# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection validation extraction.

Status:
Selected; implementation has not started.

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
Pending: focused candidate-rejection baselines, exact old/new fixture
validation reports, strict compile, broader Schema contract tests, JSON Schema
export checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema contact-report validation extraction, selected in `5e53f326` and
implemented in `d4cd41ab`. `schema.ex` moved from 7,023 to 6,991 lines; the
dedicated owner is 51 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after
candidate-rejection validation has one production owner.

Blocked:
No.
