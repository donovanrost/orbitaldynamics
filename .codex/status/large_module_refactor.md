# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Refreshed-window lineage fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`refreshed_window.v1` and `source_window_lineage.v1` into a new
`Validation.ReferenceFixtures.ContactWindowArtifacts` leaf. Stop before
`spacecraft_state_estimate.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 7,904 lines. The
next two contiguous fixtures form an 80-line refreshed-window/lineage pair with
dedicated assertions in `contact_window_fixture_test.exs`.

Current coupling/problem:
Refreshed-window output and its source lineage remain in the general facade
between contact/link evidence and spacecraft-state fixtures. Their shared
window-transformation responsibility warrants a distinct leaf from contact
intent.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ContactWindowArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/contact_window_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused contact-window and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The refreshed-window/lineage fixtures exist only in the new cohesive leaf, all
26 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, `spacecraft_state_estimate.v1` and
the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `9871471bbf9a63cf018b9d9b5a008a432df478756f4f2b52ce3e7c534435a669`.
- Exact 193-entry remainder: deterministic digest
  `402653897f9a6052f1460f8a60bd153f99fe3e64453b293b4332a22898b407c1`.
- Source boundary confirmed at facade lines 158-237, with
  `spacecraft_state_estimate.v1` beginning at line 238 and no facade
  helper-attribute dependency in the selected literals.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No refreshed-window lineage implementation has started.

Last completed slice:
Link-capacity extraction published as `6f45998d`: the exact report/summary pair
moved from two facade ranges into a new 179-line leaf, the facade shrank from
8,073 to 7,904 lines, the 195-entry map and all deterministic digests stayed
exact, 15 focused and 181 full validation tests passed, and bounded review was
clean.

Next candidate:
Select the refreshed-window lineage extraction described above, capture the
exact baseline and source boundary, then stop before
`spacecraft_state_estimate.v1`.

Blocked:
No.
