# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh filter/rejection replay fixture extraction.

Status:
Completed and published as `14fb3959`.

Selected slice:
Move the now-contiguous `candidate_rejection_replay` and
`contact_filter_replay` fixtures into
`Validation.ReferenceFixtures.CandidateRefreshFilterRejection`. Leave the
following link-capacity replay in the facade and merge the new family behind
unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 10,761 lines.
These two fixtures form one contiguous 160-line filter/rejection replay family
and have one dedicated focused owner in
`validation/candidate_refresh_filter_rejection_replay_fixture_test.exs`.

Current coupling/problem:
Two related generated replay fixtures remain embedded in the facade despite
shared candidate-filtering responsibility and test ownership. Neither
references a facade helper attribute, so the pair can move without coupling the
following capacity/filter family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFilterRejection`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_filter_rejection.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused filter/rejection replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two replay fixtures exist only in the filter/rejection family module, all
13 fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly the
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
- Source-boundary proof found 2 filter/rejection, 2 planning-feedback, 4
  timeline, 3 readiness, 2 contact, 2 station-allocation, 2
  freshness/budget, 2 base, 3 campaign-planning, 10 campaign-artifact, 3
  accepted-state, 6 orbital, and 154 facade keys with no duplicate anchors;
  facade `fetch/1` matched both moved values.
- Strict test compile passed with warnings as errors.
- Focused filter/rejection replay, core-policy, and facade validation tests: 14
  passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 1-2 moved,
  link capacity and the full remainder stayed exact, all 13 maps are pairwise
  disjoint, their union equals `b26a80d0`, fetch edge behavior matches, and
  compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The candidate-rejection and contact-filter replay fixtures now live in
`Validation.ReferenceFixtures.CandidateRefreshFilterRejection`; the facade
merges that family with 12 existing fixture maps plus 154 remaining fixtures.
The facade fell from 10,761 to 10,603 lines, while the extracted family is 168
lines.

Last completed slice:
Candidate-refresh filter/rejection fixture extraction published as `14fb3959`:
the two exact filtering replay fixtures moved behind the unchanged facade,
link capacity and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
Extract the now-contiguous link-capacity and resource-filter replays into one
family. The 181-line pair has no helper-attribute coupling, shares dedicated
`candidate_refresh_capacity_filter_replay_fixture_test.exs` ownership, and
stops before non-candidate-refresh reports; re-baseline before selecting.

Blocked:
No.
