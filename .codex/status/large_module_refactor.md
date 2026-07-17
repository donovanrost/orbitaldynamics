# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline replay fixture extraction.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Candidate-refresh readiness fixture extraction published as `aa06dad1`: the
three exact readiness replay fixtures moved behind the unchanged facade,
timeline precondition and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, map the objective-gap/constraint planning-feedback pair
against `candidate_refresh_planning_feedback_replay_fixture_test.exs` and
verify helper-attribute coupling before selecting.

Blocked:
No.
