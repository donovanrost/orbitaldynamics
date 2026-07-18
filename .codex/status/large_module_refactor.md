# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline integrity-ID grouping policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move deterministic timeline row IDs, integrity scope IDs, IDs grouped by issue
type or row field, grouped ID sorting, row-list IDs, and diff-status IDs into
`Timeline.IntegrityIdGroupingPolicy`. `Timeline` retains seven private entry
points; list extraction and sorted uniqueness cross the boundary explicitly.

Why this slice:
The 6,249-line Timeline facade still owns seven exclusive ID aggregation
clauses shared by operational, diff, and integrity summaries. Moving them
together isolates filtering, pair construction, nil rejection, group ordering,
per-group deduplication, and status-scoped ID selection without extracting
report coordinators.

Planned proof:
- Focused dependency/exclusivity review, public integrity summary, and timeline
  diff integrity examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all seven moved clauses after normalizing only
  public/private heads, list/sort callbacks, and internal callback threading.
- Format, diff, whitespace, ownership, exactly-seven-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline integrity-count policy extraction, selected in `75c68200`, implemented
in `66d1c585`, and handed off in `00c79917`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
