# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state summary metrics policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move duplicate match counts, planned/realized match activity IDs,
operator-action reason frequencies, filtered timeline IDs, and flattened review
activity IDs into `Timeline.LifecycleStateSummaryMetricsPolicy`. `Timeline`
retains five private entry points; list extraction, count-map sorting, and
sorted uniqueness cross the boundary explicitly.

Why this slice:
The 6,270-line Timeline facade still owns six exclusive aggregate clauses below
the lifecycle-state summary coordinator. Moving them together isolates
duplicate cardinality, ID fallback order, row filtering, flattened activity-ID
collection, reason frequencies, and deterministic ordering without extracting
summary row assembly.

Planned proof:
- Focused lifecycle-state handoff and multi-activity summary examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all six moved clauses after normalizing only
  public/private heads, list/sort callbacks, and internal callback threading.
- Format, diff, whitespace, ownership, exactly-five-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-application activity policy extraction, selected in
`fed4f449`, implemented in `2c96d882`, and handed off in `d0f637cb`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
