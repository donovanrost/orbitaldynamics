# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-precondition context extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move `activity_precondition_row_summary/1` and the complete private
precondition engine into `Timeline.ActivityPreconditionContext.build/2`:
availability/degraded/resource blocks, depleted margins, incompatible and
suppressed activity types, command authority/safety, activity-template
required states, row construction, status precedence, counts, and sorted type
sets. `Timeline` retains every public function, shared normalization helpers,
and the shared unit-interval alias table, supplying them through callbacks and
selection data.

Why this slice:
After four context extractions, Timeline remains a 9,223-line facade. This
approximately 305-line region owns one cohesive artifact concern and has two
facade callers plus focused operational/precondition coverage. The
unit-interval alias table remains in Timeline because capabilities and input
validation also consume it; the extraction therefore avoids taking mixed
schema/validation ownership.

Planned proof:
- Focused Timeline tests covering authority/safety, availability/resource/
  margin blocks, activity-type membership, template-required states, summary
  precedence/counts/sorting, and numeric-string normalization.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the exact summary and every moved clause after
  normalizing only callback/data boundaries.
- Format, diff, whitespace, ownership, caller, public-definition, and xref
  checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline command-window context extraction, implementation published in
`4658c14f` and handoff published in `adfc3a44`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity and diff construction.

Blocked:
No.
