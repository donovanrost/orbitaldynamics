# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 replacement-ranking link-capacity penalties.

Status:
Complete; ready to publish.

Selection evidence:
- The V2 replacement producer applies exactly one negative `risk_weight` unit
  when an alternative's projected link-capacity report has selected shortfall.
- Runtime currently requires a positive shortfall when the penalty is nonzero,
  but does not reconcile the penalty magnitude with that evidence.
- A compensating penalty/ranking-score mutation can therefore remain arithmetic-
  valid while contradicting the declared one-unit link-pressure policy.

Intended behavior:
- Recompute every ranking-row link-capacity penalty from positive embedded
  shortfall evidence and the enclosing repair scoring policy.
- Require zero pressure when shortfall evidence is absent and exactly one
  negative weight unit when it is present.
- Preserve nominal rows without projected shortfall evidence.
- Add focused default/nondefault-weight and compensating-drift coverage; update
  the V2 ranking documentation.

Level 6 pillar advanced:
Reproducible V2 branch ranking with explainable link-capacity score terms.

Last published slice:
- `21b18619` Reconcile V2 ranking resource pressure (`3784 passed`).

Likely files:
- V2 replacement-ranking semantic validator wiring
- focused replacement-ranking/link-capacity planner tests
- resource/communications capability documentation

Verification:
- Focused ranking/link-capacity contract tests: `9 passed`.
- Related V2 repair/schema coverage: `150 passed`.
- Full checked-artifact lint: `155/155 passed`, zero warnings.
- Full suite with a 120-second per-test ceiling: `3784 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- No artifact shape or checked-in schema export changed.

Review:
- Runtime now applies the producer's exact row formula: zero without positive
  projected shortfall, otherwise one negative `risk_weight` unit.
- Numeric and numeric-string policy weights use the same producer-equivalent
  defaulting behavior, retaining nominal ranking compatibility.
- Default- and nondefault-weight drift cases adjust `ranking_score` to keep the
  old arithmetic valid but still fail at the exact link-pressure penalty path.
- The guard reads existing compact shortfall evidence only; it does not rerun
  link-capacity projection, enlarge the artifact, reserve provider time, or
  claim global contact optimization.
- All checked artifacts and existing V2 repair/planner consumers remain valid.

Remaining maturity gaps:
- Reconcile V2 replacement-ranking schedule churn/move costs and semantic diff
  priority to their embedded policy and source evidence.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
