# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh freshness/budget replay fixture extraction.

Status:
Completed and published as `df1f8ef6`.

Selected slice:
Move the contiguous `freshness_replay` and `refresh_budget_replay` fixtures into
`Validation.ReferenceFixtures.CandidateRefreshFreshnessBudget`. Leave the
preceding candidate-rejection and following station-calendar replays in the
facade and merge the new family behind unchanged `ReferenceFixtures.all/0` and
`fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 12,063 lines.
These two fixtures form one contiguous 133-line replay family and have one
dedicated focused owner in
`validation/candidate_refresh_freshness_budget_replay_fixture_test.exs`.

Current coupling/problem:
Two related generated replay fixtures remain embedded in the facade despite
shared freshness-policy responsibility and test ownership. Neither references
a facade helper attribute, so the pair can move without coupling adjacent
replay families.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFreshnessBudget`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_freshness_budget.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused freshness/budget replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two replay fixtures exist only in the freshness/budget family module, all
seven fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly
the same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Exact post-split proof matched the 195-entry selection baseline,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found 2 freshness/budget, 2 base, 3
  campaign-planning, 10 campaign-artifact, 3 accepted-state, 6 orbital, and
  169 facade keys with no duplicate anchors; facade `fetch/1` matched both
  moved values.
- Strict test compile passed with warnings as errors.
- Focused freshness/budget replay, core-policy, and facade validation tests: 14
  passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 2-3 moved, both
  neighboring replay fixtures and the remainder stayed exact, all seven maps
  are pairwise disjoint, their union equals `d7984f9d`, fetch edge behavior
  matches, and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The freshness and refresh-budget replay fixtures now live in
`Validation.ReferenceFixtures.CandidateRefreshFreshnessBudget`; the facade
merges that family with six existing fixture maps plus 169 remaining fixtures.
The facade fell from 12,063 to 11,932 lines, while the extracted family is 141
lines.

Last completed slice:
Candidate-refresh freshness/budget fixture extraction published as `df1f8ef6`:
the two exact replay fixtures moved behind the unchanged facade, their
neighbors and remainder stayed exact, the 195-entry map and deterministic
bytes stayed exact, 181 validation tests passed, and bounded review was clean.

Next candidate:
Extract the contiguous station-calendar and contact-allocation contradiction
replays into one family. The 205-line pair has no helper-attribute coupling,
shares dedicated
`candidate_refresh_station_allocation_replay_fixture_test.exs` ownership, and
stops before contact-contention; re-baseline before selecting.

Blocked:
No.
