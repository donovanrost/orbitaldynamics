# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
No slice selected.

Status:
Slice complete and pushed.

Selected boundary:
Completed the existing `OrbitalDynamics.Schema.TimelineContextValidation`
extraction by routing callback tables directly to that owner and removing
nine facade pass-through clauses.
Preserved all `OrbitalDynamics.Schema` public facades and validation/error
behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,640 lines.
- Timeline-context validation logic already has a focused owner, but the facade
  retains one-hop wrappers referenced by operational timeline, transition,
  campaign, Cadence import, source-review, and operator-review callbacks.
- The selected code has one responsibility: route optional precondition,
  activity, protection, lifecycle, identity, link, and protection-summary
  context validation to the existing owner.
- Preserve the facade wrappers' map-only function-clause behavior by moving
  those guards to the owner before exposing it directly to callback tables.
- Callback-table composition, timeline transition/source validation, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, required-field behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
- Moved the facade wrappers' map guards onto the seven corresponding optional
  owner functions so malformed-input function-clause behavior remains stable.
- Routed operational-timeline, transition, campaign, Cadence import,
  source-review, and operator-review callback tables directly to
  `TimelineContextValidation`.
- Removed nine one-hop private wrapper clauses, including the two-clause
  timeline-identity adapter.
- `schema.ex` moved from 6,640 to 6,622 lines; the focused owner remains compact
  at 76 lines.

Verification:
- Pre-change strict focused baseline: 43 timeline/Cadence/operator-review
  contract tests passed.
- Post-change strict focused verification: the same 43 tests passed; 7 broader
  validation and campaign-fixture tests also passed.
- Static checks found no migrated timeline-context wrappers or local callback
  captures remaining; xref reports `schema.ex` as the runtime caller of
  `TimelineContextValidation`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,050 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema timeline-context validation routing cleanup, selected in `88bd2853` and
implemented in `d9d05131`.
`schema.ex` moved from 6,640 to 6,622 lines by completing routing to the
existing TimelineContextValidation owner.

Next candidate:
Re-rank the remaining schema wrapper clusters. Keep the timeline-transition
adapters because they inject callback dependencies; source-evidence routing is
a smaller pure pass-through candidate.

Blocked:
No.
