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
Completed the existing `OrbitalDynamics.Schema.TimelineSourceValidation`
extraction by routing callback tables directly to that owner and removing
eight facade pass-through wrappers.
Preserved all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,694 lines.
- Timeline-source validation logic already has a focused owner, but the facade
  retains eight one-hop wrappers referenced by campaign, Cadence import,
  source-review, and operator-review callback tables.
- The selected code has one responsibility: route optional timeline diff,
  dependency, precondition, integrity, preservation, lifecycle, and activity
  source validation to the existing owner.
- Callback-table composition, timeline transition/context validation, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, required-field behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
- Routed campaign-plan, Cadence source-review/import handoff, and
  operator-review callback tables directly to `TimelineSourceValidation`.
- Removed eight one-hop private wrappers for timeline diff, dependency,
  precondition, integrity, preservation, lifecycle, and activity-state source
  validation.
- `schema.ex` moved from 6,694 to 6,640 lines; no new abstraction was added
  because the focused owner already existed.

Verification:
- Pre-change strict focused baseline: 43 timeline/Cadence/operator-review
  contract tests passed.
- Post-change strict focused verification: the same 43 tests passed; 7 broader
  validation and campaign-fixture tests also passed.
- Static checks found no migrated timeline-source wrappers remaining; xref
  reports `schema.ex` as the runtime caller of `TimelineSourceValidation`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,050 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema timeline-source validation routing cleanup, selected in `812776d1` and
implemented in `a60fc5ee`.
`schema.ex` moved from 6,694 to 6,640 lines by completing routing to the
existing TimelineSourceValidation owner.

Next candidate:
Continue with the separate timeline-transition validation routing wrapper
cluster in `schema.ex`.

Blocked:
No.
