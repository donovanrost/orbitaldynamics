# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline protection-summary policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move filtered protection-decision IDs, protection-category activity-ID sets,
deterministic ID sorting, and preservation status precedence into
`Timeline.ProtectionSummaryPolicy`. `Timeline` retains four private entry
points; sorted uniqueness crosses the boundary explicitly.

Why this slice:
The 6,263-line Timeline facade still owns six exclusive summary clauses shared
by protection decisions and lifecycle preservation reports. Moving them
together isolates decision/category filtering, nil exclusion, grouped ID-set
ordering, and review-over-preserve-over-clear precedence without extracting
protection or preservation coordinators.

Planned proof:
- Focused lifecycle preservation summary/status and protection-decision
  classification examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all six moved clauses after normalizing only
  public/private heads, sorted-unique callbacks, and internal grouped-ID
  callback threading.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline identity-grouping policy extraction, selected in `e1ff48a7`,
implemented in `ffbcd5f0`, and handed off in `af9e5dd6`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
