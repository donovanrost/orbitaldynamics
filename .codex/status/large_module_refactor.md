# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest activity-schema extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the activity input JSON Schema assembly, including activity-specific
identity fragments and contact-direction schema metadata, into
`OrbitalDynamics.Study.Manifest.ActivitySchema`. Preserve the private
`activity_schema/0` seam in the Manifest facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,260 lines, just behind the
  remaining TimelineFeedback facade.
- The selected 513-699 function is a self-contained activity contract assembly
  whose activity types, statuses, approvals, directions, and provider aliases
  derive from `MissionPlan.Activity.capabilities/0`.
- Manifest loading, typed field reading, activity construction, all other
  schema families, and public JSON Schema APIs remain in the facade.
- Existing public manifest schema output and loader behavior remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation observation-evidence extraction, selected in
`df6f88b8` and implemented in `180de1a0`. `timeline_feedback.ex` moved from
4,376 to 4,293 lines; the dedicated owner is 117 lines.

Next candidate:
Implement and verify the selected Study.Manifest activity-schema extraction.

Blocked:
No.
