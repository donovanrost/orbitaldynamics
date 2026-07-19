# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest reusable value-schema ownership extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract reusable target, ground-station, and spacecraft identity schemas plus
the three-number vector schema into
`OrbitalDynamics.Study.Manifest.ValueSchema`. Preserve the existing public
Manifest schema and loader facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,039 lines, ahead of
  ContactAllocation and TimelineFeedback and behind the three larger
  orchestration-heavy facades.
- The selected builders form one reusable embedded-value schema vocabulary
  with no runtime parsing or semantic-validation responsibility.
- Public schema/export APIs and entity schemas remain in the facade.
- This removes the last facade-private builder dependencies from the remaining
  realized-activity input-schema boundary.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation outcome-evidence extraction, selected in
`32b15d88` and implemented in `64be0fd0`.
`timeline_feedback.ex` moved from 4,070 to 3,950 lines; the dedicated owner is
215 lines.

Next candidate:
Implement and verify the selected Study.Manifest reusable value-schema
ownership extraction.

Blocked:
No.
