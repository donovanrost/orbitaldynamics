# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh base reference-fixture family extraction.

Status:
Ready for implementation.

Selected slice:
Move the two noncontiguous candidate-refresh base fixtures—
`candidate_refresh.v1` and `resource_provenance_v1`—into
`Validation.ReferenceFixtures.CandidateRefreshBase`. Leave every replay fixture
in the facade and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 12,147 lines.
These two fixtures share `artifact.candidate_refresh.v1`, represent checked-in
base artifacts rather than generated replays, and have one dedicated focused
test owner in `validation/candidate_refresh_base_fixture_test.exs`.

Current coupling/problem:
Two checked-in base fixture values remain separated by the generated replay
range in the facade despite sharing contract and test ownership. Neither
references a facade helper attribute, so both can move without coupling the new
module to replay construction.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshBase`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_base.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused candidate-refresh-base and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two base fixtures exist only in the candidate-refresh-base family module,
all six fixture maps have disjoint key sets, `all/0` and `fetch/1` return
exactly the same 195-entry map and deterministic term bytes, focused and full
validation tests pass, and bounded review finds no blocker.

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
Campaign planning reference-fixture extraction published as `fde8c3ac`: the
three exact repair/lint/strategy fixtures moved behind the unchanged facade,
the 195-entry map and deterministic bytes stayed exact, 181 validation tests
passed, and bounded review was clean.

Next candidate:
After this boundary, select one replay family by focused test ownership; the
freshness/budget pair is a likely first candidate, but recheck helper-attribute
coupling before moving it.

Blocked:
No.
