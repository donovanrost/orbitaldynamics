# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 replacement-ranking schedule costs.

Status:
Complete; ready to publish.

Selection evidence:
- The V2 replacement producer derives `schedule_churn_s` from source/candidate
  starts, applies one fixed negative churn-cost weight, and multiplies churn by
  the negative schedule-move weight.
- Runtime currently requires numeric fields and reconciles their sum into
  `ranking_score`, but does not pin the timing delta or either policy formula.
- The embedded source activity context, unique source candidate, and scoring
  policy already contain enough evidence for exact replay without new fields.

Intended behavior:
- Recompute ranking-row churn seconds from source and candidate start times when
  both are present and uniquely identifiable.
- Pin the fixed churn penalty and churn-times-move penalty to the enclosing
  scoring policy with producer-equivalent numeric/default handling.
- Preserve older rows that lack replayable source timing while still checking
  their penalty formulas against embedded churn.
- Add focused timing, default/nondefault-weight, and compensating-drift coverage;
  update the V2 ranking documentation.

Level 6 pillar advanced:
Reproducible V2 branch ranking with replayable schedule-cost terms.

Last published slice:
- `0f9ba0fd` Reconcile V2 ranking link pressure (`3784 passed`).

Likely files:
- V2 replacement-ranking semantic validator wiring
- focused replacement-ranking/schedule-policy planner tests
- resource/communications capability documentation

Verification:
- Focused ranking/schedule-policy contract tests: `12 passed`.
- Related V2 repair/schema coverage: `150 passed`.
- Full checked-artifact lint: `155/155 passed`, zero warnings.
- Full suite with a 120-second per-test ceiling: `3784 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- No artifact shape or checked-in schema export changed.

Review:
- Runtime now replays `schedule_churn_s` from the exact unique embedded source
  candidate and source-activity start time when both are available.
- Every ranking row pins its fixed churn penalty and churn-times-move penalty to
  the enclosing scoring policy with producer-equivalent numeric/default logic.
- Compensating timing and cost mutations keep legacy `ranking_score` arithmetic
  valid but fail at the exact churn or penalty path.
- Older rows without source timing skip only timing replay; policy formulas
  remain enforced, preventing the compatibility fallback from becoming a
  semantic bypass.
- The nondefault move-cost planner case now uses a canonical refreshed contact
  and exercises the full schema boundary; all checked artifacts and existing V2
  repair/planner consumers remain valid.

Remaining maturity gaps:
- Reconcile V2 replacement-ranking semantic diff match/priority to embedded
  candidate-diff source evidence.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
