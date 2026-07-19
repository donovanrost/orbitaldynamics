# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema source-evidence validation extraction.

Status:
Completed and published.

Selected boundary:
Extract source-evidence field validation plus freshness, schema-validation, and
execution source-status matching into
`OrbitalDynamics.Schema.SourceEvidenceValidation`. Preserve the existing
arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,912 lines; the selected contiguous cluster spans
  6,664-6,711.
- The cluster has one responsibility: validate nested source evidence and
  ensure its declared statuses match source artifacts.
- Freshness and schema-validation status catalogs remain shared facade/export
  data and can be passed to the new owner; execution statuses and handoff
  validators are already independently owned.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,867 files with warnings as errors.
- Focused Cadence-import and operator-review contracts passed: 6 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 9 valid, matching, mismatched,
  invalid, and malformed source-evidence/status fixtures.
- Static inspection confirms the facade retains only its arity-3 seams plus
  shared status-catalog inputs; runtime xref reports `Schema` as the sole caller
  of the new owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema source-evidence validation extraction, selected in `32c1639d` and
implemented in `dde67b49`. `schema.ex` moved from 6,912 to 6,888 lines; the
dedicated owner is 40 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after source-evidence
validation has one production owner.

Blocked:
No.
