# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention priority-override normalization extraction.

Status:
Selected; implementation pending.

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
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback resource override projection extraction, selected in
`f4bb05b5` and implemented in `42cfbee0`.
`timeline_feedback.ex` moved from 2,472 to 2,267 lines; the dedicated resource
feedback owner is 232 lines.

Next candidate:
Complete and verify the selected ContactContention priority-override
normalization extraction.

Blocked:
No.
