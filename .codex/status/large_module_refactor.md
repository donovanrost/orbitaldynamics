# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication invalidation policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move downstream invalidation ID selection and validation, reason
classification/grouping/counting, publication/downstream status selection, and
publication-summary ID construction into
`Timeline.PublicationInvalidationPolicy`. `Timeline` retains seven private
entry points; the dependency-impact review predicate becomes policy-internal.

Why this slice:
The 6,366-line Timeline facade still owns 13 contiguous, pure clauses for one
publication responsibility. They have no callback dependencies, and their
ordering-sensitive validation and precedence rules can move together without
extracting the much wider publication-summary map coordinator.

Planned proof:
- Focused publication summary example covering dependency-impact invalidation,
  supersession identity, no-impact status, grouped reason counts, schema
  validation, and invalid explicit invalidation IDs.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 13 moved clauses after normalizing only
  public/private heads.
- Format, diff, whitespace, ownership, exactly-seven-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity delivery-timing policy extraction, selected in `615501f8` and
implemented in `0154cab2`, and handed off in `f99882b8`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding the
wide publication-summary and activity-context map coordinator callback
surfaces.

Blocked:
No.
