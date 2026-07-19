# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention feedback-context extraction.

Status:
Completed and pushed in `760a7ba0`.

Selected boundary:
Extract contact/command feedback aggregation, provider-result artifact
normalization, actual-throughput selection, and actual-data-rate throughput
derivation into
`OrbitalDynamics.Communications.ContactContention.FeedbackContext`. Preserve
the public ContactContention facade and private delegates used by contention
group/recommendation construction, approval-policy context copying, and
provider-contact evidence detection.

Selection evidence:
- Live re-ranking placed `contact_contention.ex` at 2,805 lines, fifth behind
  Schema, Timeline, MissionPlan.Activity, and the intentionally public
  `OrbitalDynamics` facade, and ahead of LinkCapacity, StationCalendar,
  OperationalReadiness, RecommendationRiskContext, TimelineFeedback, and
  ResourceProjection.
- The extracted family owned boolean/factor/string feedback aggregation,
  metadata fallback, nested provider-result flattening, explicit throughput
  aliases, data-rate unit conversion, duration fallback, and derivation
  evidence.
- Four contention group/recommendation builders consume the feedback context;
  two approval-policy paths consume its field allowlist; provider contact
  evidence consumes actual throughput. Three narrow private delegates preserve
  those facade callers.
- Station-calendar context/capacity semantics, contention grouping, approval
  requirements, resolution-policy normalization and ordering, contact
  identity, public report clauses, and artifact contracts remain outside this
  boundary.

Verification:
- Strict warning-clean compile passed across 3,953 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused ContactContention regression passed 40 tests; the adjacent
  ContactAllocation, campaign-planner contention, operator-review contention
  and resolution, and validation-fixture bundle passed 83 tests. The final
  consolidated run passed all 123 tests.
- Exact old/new parity passed 10 comparisons from selection commit `1eb8bb50`
  with `/tmp/contact_contention_feedback_context_compare.exs`, covering rich
  nested feedback, metadata fallback, explicit-throughput precedence, MB/s and
  Mbps derivation, negative-rate clamping, atom-key normalization, empty and
  deterministic reports, resolution reports/summaries, and public errors.
- `mix xref callers
  OrbitalDynamics.Communications.ContactContention.FeedbackContext` reports
  only the ContactContention facade.
- Compile-connected xref scope for the new owner does not expand beyond the
  owner itself.
- Focused formatting, `git diff --check`, removed-family static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public ContactContention facade, feedback aggregation, provider
result traversal, throughput precedence and conversion, contact identity,
deterministic output, artifact contracts, and exact errors are unchanged.

Last completed slice:
ContactContention feedback-context extraction, selected in `1eb8bb50` and
implemented in `760a7ba0`.
`contact_contention.ex` moved from 2,805 to 2,509 lines; the dedicated
feedback-context owner is 327 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
