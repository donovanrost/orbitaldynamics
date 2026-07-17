# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh capacity/filter replay fixture extraction.

Status:
Publishing implementation.

Selected slice:
Move the now-contiguous `link_capacity_replay` and `resource_filter_replay`
fixtures into
`Validation.ReferenceFixtures.CandidateRefreshCapacityFilter`. Stop before
`candidate_rejection_report.v1` and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 10,603 lines.
These two fixtures form the final contiguous 181-line candidate-refresh replay
family in the facade and have one dedicated focused owner in
`validation/candidate_refresh_capacity_filter_replay_fixture_test.exs`.

Current coupling/problem:
Two related generated replay fixtures remain embedded in the facade despite
shared capacity/resource-filtering responsibility and test ownership. Neither
references a facade helper attribute, so the pair can move without coupling
following non-candidate-refresh report fixtures.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshCapacityFilter`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_capacity_filter.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused capacity/filter replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two replay fixtures exist only in the capacity/filter family module, all
14 fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Exact post-split proof matched the 195-entry selection baseline,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found 2 capacity/filter, 2 filter/rejection, 2
  planning-feedback, 4 timeline, 3 readiness, 2 contact, 2
  station-allocation, 2 freshness/budget, 2 base, 3 campaign-planning, 10
  campaign-artifact, 3 accepted-state, 6 orbital, and 152 facade keys with no
  duplicate anchors; facade `fetch/1` matched both moved values.
- Strict test compile passed with warnings as errors.
- Focused capacity/filter replay, core-policy, and facade validation tests: 14
  passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 1-2 moved,
  candidate-rejection report and the full remainder stayed exact, all 14 maps
  are pairwise disjoint, their union equals `8529a83b`, fetch edge behavior
  matches, and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The link-capacity and resource-filter replay fixtures now live in
`Validation.ReferenceFixtures.CandidateRefreshCapacityFilter`; the facade
merges that family with 13 existing fixture maps plus 152 remaining fixtures.
The facade fell from 10,603 to 10,424 lines, while the extracted family is 189
lines.

Last completed slice:
Candidate-refresh filter/rejection fixture extraction published as `14fb3959`:
the two exact filtering replay fixtures moved behind the unchanged facade,
link capacity and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, remap the remaining capability/report fixture families
and choose the next extraction by focused test ownership rather than adjacency.

Blocked:
No.
