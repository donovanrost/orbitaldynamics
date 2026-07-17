# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Benchmark fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move all
eight `study_benchmark` fixtures from their contiguous facade range into a new
`Validation.ReferenceFixtures.BenchmarkArtifacts` leaf. Preserve the following
schema-validation report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 3,275 lines. The
eight fixtures occupy 418 facade lines and together own
`benchmark_fixture_test.exs`.

Current coupling/problem:
Local, distributed, chunked, diagnostic, Monte Carlo, and Nx benchmark
expectations form one contiguous test-owned family but remain embedded in the
general registry. Moving the complete range preserves benchmark responsibility
without absorbing schema compatibility.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.BenchmarkArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/benchmark_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused benchmark and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All eight benchmark fixtures exist only in the new cohesive leaf, all 42
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and post-move verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected eight-fixture map: deterministic digest
  `7fe52275bfb6e159fb453cc472b5549c65db46618bb8c5697ebc088cd6b26ccc`.
- Exact 187-entry remainder: deterministic digest
  `b4fd63fe27b9e0ea3484cdee373d6f312b3dc5b0fd2127ea83e25a5a086c8947`.
- Contiguous source boundary confirmed at facade lines 283-700, followed by
  `schema_validation_report.v1`, with no facade helper-attribute dependency in
  the selected literals.
- Focused benchmark/facade selection baseline: 13 tests passed.

Behavior/schema changes:
None.

Outcome:
No benchmark implementation has started.

Last completed slice:
Candidate-strategy ownership cleanup published as `f6deef4b`: the exact pair
moved into the existing leaf, the facade shrank from 3,379 to 3,275 lines, the
leaf grew from 285 to 389 lines, the 195-entry map and all deterministic digests
stayed exact, 18 focused and 181 full validation tests passed, and bounded
review was clean.

Next candidate:
Select the benchmark extraction described above, capture the exact map and
contiguous source boundary, then move the complete test-owned family.

Blocked:
No.
