# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline replay fixture extraction.

Status:
Completed and published as `716171c2`.

Selected slice:
Move the contiguous timeline activity-precondition, lifecycle-state,
activity-lifecycle, and transition-application replay fixtures into
`Validation.ReferenceFixtures.CandidateRefreshTimeline`. Leave the following
objective-gap planning-feedback replay in the facade and merge the new family
behind unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 11,317 lines.
These four fixtures form one contiguous 353-line timeline replay family and
have one dedicated focused owner in
`validation/candidate_refresh_timeline_replay_fixture_test.exs`.

Current coupling/problem:
Four related generated replay fixtures remain embedded in the facade despite
shared timeline lifecycle responsibility and test ownership. None references a
facade helper attribute, so the block can move without coupling the following
planning-feedback family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshTimeline`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_timeline.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused timeline replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four replay fixtures exist only in the timeline family module, all 11
fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly the
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
- Source-boundary proof found 4 timeline, 3 readiness, 2 contact, 2
  station-allocation, 2 freshness/budget, 2 base, 3 campaign-planning, 10
  campaign-artifact, 3 accepted-state, 6 orbital, and 158 facade keys with no
  duplicate anchors; facade `fetch/1` matched all four moved values.
- Strict test compile passed with warnings as errors.
- Focused timeline replay, core-policy, and facade validation tests: 16
  passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 2-5 moved,
  objective gap and the full remainder stayed exact, all 11 maps are pairwise
  disjoint, their union equals `8bac1dfc`, fetch edge behavior matches, and
  compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The four timeline precondition/lifecycle/transition replay fixtures now live in
`Validation.ReferenceFixtures.CandidateRefreshTimeline`; the facade merges
that family with 10 existing fixture maps plus 158 remaining fixtures. The
facade fell from 11,317 to 10,966 lines, while the extracted family is 361
lines.

Last completed slice:
Candidate-refresh timeline fixture extraction published as `716171c2`: the
four exact timeline replay fixtures moved behind the unchanged facade,
objective gap and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
Extract the contiguous objective-gap and constraint planning-feedback replays
into one family. The 207-line pair has no helper-attribute coupling, shares
dedicated `candidate_refresh_planning_feedback_replay_fixture_test.exs`
ownership, and stops before contact-filter rejection; re-baseline before
selecting.

Blocked:
No.
