# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema proposed-contact callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point both facade uses of `validate_proposed_contact/3` directly at
`Schema.ProposedContactContracts.validate/3`: the top-level
`proposed_contact.v1` contract pipe and the matching callback-bag capture.
Remove the pure wrapper while preserving pipeline order, callback key and bag
position, and issue ordering.

Why this slice:
`Schema` remains a named 7,958-line production hotspot. The established
ProposedContact owner already exposes the exact `/3` implementation, and this
two-use wrapper has a stable direct-call and callback boundary.

Current coupling/problem:
Top-level proposed-contact validation and a shared contract callback bag still
route through a pure facade wrapper even though both can reference the
established owner without changing the callback contract.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, callback key and order, exact
validation issue ordering, paths and messages, JSON Schema output, checked-in
export bytes, and proposed-contact behavior.

Likely extraction target:
Existing `OrbitalDynamics.Schema.ProposedContactContracts.validate/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact pipeline stages, callback key/position, and wrapper-removal proof
- focused communications contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- aggregate generated and checked-in schema bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The top-level proposed-contact pipe ends at the established owner with unchanged
arguments, the callback bag captures the same owner `/3` under the same key and
between the same neighboring entries, the wrapper is gone, issue order and
messages stay exact, schema bytes do not change, tests pass, and bounded review
finds no blocker.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: `validate_proposed_contact/3` has one final top-level pipe
  call after `require_fields`, one callback-bag capture between
  `validate_activity` and `validate_contact_intent`, and one pure wrapper.
- Focused `communications_contracts_test.exs` baseline: 8 tests passed with
  warnings as errors.
- Generated 121-schema bundle JSON byte digest:
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`
  across 15,506,740 bytes.
- Checked-in `schemas/orbital_dynamics.schema_bundle.v1.json` digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No proposed-contact callback implementation has started.

Last completed slice:
Spacecraft-state-estimate callback cleanup published as `e10103bf`: the
standalone contract pipe now calls the established owner directly, `schema.ex`
shrank from 7,963 to 7,958 lines, 6 focused and 182 complete schema/export
tests passed, all 122 generated schema files byte-matched, and bounded review
was clean.

Next candidate:
Select both direct proposed-contact owner references described above, preserve
pipeline and callback position exactly, then remove the wrapper.

Blocked:
No.
