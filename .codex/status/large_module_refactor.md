# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Environment capability reference-fixture extraction.

Status:
Ready for implementation.

Selected slice:
Move the six contiguous environment model/provider capability fixtures into
`Validation.ReferenceFixtures.EnvironmentCapabilities`. Stop before
`branch_comparison_report.v1` and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 10,318 lines.
These six fixtures form one contiguous 255-line environment capability family,
and every key has focused coverage in `validation/planning_input_fixture_test.exs`.

Current coupling/problem:
Six related capability fixtures remain embedded in the facade despite shared
environment-model/provider responsibility and focused test ownership. None
references a facade helper attribute; runtime observation construction remains
outside the literal map.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.EnvironmentCapabilities`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/environment_capabilities.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused planning-input and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The six capability fixtures exist only in the environment family module, all 16
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
Candidate-state report fixture extraction published as `089ee63a`: the two
exact report/diff fixtures moved behind the unchanged facade, the environment-
capability block and remainder stayed exact, the 195-entry map and deterministic
bytes stayed exact, 181 validation tests passed, and bounded review was clean.

Next candidate:
After this boundary, remap the branch-comparison/optimizer/candidate-state
report run and choose a family by focused test ownership rather than adjacency.

Blocked:
No.
