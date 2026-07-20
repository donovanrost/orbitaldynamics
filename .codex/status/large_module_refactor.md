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
Extracted schema-facing timeline capability/model-limit access into
`OrbitalDynamics.Schema.TimelineCapabilityContext` and import its focused
internal APIs into the Schema facade.
Preserved all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,525 lines.
- Nine private helpers repeatedly normalize Timeline/TimelineFeedback
  capabilities into model limits, rejection reasons/actions, transition
  decisions, integrity issue types, precondition statuses, and required
  operator actions.
- The selected code has one responsibility: expose schema-facing timeline
  capability context with stable string/atom/list ordering.
- Importing those internal APIs preserves the existing unqualified call sites
  and evaluation order. Property-dispatch composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact model-limit conversion, capability values and ordering, validation
  results, generated JSON Schema, and checked-in exports must remain unchanged.

Implementation:
- Added the focused `TimelineCapabilityContext` owner for Timeline and
  TimelineFeedback model limits, capability data, rejection reasons/actions,
  transition decisions, integrity issue types, precondition statuses, and
  required operator actions.
- Imported those internal APIs into `Schema`, preserving all existing
  unqualified property-dispatch and validation call sites.
- Removed nine private capability/model-limit helpers from the facade.
- `schema.ex` moved from 6,525 to 6,498 lines; the owner is 34 lines.

Verification:
- Pre-change strict focused baseline: 51 JSON-export/timeline contract tests
  passed.
- Post-change strict focused verification: the same 51 tests passed; the full
  schema-export task test and broader validation checks also passed.
- Static checks found no migrated timeline capability helpers remaining; xref
  reports `schema.ex` as an exported/imported caller of
  `TimelineCapabilityContext`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,051 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema timeline capability-context extraction, selected in `cefcd8d6` and
implemented in `dd182ce7`.
`schema.ex` moved from 6,525 to 6,498 lines; the dedicated
TimelineCapabilityContext owner is 34 lines.

Next candidate:
Re-rank the remaining schema capability/model-limit responsibility clusters.

Blocked:
No.
