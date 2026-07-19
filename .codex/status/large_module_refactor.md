# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention priority-override normalization extraction.

Status:
Completed and pushed.

Selected boundary:
Extract resolution priority-override alias routing, stable contact-ID and
numeric-priority normalization, ignored-input diagnostics, counts, and sorted
contact-ID projection into
`OrbitalDynamics.Communications.ContactContention.PriorityOverrides`. Preserve
all public ContactContention report, resolution, and summary facades.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 2,466
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 1,892-1,997 and exclusively owns
  priority-override normalization and derived policy context.
- Resolution-policy construction is the only consumer of the normalized
  override values and diagnostics.
- Selection-rule validation, tie breaking, contact scoring, recommendation
  construction, contention grouping, approval policy, public clauses, and
  artifact contracts remain outside this boundary.
- Existing alias precedence, atom/string key handling, stable-ID rejection,
  numeric-string coercion, duplicate normalized-ID overwrite behavior,
  ignored-key rendering, ignored-input counting, nil omission, and
  deterministic sorting must remain unchanged.

Implementation:
- Selection was recorded and pushed in `fab92d36`.
- Implementation was committed and pushed in `b46b3b30`.
- `communications/contact_contention.ex` moved from 2,466 to 2,370 lines.
- `OrbitalDynamics.Communications.ContactContention.PriorityOverrides` is a
  134-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,967 files.
- The focused ContactContention file and five adjacent campaign, strategy,
  Cadence-import, operator-review, and manifest consumers passed together:
  178 tests.
- Exact old/new public parity passed for 13 cases covering every override
  alias, atom/string/integer IDs, numeric strings, malformed values and
  containers, keyword and invalid policy input, and capability metadata.
- `mix xref callers` reports only the ContactContention facade.
- The removed override normalization helpers and facade-owned alias attribute
  are absent apart from thin delegates, formatting and `git diff --check`
  passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention priority-override normalization extraction, selected in
`fab92d36` and implemented in `b46b3b30`.
`communications/contact_contention.ex` moved from 2,466 to 2,370 lines; the
dedicated priority-overrides owner is 134 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
