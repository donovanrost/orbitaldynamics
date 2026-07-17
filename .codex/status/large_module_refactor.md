# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh contact replay fixture extraction.

Status:
Completed and published as `d468ac6f`.

Selected slice:
Move the contiguous `contact_contention_cross_station_replay` and
`contact_intent_direction_replay` fixtures into
`Validation.ReferenceFixtures.CandidateRefreshContact`. Leave the following
resource-projection replay in the facade and merge the new family behind
unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 11,729 lines.
These two fixtures form one contiguous 186-line contact replay family and have
one dedicated focused owner in
`validation/candidate_refresh_contact_replay_fixture_test.exs`.

Current coupling/problem:
Two related generated replay fixtures remain embedded in the facade despite
shared contact contention/intent responsibility and test ownership. Neither
references a facade helper attribute, so the pair can move without coupling
the following readiness replay family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshContact`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_contact.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused contact replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two replay fixtures exist only in the contact family module, all nine
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
- Source-boundary proof found 2 contact, 2 station-allocation, 2
  freshness/budget, 2 base, 3 campaign-planning, 10 campaign-artifact, 3
  accepted-state, 6 orbital, and 165 facade keys with no duplicate anchors;
  facade `fetch/1` matched both moved values.
- Strict test compile passed with warnings as errors.
- Focused contact replay, core-policy, and facade validation tests: 14 passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 2-3 moved,
  resource projection and the full remainder stayed exact, all nine maps are
  pairwise disjoint, their union equals `de719d27`, fetch edge behavior
  matches, and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The cross-station contact-contention and contact-intent direction replay
fixtures now live in
`Validation.ReferenceFixtures.CandidateRefreshContact`; the facade merges that
family with eight existing fixture maps plus 165 remaining fixtures. The
facade fell from 11,729 to 11,545 lines, while the extracted family is 194
lines.

Last completed slice:
Candidate-refresh contact fixture extraction published as `d468ac6f`: the two
exact contention/intent replay fixtures moved behind the unchanged facade,
resource projection and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
Extract the contiguous resource-projection, quality-gate, and operational-
readiness replays into one family. The 230-line trio has no helper-attribute
coupling, shares dedicated
`candidate_refresh_readiness_replay_fixture_test.exs` ownership, and stops
before timeline replays; re-baseline before selecting.

Blocked:
No.
