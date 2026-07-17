# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh planning-feedback replay fixture extraction.

Status:
Publishing implementation.

Selected slice:
Move the contiguous `objective_gap_replay` and `constraint_replay` fixtures
into `Validation.ReferenceFixtures.CandidateRefreshPlanningFeedback`. Leave
the following contact-filter rejection replay in the facade and merge the new
family behind unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 10,966 lines.
These two fixtures form one contiguous 207-line planning-feedback replay family
and have one dedicated focused owner in
`validation/candidate_refresh_planning_feedback_replay_fixture_test.exs`.

Current coupling/problem:
Two related generated replay fixtures remain embedded in the facade despite
shared planning-feedback responsibility and test ownership. Neither references
a facade helper attribute, so the pair can move without coupling the following
filter/rejection family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshPlanningFeedback`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_planning_feedback.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused planning-feedback replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two replay fixtures exist only in the planning-feedback family module, all
12 fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly the
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
- Source-boundary proof found 2 planning-feedback, 4 timeline, 3 readiness, 2
  contact, 2 station-allocation, 2 freshness/budget, 2 base, 3
  campaign-planning, 10 campaign-artifact, 3 accepted-state, 6 orbital, and
  156 facade keys with no duplicate anchors; facade `fetch/1` matched both
  moved values.
- Strict test compile passed with warnings as errors.
- Focused planning-feedback replay, core-policy, and facade validation tests:
  14 passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 2-3 moved,
  contact filter and the full remainder stayed exact, all 12 maps are pairwise
  disjoint, their union equals `ab1fd4bc`, fetch edge behavior matches, and
  compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The objective-gap and constraint planning-feedback replay fixtures now live in
`Validation.ReferenceFixtures.CandidateRefreshPlanningFeedback`; the facade
merges that family with 11 existing fixture maps plus 156 remaining fixtures.
The facade fell from 10,966 to 10,761 lines, while the extracted family is 215
lines.

Last completed slice:
Candidate-refresh timeline fixture extraction published as `716171c2`: the
four exact timeline replay fixtures moved behind the unchanged facade,
objective gap and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, map candidate-rejection plus contact-filter against
`candidate_refresh_filter_rejection_replay_fixture_test.exs`; they are
noncontiguous, so verify the entire intervening facade remains exact.

Blocked:
No.
