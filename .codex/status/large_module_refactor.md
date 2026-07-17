# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Environment capability reference-fixture extraction.

Status:
Completed and published as `566532f9`.

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
- None for this bounded slice.

Tests run:
- Exact post-split proof matched the 195-entry selection baseline,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found 6 environment, 2 candidate-state, 2
  capacity/filter, 2 filter/rejection, 2 planning-feedback, 4 timeline, 3
  readiness, 2 contact, 2 station-allocation, 2 freshness/budget, 2 base, 3
  campaign-planning, 10 campaign-artifact, 3 accepted-state, 6 orbital, and
  144 facade keys with no duplicate anchors; facade `fetch/1` matched all six
  moved values.
- Strict test compile passed with warnings as errors.
- Focused planning-input, core-policy, and facade validation tests: 15 passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 1-6 moved as
  pure literal data, branch comparison and the full remainder stayed exact,
  all 16 maps are pairwise disjoint, their union equals `97fa118a`, fetch edge
  behavior matches, and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The six environment model/provider capability fixtures now live in
`Validation.ReferenceFixtures.EnvironmentCapabilities`; the facade merges that
family with 15 existing fixture maps plus 144 remaining fixtures. The facade
fell from 10,318 to 10,065 lines, while the extracted family is 263 lines.

Last completed slice:
Environment capability fixture extraction published as `566532f9`: the six
exact model/provider capability fixtures moved behind the unchanged facade,
branch comparison and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
Extract the contiguous branch-comparison, optimizer-contract, and
invalidated-candidate fixtures into a candidate-strategy family. The 233-line
trio shares dedicated `candidate_strategy_fixture_test.exs` ownership and stops
before `candidate_diff_report.v1`; first verify helper-attribute independence
and re-baseline the complete map.

Blocked:
No.
