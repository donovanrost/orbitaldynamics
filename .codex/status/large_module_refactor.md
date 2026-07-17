# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-intent fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`contact_intent.v1` and `contact_intent_summary.v1` into a new
`Validation.ReferenceFixtures.ContactIntentArtifacts` leaf. Stop before
`link_capacity_summary.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,199 lines. The
next two contiguous fixtures form the 128-line contact-intent pair and have
dedicated assertions in `contact_window_fixture_test.exs`.

Current coupling/problem:
Contact intent and its summary remain embedded in the general facade between
activity artifacts and link-capacity evidence. Their shared contact-intent
responsibility and focused tests justify a dedicated leaf.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ContactIntentArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/contact_intent_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused contact-window and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two contact-intent fixtures exist only in the new cohesive leaf, all 24
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, `link_capacity_summary.v1` and the
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
  `37ba67b3227aaa447d940e862eb89ddbfeef9a71a960735218ad65b53f0f3e6f`.
- Exact 193-entry remainder: deterministic digest
  `b80744cdcd1814ada66ef0f1a902d18d668c28064a924cdca1f14bdc394f8f3d`.
- Source boundary confirmed at facade lines 156-283, with
  `link_capacity_summary.v1` beginning at line 284 and no facade
  helper-attribute dependency in the selected literals.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No contact-intent implementation has started.

Last completed slice:
Activity-family ownership completed as `c694c2ac`: the exact
realized/delta/candidate trio moved into the existing five-fixture leaf, the
facade shrank from 8,358 to 8,199 lines, the 195-entry map and all deterministic
digests stayed exact, 18 focused and 181 full validation tests passed, and
bounded review was clean.

Next candidate:
Select the contact-intent extraction described above, capture the exact
baseline and source partition, then stop before `link_capacity_summary.v1`.

Blocked:
No.
