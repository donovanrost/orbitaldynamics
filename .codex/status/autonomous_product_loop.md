# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 replacement-ranking semantic diff priority.

Status:
Complete; ready to publish.

Selection evidence:
- The V2 replacement producer marks a semantic match only when the embedded
  candidate-diff report links the row candidate to the repair source ID or
  source-window identity.
- Runtime currently pins priority to the row boolean but does not recompute that
  boolean from the source report, so both fields can drift together.
- The repair source ID/context, candidate ID, and optional source diff report
  already contain the exact producer predicate without requiring new fields.

Intended behavior:
- Recompute every ranking-row semantic-match boolean from embedded candidate-
  diff replacement rows using the exact source ID/window and candidate ID rule.
- Let the existing priority contract continue deriving zero/one priority from
  the now source-reconciled boolean.
- Preserve repairs with no source diff report by requiring every row to remain
  a nonmatch.
- Add positive, negative, missing-source, and drift coverage; update the V2
  ranking documentation.

Level 6 pillar advanced:
Reproducible V2 branch ranking with source-replayable semantic priority.

Last published slice:
- `6b6a7b91` Reconcile V2 ranking schedule costs (`3784 passed`).

Likely files:
- V2 replacement-ranking semantic validator wiring
- focused replacement-ranking/candidate-diff planner tests
- resource/communications capability documentation

Verification:
- Focused ranking/candidate-diff contract tests: `5 passed`.
- Related V2 repair/schema coverage: `150 passed`.
- Full checked-artifact lint: `155/155 passed`, zero warnings.
- Full suite with a 120-second per-test ceiling: `3784 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- No artifact shape or checked-in schema export changed.

Review:
- Runtime now applies the producer's exact semantic-match predicate over source
  activity ID, optional source-window identity, and replacement candidate ID.
- A real planner artifact validates both the linked match and unrelated
  nonmatch; deleting its source diff report now rejects the stale match at the
  exact ranking-row path.
- The existing priority check derives zero/one priority from the source-
  reconciled boolean, closing the prior paired-field mutation gap.
- Repairs without a source diff report remain compatible only with nonmatch
  rows, matching producer behavior.
- Malformed diff rows are ignored by this replay layer and remain errors for the
  standalone source-report validator rather than crashing artifact validation;
  all checked artifacts and existing V2 consumers remain valid.

Remaining maturity gaps:
- Reassess the remaining V2 replacement-ranking envelope for selected-candidate
  handoff identity and candidate-specific replay gaps.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
