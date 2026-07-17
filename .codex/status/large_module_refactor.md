# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation orbital/event reference-fixture family extraction.

Status:
Publishing implementation.

Selected slice:
Move the first six contiguous non-artifact fixtures—four event cases plus J2
and two-body propagation—into
`Validation.ReferenceFixtures.Orbital`. Merge that family with the remaining
artifact fixture map behind unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` is now the largest production module at 13,383 lines but
exposes only two public facade functions over one giant 195-entry map. The first
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
them with all 189 artifact fixtures, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Strict test compile passed with warnings as errors.
- Exact post-split fixture proof matched the pre-split baseline: 195 entries,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found six unique orbital keys, 189 unique facade keys,
  no duplicate key anchors, and matching facade `fetch/1` results for all six.
- Focused orbital, core-policy, and facade validation tests: 18 passed.
- Full validation test family: 181 passed.
- Format check, diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: AST-level fixture literals exactly match
  `HEAD`, the 6/189 key sets are disjoint, their union equals the prior map,
  deterministic digests reproduce, and the compile dependency is one-way.

Behavior/schema changes:
None.

Outcome:
The exact six-fixture orbital/event family now lives in
`Validation.ReferenceFixtures.Orbital`; the facade merges it with the remaining
189 artifact fixtures behind unchanged public functions. The facade fell from
13,383 to 13,142 lines, while the extracted family is 253 lines.

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
