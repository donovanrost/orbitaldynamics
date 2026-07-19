# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-context JSON Schema extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract validation issues, remediation, batch/migration/skipped rows, validation
records, registry conditions, model-acceptance and safety-case rows, reference
reports, and checks into
`OrbitalDynamics.Schema.ValidationContextJsonSchema`. Preserve the existing
private Schema helper seams.

Selection evidence:
- `schema.ex` is 6,764 lines; the selected contiguous validation-schema cluster
  spans 3,726-3,788.
- The cluster has one responsibility: construct reusable validation, migration,
  acceptance, and safety-case evidence schemas.
- Stable-ID patterns, validation levels, and the registry-backed batch report
  document remain facade-owned inputs to the new owner.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused validation-schema baselines, exact old/new JSON Schema
documents, strict compile, broader Schema contract tests, JSON Schema export
checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema strategy-context JSON Schema extraction, selected in `42dddf3b` and
implemented in `f6d4ad0b`. `schema.ex` moved from 6,786 to 6,764 lines; the
dedicated owner is 77 lines.

Next candidate:
Re-inventory remaining Schema families after validation-context JSON Schema
construction has one production owner.

Blocked:
No.
