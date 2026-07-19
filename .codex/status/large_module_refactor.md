# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema source-evidence validation extraction.

Status:
Selected; implementation has not started.

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
Pending: focused source-evidence/status baselines, exact old/new fixture
validation reports, strict compile, broader Schema contract tests, JSON Schema
export checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema timeline-context validation extraction, selected in `7cc168a1` and
implemented in `07f20eef`. `schema.ex` moved from 6,950 to 6,912 lines; the
dedicated owner is 76 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after source-evidence
validation has one production owner.

Blocked:
No.
