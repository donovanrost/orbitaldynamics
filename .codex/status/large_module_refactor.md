# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema activity-artifact owner extraction.

Status:
Complete and pushed.

Selected boundary:
Add a focused `ActivityArtifactValidation` owner for
`activity_template.v1` and `planned_activity.v1`. Resolve each full registry
contract inside the owner, resolve timeline capabilities for templates, and
route both direct `Schema` clauses through it.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,722 lines; the other
  targeted public facades are now 164 to 524 lines.
- The two adjacent clauses are the complete activity-definition/planning
  artifact pair and both currently expose registry orchestration in the facade.
- Their isolated registry modules and timeline capability context provide every
  input a focused owner needs.
- No route needs recursive `Schema` lookup.

Implementation:
Added a 39-line `ActivityArtifactValidation` owner that resolves the
activity-template and planned-activity registry contracts and the existing
timeline capability context. Routed both direct `Schema` clauses through it.
`schema.ex` moved from 4,722 to 4,712 lines.

Verification:
- Strict focused baseline: 19 tests passed.
- Activity, capability, cadence, review, export, validation, and fixture
  adjacency: 33 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,088 files successfully.

Behavior/schema changes:
None. Registry contract source, timeline capability source, validation ordering
and paths, public `Schema`, validation results, and checked-in exports remain
unchanged.

Last completed slice:
Schema activity-artifact owner extraction, selected in `ce7e1eca` and
implemented in `65e3a783`. `schema.ex` moved from 4,722 to 4,712 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses. Capability-catalog
full-registry context and result-artifact recursion remain the two explicit
facade-coupled routes.

Blocked:
No.
