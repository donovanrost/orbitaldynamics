# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention resolution-summary values extraction.

Status:
Completed and pushed.

Selected boundary:
Extract resolution-summary selected/deferred/review ID projection, grouped
value/list routing, grouped review-contact routing, field counts, stable
nil-removing deduplication, sorting, and empty-group omission into
`OrbitalDynamics.Communications.ContactContention.ResolutionSummaryValues`.
Preserve all public ContactContention report and summary facades.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 2,509
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 711-778 and exclusively owns
  deterministic recommendation value/list/count projection for resolution
  summaries.
- Resolution-summary construction consumes seven helpers; capacity-demand
  source routing consumes the stable compact-list primitive once.
- Capacity-demand arithmetic, contention grouping, recommendation selection,
  resolution policy, approval requirements, provider/station evidence, public
  clauses, and artifact contracts remain outside this boundary.
- Existing selected/deferred/duplicate inclusion, nil/group omission,
  flattening, deduplication, lexicographic sorting, frequency counts, exact
  routing keys, and deterministic output must remain unchanged.

Implementation:
- Selection was recorded and pushed in `4541dbd9`.
- Implementation was committed and pushed in `12e731f7`.
- `communications/contact_contention.ex` moved from 2,509 to 2,466 lines.
- `OrbitalDynamics.Communications.ContactContention.ResolutionSummaryValues`
  is a 71-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,963 files.
- The focused ContactContention file and five adjacent resolution
  review/strategy/replay/schema consumers passed together: 55 tests.
- Exact old/new public parity passed for 6 summaries covering empty,
  selected/deferred, duplicate/ambiguous, review, grouped
  resource/action/reason, nil-group, duplicate-value, atom-key, ordering, and
  public-error cases.
- `mix xref callers` reports only the ContactContention facade; the
  compile-connected graph reports the new owner and facade.
- The removed projection helpers are absent from the facade apart from thin
  delegates, formatting and `git diff --check` passed, and the final diff is
  ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention resolution-summary values extraction, selected in
`4541dbd9` and implemented in `12e731f7`.
`communications/contact_contention.ex` moved from 2,509 to 2,466 lines; the
dedicated resolution-summary values owner is 71 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
