# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Correlate contention resource-scope counts.

Status:
Verified; ready for mechanical publish.

Selection evidence:
- Raw contention producers assign conflict groups only to `ground_station` or
  `spacecraft` resource scope.
- Preserved compact summaries currently replay arbitrary resource-scope keys
  and counts independently of the conflict-group scalar.
- Unknown, zero-evidence, or over-counted scopes can therefore create branch
  pressure after raw conflict rows have been removed.

Intended behavior:
- Retain only canonical positive `ground_station` and `spacecraft` scope counts
  whose combined total does not exceed the conflict-group scalar.
- Apply correlation per report and again at flattened-source/replay boundaries.
- Keep the conflict-group scalar as pressure while preventing uncorrelated scope
  keys from independently creating branch pressure.

Level 6 pillar advanced:
Fleet-scale planning decisions and durable reproducible audit handoffs.

Planned files:
- contention resource-scope aggregation, flattened source fields, replay, and
  compact-summary schema correlation
- unknown-scope and over-counted-scope challenge tests
- contention artifact documentation and autonomous-loop ledger

Verification:
- Contact-contention replay and candidate-source focus -> `15 passed`.
- CandidateRefresh compact-summary schema focus -> `4 passed`.
- `mix test test/orbital_dynamics/**/*contact_contention*.exs --timeout 120000`
  -> `103 passed`.
- `mix orbital_dynamics.schema.lint --all` -> `155 passed`, no warnings.
- `mix format --check-formatted` and `git diff --check` passed.
- `mix test --timeout 120000` -> `3806 passed`.

Review:
- Canonical scopes are filtered per raw report before aggregation and again at
  compact flattened/replay boundaries; conflict scalar pressure is unchanged.
- Combined canonical counts are bounded by the conflict-group scalar, allowing
  partial scope evidence while rejecting ambiguous over-counted maps.
- A branch-selection fixture was made internally correlated without changing
  its branch-over-provenance purpose; schema/runtime agree on unknown,
  non-positive, zero-evidence, and over-counted scope handling. No unresolved
  findings.

Last published slice:
- `af5bcf50` Correlate contention review actions (`3806 passed`).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Add planner effects only for allocation/resource evidence with selected
  candidate identity; keep aggregate station-pressure maps provenance-only.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After publish, audit contention ground-station count totals and station identity
authority for preserved compact summaries.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, implementation, review, and mechanical publish checks.
