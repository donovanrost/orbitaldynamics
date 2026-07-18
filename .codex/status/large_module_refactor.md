# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline integrity annotation extraction.

Status:
Implementation in progress; initial compile exposed one shared helper boundary
that is being corrected before verification.

Selected boundary:
Move `annotate_timeline_integrity_rows/2` and the complete integrity engine
through `issue_value/2` into `Timeline.IntegrityAnnotation.annotate/3`:
activity/timeline dependency validation, missing/self/duplicate/cycle/order
issues, explicit and group exclusivity overlaps, issue aggregation, operator
routing/supersession, and deterministic ID/type evidence. `Timeline` retains
all public functions and supplies shared issue construction, list lookup, and
map compaction callbacks. Duplicate timeline-identity annotation remains in
the facade as a separate responsibility.

Why this slice:
The reduced Timeline facade is 8,930 lines. This approximately 378-line region
has one cohesive responsibility, six facade callers, no module-attribute
dependencies, three shared helper dependencies, and dense focused coverage.
Keeping duplicate timeline identity separate makes the boundary match
dependency/exclusivity integrity rather than unrelated collision routing.

Boundary correction:
The initial strict compile exposed that `issue/2` is also used by invalid-input
normalization outside the selected block. It therefore remains in Timeline
and is injected into the integrity module alongside list lookup and
compaction.

Planned proof:
- Focused Timeline tests covering missing, self, duplicate, cyclic, and
  order-violating dependencies; explicit/group exclusivity; timeline-ID
  evidence; and normalized selected-activity annotations.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for every moved clause after normalizing only the
  three callback boundaries.
- Format, diff, whitespace, ownership, six-caller, public-definition, and xref
  checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-precondition context extraction, implementation published in
`91250c45` and handoff published in `f6fae270`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing diff-row and
transition-application construction.

Blocked:
No.
