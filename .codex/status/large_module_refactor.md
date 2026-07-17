# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema proposed-contact callback ownership mapping.

Status:
Publishing.

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
None.

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
- Source proof against selection commit `9985e700`: the top-level
  proposed-contact pipe retains `require_fields` and now ends at
  `ProposedContactContracts.validate/3`; the callback bag captures the same
  owner `/3` under the unchanged key and between the same activity and
  contact-intent neighbors; the wrapper is absent.
- Focused `communications_contracts_test.exs`: 8 tests passed with warnings as
  errors.
- Complete schema-contract and schema-export suite: 182 tests passed with
  warnings as errors.
- Generated bundle remains exactly 121 schemas, 15,506,740 bytes, and digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Full checked-in schema export regeneration completed with no schema diff;
  aggregate bundle digest remains
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `9985e700` was clean:
  exact pipeline arguments and callback position, unchanged proposed-contact
  owner, 8 focused and 182 complete tests, generated and checked bundle
  digests, all 122 generated export files byte-matched, strict compile, xref,
  formatting, sizes, ledger, and diff hygiene matched the recorded evidence.

Behavior/schema changes:
None.

Outcome:
Both facade uses now reference the established proposed-contact owner directly
and the pure wrapper is gone. `schema.ex` decreased from 7,958 to 7,950 lines.

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
