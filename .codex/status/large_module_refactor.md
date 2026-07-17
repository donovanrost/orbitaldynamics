# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-summary callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point the campaign-repair `validate_resource_summary` callback directly at
`Schema.ResourceSummaryContracts.validate/3` and remove the pure facade wrapper.

Why this slice:
`Schema` remains a 7,895-line hotspot. Live mapping confirms one runtime
capture, one pure wrapper, and an established owner with the exact signature.

Public facade to preserve:
All Schema APIs, callback key/order, issue ordering/messages, JSON Schema and
checked export bytes, and nested repair resource-summary behavior.

Definition of done:
The callback key remains between `validate_contact_intent` and optional contact
filter, captures the owner directly, the wrapper is absent, focused/full tests
and schema bytes remain exact, and review is clean.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: one callback capture and one pure wrapper.
- Focused repair/strategy baseline: 2 tests passed with warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No resource-summary callback implementation has started.

Last completed slice:
Realized-state-snapshot cleanup published as `c24e7a3e`: `schema.ex` shrank from
7,902 to 7,895 lines, 7 focused and 182 complete tests passed, all 122 exports
byte-matched, and bounded review was clean.

Next candidate:
Implement the direct callback capture and remove the wrapper.

Blocked:
No.
