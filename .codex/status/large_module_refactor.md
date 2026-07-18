# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-reference ID policy extraction.

Status:
Implementation published in `b3bb5c3f`; focused and broad proof is green.

Selected boundary:
Move scalar/map reference flattening, normalized stable-ID lists, duplicate-ID
lists, and scalar stable-ID filtering into
`Timeline.ActivityReferenceIdPolicy`. `Timeline` retains the four private
normalize/duplicate entry points for general and map-only references plus the
private scalar stable-ID entry point used by publication and station-calendar
context. The stable-activity-ID predicate crosses the boundary explicitly.

Why this slice:
The extraction moved 24 clauses into a 127-line internal module and reduced
Timeline from 6,759 to 6,674 lines. Five private entry points preserve
dependency, exclusivity, objective, publication, and station-calendar callers
while moving input-shape filtering, stable-ID validation, normalization, and
duplicate detection out of the facade.

Completed proof:
- Focused dependency/exclusivity examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,742 files.
- Canonical AST equivalence: all 24 moved clauses after normalizing only the
  five facade names and stable-ID predicate callback.
- Format, whitespace, ownership, exactly-five-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-reference ID policy extraction, selected in `ff1f4dd0`,
corrected in `368a318e`, and implemented in `b3bb5c3f`.

Next candidate:
Remap the reduced 6,674-line Timeline facade, emphasizing remaining activity
normalization and lifecycle state assembly.

Blocked:
No.
