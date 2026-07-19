# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operational-readiness context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract adapter-boundary, resource, operator-training, and Cadence-import
operational-readiness context projections into
`OrbitalDynamics.CadenceImport.OperationalReadinessContext`. Preserve the
facade's four existing callback seams as delegates for operational-readiness and
quality-gate row builders.

Selection evidence:
- `cadence_import.ex` is now 3,225 lines.
- The selected contiguous family spans about 120 lines and is shared by
  operational-readiness and quality-gate row builders through stable callbacks.
- The family has one responsibility: project typed readiness evidence with the
  existing top-level-value-first, nested-evidence-fallback precedence.
- Manifest assembly, row construction, map compaction, capability metadata,
  schemas, and ordering remain outside the boundary.

Verification:
Pending: focused operational-readiness and quality-gate baselines, executable
old-AST equivalence across all four projections, strict compile, all combined
CadenceImport tests, schema contracts, static single ownership, runtime xref,
and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-summary context extraction, selected in `18611476` and
implemented in `19e4312d`. `cadence_import.ex` moved from 3,337 to 3,225 lines;
the extracted owner is 122 lines.

Next candidate:
Return to manifest assembly after operational-readiness context projections
have one production owner.

Blocked:
No.
