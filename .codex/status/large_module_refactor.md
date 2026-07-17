# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-intent-summary callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point the standalone `contact_intent_summary.v1` contract pipe directly at
`Schema.ContactIntentSummaryContracts.validate_summary/3`. Remove the pure
facade delegate while preserving the pipe position and issue ordering.

Why this slice:
`Schema` remains a named 7,950-line production hotspot. Live source inspection
corrected the handoff shorthand: the established owner exposes the exact
`validate_summary/3` implementation. The facade delegate has exactly one caller,
so the cleanup remains bounded.

Current coupling/problem:
The standalone contact-intent-summary validator still routes through a private
facade callback even though `ContactIntentSummaryContracts` owns the complete
implementation.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and
contact-intent-summary behavior.

Likely extraction target:
Existing
`OrbitalDynamics.Schema.ContactIntentSummaryContracts.validate_summary/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact source call-site, pipe position, and delegate-removal proof
- focused communications contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- aggregate generated and checked-in schema bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The standalone contact-intent-summary pipe calls the established owner in the
same final position, the pure facade delegate is gone, issue order and messages
stay exact, schema bytes do not change, focused and complete tests pass, and
bounded review finds no blocker.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: `validate_contact_intent_summary/3` appears exactly once as
  the final standalone contract-pipe call after `require_fields` and once as
  its pure facade definition; the established owner exposes the exact
  `validate_summary/3` implementation.
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
No contact-intent-summary callback implementation has started.

Last completed slice:
Proposed-contact wrapper cleanup published as `a8175d2f`: both facade uses now
point directly at the established owner, `schema.ex` shrank from 7,958 to 7,950
lines, 8 focused and 182 complete schema/export tests passed, all 122 generated
schema files byte-matched, and bounded review was clean.

Next candidate:
Select the direct contact-intent-summary owner described above, preserve the
final pipeline position exactly, then remove the unused facade delegate.

Blocked:
No.
