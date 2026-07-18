# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-metric calculation policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move numeric replacement/source delta and positive-planned completion-fraction
calculation into `Timeline.ActivityMetricCalculationPolicy`. `Timeline` retains
two private entry points. The boundary has no callbacks, module attributes, or
shared vocabulary arguments.

Why this slice:
The reduced Timeline facade is 6,603 lines. These four exclusive clauses own
numeric-only delta behavior and the positive-denominator completion rule used
by data-volume, throughput, latency, delivery, thermal, diff, and activity
context surfaces.

Planned proof:
- Focused data-volume completion, throughput completion, latency, delivery,
  thermal, and diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all four moved clauses after normalizing only
  the two facade names.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-timing policy extraction, selected in `b81cc29b`,
implemented in `da906de9`, and handed off in `2da63bf9`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding boundaries whose
guard vocabularies remain shared with Timeline.

Blocked:
No.
