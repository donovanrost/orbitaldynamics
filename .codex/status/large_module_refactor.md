# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity identity policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move durable/derived timeline identity, subject selection, and source-window ID
and type selection into `Timeline.ActivityIdentityPolicy`. `Timeline` retains
four private entry points; derived identity becomes internal to the policy.
Activity start selection and artifact-value encoding cross the boundary
explicitly.

Why this slice:
The reduced Timeline facade is 6,599 lines. These five exclusive clauses own
the precedence for explicit timeline/persistent IDs, deterministic derived
timeline IDs, subject identity, and nested top-level/metadata source-window
identity used across row, context, transition, lifecycle-summary, and
publication surfaces.

Planned proof:
- Focused persistent/derived identity, subject precedence, provider station,
  nested source-window, and metadata source-window examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all five moved clauses after normalizing only
  the four facade names and two callback boundaries.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-metric calculation policy extraction, selected in `26915dd1`,
implemented in `7df37151`, and handed off in `b2dbc7eb`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding boundaries whose
guard vocabularies remain shared with Timeline.

Blocked:
No.
