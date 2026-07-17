# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation orbital/event reference-fixture family extraction.

Status:
Ready for implementation.

Selected slice:
Move the first six contiguous non-artifact fixtures—four event cases plus J2
and two-body propagation—into
`Validation.ReferenceFixtures.Orbital`. Merge that family with the remaining
artifact fixture map behind unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` is now the largest production module at 13,383 lines but
exposes only two public facade functions over one giant 194-entry map. The first
six entries are a contiguous orbital/event family with dedicated focused tests,
making them a cohesive first split without mixing artifact contracts.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/orbital.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused orbital reference-fixture and validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The six fixtures exist only in the orbital family module, the facade merges
them with all 188 artifact fixtures, `all/0` and `fetch/1` return exactly the
same 194-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema priority-override count callback ownership cleanup published as
`3e6ba790`: the contact-allocation callback now points directly to the
priority-override owner, the guarded facade delegate was removed, 182
schema/export tests passed, full export bytes stayed exact, and bounded review
was clean.

Next candidate:
After this boundary, split the next contiguous artifact family only after
mapping key ranges and focused contract coverage; candidate-refresh artifacts
are the largest obvious family but should not be moved as one unreviewable
block.

Blocked:
No.
