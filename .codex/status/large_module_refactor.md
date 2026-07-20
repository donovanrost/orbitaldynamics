# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema activity-artifact owner extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Registry contract source, timeline capability source, validation
ordering and paths, public `Schema`, validation results, and checked-in exports
must remain unchanged.

Last completed slice:
Schema proposed-contact owner completion, selected in `b7fc688e` and implemented
in `c6c6fc6a`. `schema.ex` moved from 4,724 to 4,722 lines.

Next candidate:
Implement and verify the selected activity-artifact owner, then re-rank the
remaining Schema responsibility clusters.

Blocked:
No.
