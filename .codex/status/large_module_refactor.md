# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline integrity-ID grouping policy extraction.

Status:
Implementation published in `fcdc3670`; focused and broad proof is green.

Selected boundary:
Move deterministic timeline row IDs, integrity scope IDs, IDs grouped by issue
type or row field, grouped ID sorting, row-list IDs, and diff-status IDs into
`Timeline.IntegrityIdGroupingPolicy`. `Timeline` retains six private entry
points; grouped ID sorting becomes policy-internal, while list extraction and
sorted uniqueness cross the boundary explicitly.

Why this slice:
The extraction moved seven clauses into a 55-line internal module. Timeline
retains six private entry points and is now 6,250 lines; the one-line facade
increase makes list/sort dependencies explicit, while grouped sorting becomes
policy-internal. Filtering, pair construction, nil rejection, group ordering,
per-group deduplication, and status-scoped ID selection now live together.

Completed proof:
- Focused dependency/exclusivity review, public integrity summary, and timeline
  diff integrity examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,765 files.
- Canonical AST equivalence: all seven moved clauses after normalizing only
  public/private heads, list/sort callbacks, and internal callback threading.
- Format, whitespace, ownership, exactly-six-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline integrity-ID grouping policy extraction, selected in `7e726f43`,
corrected in `8f39e03a`, and implemented in `fcdc3670`.

Next candidate:
Continue remapping the 6,250-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
