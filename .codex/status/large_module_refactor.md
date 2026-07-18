# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-event policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move lifecycle-event replacement derivation, review-transition precedence, and
provenance field/transition selection into `Timeline.LifecycleEventPolicy`.
`Timeline` retains the four existing private entry points. Lifecycle-event
normalization, preserved-status handling, and operator-review classification
remain Timeline-owned callbacks.

Why this slice:
The reduced Timeline facade is 7,332 lines. These four exclusive clauses form
the policy used only by `apply_lifecycle_event/3`: event-to-replacement mapping,
status-before-approval review precedence, and deterministic provenance
selection. The boundary leaves the public helper orchestration and all shared
normalization/state semantics in Timeline.

Planned proof:
- Focused lifecycle helper examples covering safe application, unsafe status
  and approval transitions, preserved terminal status, aliases, and provenance.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all four moved clauses after normalizing only
  the four facade names and callback boundaries.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-application integrity orchestration extraction, selected in
`4faa56ed`, implemented in `67195816`, and handed off in `62d96609`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.
