# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh empty refresh-budget ID normalization repair.

Status:
Selected; implementation pending.

Selected boundary:
Normalize only empty-map `kept_candidate_ids` and `dropped_candidate_ids` values
back to empty lists at the refresh-budget replay-summary boundary. Preserve
non-empty values, counts, public replay APIs, and all artifact contracts.

Selection evidence:
- Keyword-map encoding represents an empty list as `%{}` inside the branch
  candidate-source summary.
- Refresh-budget replay currently copies those maps and tests `!= []`, causing
  false dropped-candidate, candidate-limit, and budget pressure.
- Empty candidate-ID collections are contractually arrays; normalizing only the
  empty-map representation restores the original deterministic output.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner prior result-artifact filter routing repair, selected in
`1d202538` and implemented in `340d966a`. Correct argument ordering restored
three missing-branch tests.

Next candidate:
Implement and verify the refresh-budget normalization, then resolve the final
readiness score-term failure.

Blocked:
No.
