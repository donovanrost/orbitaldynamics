# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest reference-fixture extraction.

Status:
Ready for implementation.

Selected slice:
Move the contiguous manifest-field-reference and study-manifest-lint fixtures
into `Validation.ReferenceFixtures.ManifestArtifacts`. Stop before
`approval_requirement.v1` and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,593 lines.
These two fixtures form one contiguous 112-line manifest metadata/lint family,
and both keys have focused coverage in `validation/manifest_fixture_test.exs`.

Current coupling/problem:
Two related manifest fixtures remain embedded in the facade despite shared
manifest responsibility and focused test ownership. Neither references a
facade helper attribute, so the pair can move without coupling the following
policy-approval family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ManifestArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/manifest_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused manifest and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two manifest fixtures exist only in the manifest family, all 19
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
Core-run report fixture extraction published as `67682478`: the four exact
diff/budget/execution/freshness fixtures moved behind the unchanged facade,
manifest metadata and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, map approval-requirement/policy-decision/proposed-contact
against focused policy-decision ownership before selecting the next family.

Blocked:
No.
