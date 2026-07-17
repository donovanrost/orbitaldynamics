# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Link-capacity fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`link_capacity_summary.v1` and `link_capacity_report.v1` from their two facade
ranges into a new `Validation.ReferenceFixtures.LinkCapacityArtifacts` leaf.
Stop before `refreshed_window.v1` and `relay_data_path_summary.v1`,
respectively.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,073 lines. The
two link-capacity fixtures total 171 lines and are jointly owned by dedicated
assertions in `link_capacity_fixture_test.exs`.

Current coupling/problem:
The capacity report and its summary are separated by unrelated fixture families
inside the general facade despite sharing one contract responsibility and
focused test module. Extracting both avoids a one-fixture leaf and reunifies
their ownership.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.LinkCapacityArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/link_capacity_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused link-capacity and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The report/summary fixtures exist only in the new cohesive leaf, all 25 fixture
maps remain disjoint, `all/0` and `fetch/1` return exactly the same 195-entry
map and deterministic term bytes, both following boundary fixtures and the
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `7817e0c1af0ec3b38d0c9ea5768aa301c34dce167c369342ffd5c38af2ae7c2d`.
- Exact 193-entry remainder: deterministic digest
  `c7eb92ec687c0915792b1087ed65ce9e4fb96869f968be0519cfe96da6a2b073`.
- Source boundaries confirmed at facade lines 157-248 and 3819-3897, followed
  by `refreshed_window.v1` and `relay_data_path_summary.v1`, respectively, with
  no facade helper-attribute dependency in either selected literal.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No link-capacity implementation has started.

Last completed slice:
Contact-intent extraction published as `2a189f06`: the exact intent/summary
pair moved into a new 136-line leaf, the facade shrank from 8,199 to 8,073
lines, the 195-entry map and all deterministic digests stayed exact, 16 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the link-capacity extraction described above, capture the exact baseline
and both source boundaries, then move the two test-owned fixtures together.

Blocked:
No.
