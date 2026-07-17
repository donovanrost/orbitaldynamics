# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh readiness replay fixture extraction.

Status:
Completed and published as `aa06dad1`.

Selected slice:
Move the contiguous `resource_projection_replay`, `quality_gate_replay`, and
`operational_readiness_replay` fixtures into
`Validation.ReferenceFixtures.CandidateRefreshReadiness`. Leave the following
timeline replay family in the facade and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 11,545 lines.
These three fixtures form one contiguous 230-line readiness replay family and
have one dedicated focused owner in
`validation/candidate_refresh_readiness_replay_fixture_test.exs`.

Current coupling/problem:
Three related generated replay fixtures remain embedded in the facade despite
shared readiness-gating responsibility and test ownership. None references a
facade helper attribute, so the trio can move without coupling the following
timeline replay family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshReadiness`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_readiness.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused readiness replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three replay fixtures exist only in the readiness family module, all 10
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
- Source-boundary proof found 3 readiness, 2 contact, 2 station-allocation, 2
  freshness/budget, 2 base, 3 campaign-planning, 10 campaign-artifact, 3
  accepted-state, 6 orbital, and 162 facade keys with no duplicate anchors;
  facade `fetch/1` matched all three moved values.
- Strict test compile passed with warnings as errors.
- Focused readiness replay, core-policy, and facade validation tests: 15
  passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 2-4 moved,
  timeline precondition and the full remainder stayed exact, all 10 maps are
  pairwise disjoint, their union equals `4673af7e`, fetch edge behavior
  matches, and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The resource-projection, quality-gate, and operational-readiness replay
fixtures now live in
`Validation.ReferenceFixtures.CandidateRefreshReadiness`; the facade merges
that family with nine existing fixture maps plus 162 remaining fixtures. The
facade fell from 11,545 to 11,317 lines, while the extracted family is 238
lines.

Last completed slice:
Candidate-refresh readiness fixture extraction published as `aa06dad1`: the
three exact readiness replay fixtures moved behind the unchanged facade,
timeline precondition and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
Extract the four contiguous timeline precondition/lifecycle/transition replays
into one family. The 353-line block has no helper-attribute coupling, shares
dedicated `candidate_refresh_timeline_replay_fixture_test.exs` ownership, and
stops before objective-gap planning feedback; re-baseline before selecting.

Blocked:
No.
