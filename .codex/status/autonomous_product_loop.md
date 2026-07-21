# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 CandidateRefresh source score terms.

Status:
Complete; ready to publish.

Selection evidence:
- V2 candidate-diff, refresh-freshness, and refresh-budget terms are numeric and
  total-consistent but are not recomputed from their embedded source reports.
- Coordinated edits to these terms, the total, and score-term report can remain
  internally valid while misrepresenting refresh risk or candidate loss.
- Producer formulas are deterministic, and the exact source reports plus policy
  evidence are already embedded in the repair artifact.

Intended behavior:
- Extract shared CandidateRefresh pressure counts used by producer and validator:
  one for replay-classified candidate diff, one for stale/unknown freshness, and
  one per exact nonblank budget-dropped candidate ID with producer fallbacks.
- Recompute each present penalty from that shared count and `risk_weight`.
- Preserve optional legacy terms, absent/nominal reports, zero risk weight,
  numeric-string/default policy handling, malformed-report safety, and checked
  V2 compatibility.
- Add coordinated-tamper, positive planner, nominal/optional/default/zero, and
  fallback coverage; document the executable guarantees.

Level 6 pillar advanced:
Explainable V2 refresh-source terms backed by embedded CandidateRefresh evidence.

Last published slice:
- `8f94fc4c` Reconcile V2 report pressure score terms (`3715 passed`).

Likely files:
- shared repair refresh-pressure classifier
- V2 campaign-repair score runtime contract
- focused score contract tests
- V2 capability and roadmap docs

Verification:
- Focused score/CandidateRefresh planner tests: `24 passed`.
- Campaign-repair schema fixtures: `19 passed`.
- Schema suite plus schema-lint task tests: `397 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3717 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Runtime-only reconciliation required no generated schema changes.

Review:
- Candidate-diff scoring retains the shared artifact-only replay classifier and
  remains a single penalty regardless of diff row count.
- Freshness remains one penalty only for normalized stale/unknown status; budget
  pressure preserves exact nonblank dropped-ID precedence, numeric count
  truncation, and invalid-limit-policy fallback semantics.
- Malformed candidate-diff shapes safely yield neutral derived pressure here
  while structural validators own the report error; unexpected valid-report
  exceptions are not broadly swallowed.
- Policy values retain producer-equivalent numeric-string parsing, zero weights,
  and missing-key defaults; all three terms remain optional for older V2 maps.
- Positive planner artifacts and nominal fixtures remain valid, while coordinated
  term, total, and score-report edits no longer mask any of the three mismatches.

Remaining maturity gaps:
- Continue exact V2 ranking/score reconciliation for replayable source fields.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
